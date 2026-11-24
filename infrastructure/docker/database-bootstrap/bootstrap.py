import json
import logging
import os
import sys
import time

import boto3
import psycopg
from psycopg import sql
from botocore.exceptions import BotoCoreError, ClientError

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
logger = logging.getLogger("database-bootstrap")


def required_env(name):
    value = os.environ.get(name)
    if not value:
        raise ValueError(f"Required environment variable is missing: {name}")
    return value


def get_credentials():
    region = required_env("AWS_REGION")
    secret_arn = required_env("RDS_SECRET_ARN")

    client = boto3.client("secretsmanager", region_name=region)

    response = client.get_secret_value(SecretId=secret_arn)
    secret = json.loads(response["SecretString"])

    return secret["username"], secret["password"]


def connect_with_retry(host, port, database, username, password):
    attempts = int(os.getenv("DB_CONNECT_ATTEMPTS", "12"))

    for attempt in range(1, attempts + 1):
        try:
            connection = psycopg.connect(
                host=host,
                port=port,
                dbname=database,
                user=username,
                password=password,
                sslmode="verify-full",
                sslrootcert="/etc/ssl/certs/rds-global-bundle.pem",
                connect_timeout=10,
                autocommit=True,
            )
            logger.info("Connected to PostgreSQL administrative database")
            return connection

        except psycopg.OperationalError:
            if attempt == attempts:
                raise

            logger.warning(
                "PostgreSQL connection attempt %s/%s failed; retrying",
                attempt,
                attempts,
            )
            time.sleep(min(attempt * 5, 30))


def provision():
    host = required_env("DB_HOST")
    port = int(os.getenv("DB_PORT", "5432"))
    admin_database = os.getenv("DB_ADMIN_DATABASE", "postgres")
    databases = [
        item.strip()
        for item in required_env("DB_NAMES").split(",")
        if item.strip()
    ]

    if not databases:
        raise ValueError("DB_NAMES must contain at least one database")

    username, password = get_credentials()

    connection = connect_with_retry(
        host, port, admin_database, username, password
    )

    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT pg_advisory_lock(%s, %s)", (20261123, 1))
            logger.info("Acquired database provisioning lock")

            try:
                for database in databases:
                    cursor.execute(
                        "SELECT 1 FROM pg_database WHERE datname = %s",
                        (database,),
                    )

                    if cursor.fetchone():
                        logger.info("Database already exists: %s", database)
                        continue

                    cursor.execute(
                        sql.SQL("CREATE DATABASE {}").format(
                            sql.Identifier(database)
                        )
                    )
                    logger.info("Created database: %s", database)

                for database in databases:
                    cursor.execute(
                        "SELECT 1 FROM pg_database WHERE datname = %s",
                        (database,),
                    )

                    if not cursor.fetchone():
                        raise RuntimeError(
                            f"Database verification failed: {database}"
                        )

                    logger.info("Database verified: %s", database)

            finally:
                cursor.execute("SELECT pg_advisory_unlock(%s, %s)", (20261123, 1))
                logger.info("Released database provisioning lock")
    finally:
        connection.close()


if __name__ == "__main__":
    try:
        provision()
        logger.info("Database bootstrap completed successfully")
    except (ValueError, KeyError, BotoCoreError, ClientError,
            psycopg.Error, RuntimeError) as exc:
        logger.error("Database bootstrap failed: %s", exc)
        sys.exit(1)
