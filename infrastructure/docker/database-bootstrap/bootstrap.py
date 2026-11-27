import base64
import json
import logging
import os
import secrets
import string
import sys
import time

import boto3
import psycopg
from psycopg import sql
from botocore.exceptions import BotoCoreError, ClientError
from kubernetes import client, config
from kubernetes.client.rest import ApiException


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
logger = logging.getLogger("database-bootstrap")

LOCK_ID = (20261123, 1)
RDS_CA_CERT = "/etc/ssl/certs/rds-global-bundle.pem"


def required_env(name):
    value = os.environ.get(name)
    if not value:
        raise ValueError(f"Required environment variable is missing: {name}")
    return value


def load_service_config():
    services = json.loads(required_env("DB_SERVICE_CONFIG"))

    if not isinstance(services, list) or not services:
        raise ValueError("DB_SERVICE_CONFIG must contain a non-empty JSON list")

    required_fields = {
        "name", "database", "schema", "role",
        "secretName", "kubernetesSecret",
    }

    names = set()
    for service in services:
        if not isinstance(service, dict):
            raise ValueError("Each service configuration must be an object")

        missing = required_fields - service.keys()
        if missing:
            raise ValueError(
                f"Service configuration is missing fields: {sorted(missing)}"
            )

        if service["name"] in names:
            raise ValueError("Duplicate service name in DB_SERVICE_CONFIG")

        names.add(service["name"])

    return services


def get_master_credentials(secrets_client):
    response = secrets_client.get_secret_value(
        SecretId=required_env("RDS_SECRET_ARN")
    )
    secret = json.loads(response["SecretString"])
    return secret["username"], secret["password"]


def connect_with_retry(host, port, database, username, password):
    attempts = int(os.getenv("DB_CONNECT_ATTEMPTS", "12"))

    for attempt in range(1, attempts + 1):
        try:
            return psycopg.connect(
                host=host,
                port=port,
                dbname=database,
                user=username,
                password=password,
                sslmode="verify-full",
                sslrootcert=RDS_CA_CERT,
                connect_timeout=10,
                autocommit=True,
            )
        except psycopg.OperationalError:
            if attempt == attempts:
                raise

            logger.warning(
                "PostgreSQL connection attempt %s/%s failed; retrying",
                attempt,
                attempts,
            )
            time.sleep(min(attempt * 5, 30))

    raise RuntimeError("PostgreSQL connection attempts exhausted")


def generate_password():
    alphabet = string.ascii_letters + string.digits + "!#$%&()*+,-.:;<=>?@[]^_{|}~"
    return "".join(secrets.choice(alphabet) for _ in range(40))


def get_or_create_credentials(
    secrets_client,
    service,
    role_exists,
):
    secret_name = service["secretName"]

    try:
        response = secrets_client.get_secret_value(SecretId=secret_name)
    except ClientError as exc:
        error_code = exc.response.get("Error", {}).get("Code")

        if error_code != "ResourceNotFoundException":
            raise

        if role_exists:
            raise RuntimeError(
                f"Role {service['role']} exists but secret {secret_name} "
                "has no stored credential version; refusing password rotation"
            ) from None

        credentials = {
            "username": service["role"],
            "password": generate_password(),
        }

        secrets_client.put_secret_value(
            SecretId=secret_name,
            SecretString=json.dumps(credentials),
        )

        logger.info(
            "Created persistent credentials for service %s",
            service["name"],
        )
        return credentials

    credentials = json.loads(response["SecretString"])

    if credentials.get("username") != service["role"]:
        raise RuntimeError(
            f"Stored username does not match configured PostgreSQL role "
            f"for service {service['name']}"
        )

    if not credentials.get("password"):
        raise RuntimeError(
            f"Stored password is missing for service {service['name']}"
        )

    logger.info(
        "Reusing existing credentials for service %s",
        service["name"],
    )
    return credentials


def ensure_database(cursor, database):
    cursor.execute(
        "SELECT 1 FROM pg_database WHERE datname = %s",
        (database,),
    )

    if cursor.fetchone():
        logger.info("Database already exists: %s", database)
        return

    cursor.execute(
        sql.SQL("CREATE DATABASE {}").format(sql.Identifier(database))
    )
    logger.info("Created database: %s", database)


def ensure_role(cursor, service, credentials, role_exists):
    role = service["role"]

    if role_exists:
        logger.info("PostgreSQL role already exists: %s", role)
        return

    cursor.execute(
        sql.SQL("CREATE ROLE {} LOGIN PASSWORD {}").format(
            sql.Identifier(role),
            sql.Literal(credentials["password"]),
        )
    )
    logger.info("Created PostgreSQL login role: %s", role)


def ensure_schema(
    host,
    port,
    master_username,
    master_password,
    service,
    credentials,
):
    database = service["database"]
    schema = service["schema"]
    role = service["role"]

    admin_connection = connect_with_retry(
        host, port, database, master_username, master_password
    )

    try:
        with admin_connection.cursor() as cursor:
            cursor.execute(
                "SELECT schema_owner.rolname "
                "FROM pg_namespace namespace "
                "JOIN pg_roles schema_owner "
                "ON schema_owner.oid = namespace.nspowner "
                "WHERE namespace.nspname = %s",
                (schema,),
            )
            existing = cursor.fetchone()

            if existing is not None:
                if existing[0] != role:
                    raise RuntimeError(
                        f"Schema {schema} in {database} is owned by "
                        f"{existing[0]}, not {role}; refusing ownership change"
                    )

                cursor.execute(
                    sql.SQL("REVOKE CREATE ON DATABASE {} FROM {}").format(
                        sql.Identifier(database),
                        sql.Identifier(role),
                    )
                )
                logger.info(
                    "Schema %s already exists with expected owner",
                    schema,
                )
                return

            cursor.execute(
                sql.SQL("GRANT CREATE ON DATABASE {} TO {}").format(
                    sql.Identifier(database),
                    sql.Identifier(role),
                )
            )
    finally:
        admin_connection.close()

    try:
        application_connection = connect_with_retry(
            host,
            port,
            database,
            credentials["username"],
            credentials["password"],
        )

        try:
            with application_connection.cursor() as cursor:
                cursor.execute(
                    sql.SQL("CREATE SCHEMA {}").format(
                        sql.Identifier(schema)
                    )
                )
            logger.info(
                "Created schema %s in database %s as its application role",
                schema,
                database,
            )
        finally:
            application_connection.close()
    finally:
        cleanup_connection = connect_with_retry(
            host, port, database, master_username, master_password
        )
        try:
            with cleanup_connection.cursor() as cursor:
                cursor.execute(
                    sql.SQL("REVOKE CREATE ON DATABASE {} FROM {}").format(
                        sql.Identifier(database),
                        sql.Identifier(role),
                    )
                )
        finally:
            cleanup_connection.close()


def verify_application_login(host, port, service, credentials):
    connection = connect_with_retry(
        host,
        port,
        service["database"],
        credentials["username"],
        credentials["password"],
    )

    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT current_user, current_schema()")
            current_user, current_schema = cursor.fetchone()

            if current_user != service["role"]:
                raise RuntimeError(
                    f"Database login verification failed for {service['name']}"
                )

            if current_schema != service["schema"]:
                raise RuntimeError(
                    f"Search path verification failed for {service['name']}: "
                    f"expected {service['schema']}, got {current_schema}"
                )

        logger.info(
            "Verified database login and schema for service %s",
            service["name"],
        )
    finally:
        connection.close()


def sync_kubernetes_secret(api, namespace, service, credentials):
    secret_name = service["kubernetesSecret"]

    encoded_data = {
        key: base64.b64encode(value.encode("utf-8")).decode("ascii")
        for key, value in credentials.items()
    }

    try:
        existing = api.read_namespaced_secret(
            name=secret_name,
            namespace=namespace,
        )
        resource_version = existing.metadata.resource_version

        secret = client.V1Secret(
            metadata=client.V1ObjectMeta(
                name=secret_name,
                namespace=namespace,
                resource_version=resource_version,
                labels={
                    "app.kubernetes.io/managed-by": "database-bootstrap",
                    "app.kubernetes.io/component": "database-credentials",
                },
            ),
            type="Opaque",
            data=encoded_data,
        )

        api.replace_namespaced_secret(
            name=secret_name,
            namespace=namespace,
            body=secret,
        )

        logger.info("Updated Kubernetes Secret: %s", secret_name)

    except ApiException as exc:
        if exc.status != 404:
            raise

        secret = client.V1Secret(
            metadata=client.V1ObjectMeta(
                name=secret_name,
                namespace=namespace,
                labels={
                    "app.kubernetes.io/managed-by": "database-bootstrap",
                    "app.kubernetes.io/component": "database-credentials",
                },
            ),
            type="Opaque",
            data=encoded_data,
        )

        api.create_namespaced_secret(
            namespace=namespace,
            body=secret,
        )

        logger.info("Created Kubernetes Secret: %s", secret_name)


def provision():
    host = required_env("DB_HOST")
    port = int(os.getenv("DB_PORT", "5432"))
    admin_database = os.getenv("DB_ADMIN_DATABASE", "postgres")
    namespace = os.getenv("KUBERNETES_NAMESPACE", "nextgen-discover")

    databases = [
        item.strip()
        for item in required_env("DB_NAMES").split(",")
        if item.strip()
    ]

    services = load_service_config()

    for service in services:
        if service["database"] not in databases:
            raise ValueError(
                f"Database {service['database']} for {service['name']} "
                "is not listed in DB_NAMES"
            )

    secrets_client = boto3.client(
        "secretsmanager",
        region_name=required_env("AWS_REGION"),
    )

    master_username, master_password = get_master_credentials(secrets_client)

    connection = connect_with_retry(
        host,
        port,
        admin_database,
        master_username,
        master_password,
    )

    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT pg_advisory_lock(%s, %s)",
                LOCK_ID,
            )
            logger.info("Acquired database provisioning lock")

            try:
                for database in databases:
                    ensure_database(cursor, database)

                provisioned = []

                for service in services:
                    cursor.execute(
                        "SELECT 1 FROM pg_roles WHERE rolname = %s",
                        (service["role"],),
                    )
                    role_exists = cursor.fetchone() is not None

                    credentials = get_or_create_credentials(
                        secrets_client,
                        service,
                        role_exists,
                    )

                    ensure_role(
                        cursor,
                        service,
                        credentials,
                        role_exists,
                    )

                    cursor.execute(
                        sql.SQL(
                            "GRANT CONNECT ON DATABASE {} TO {}"
                        ).format(
                            sql.Identifier(service["database"]),
                            sql.Identifier(service["role"]),
                        )
                    )

                    provisioned.append((service, credentials))

                for service, credentials in provisioned:
                    ensure_schema(
                        host,
                        port,
                        master_username,
                        master_password,
                        service,
                        credentials,
                    )

                    database_connection = connect_with_retry(
                        host,
                        port,
                        service["database"],
                        master_username,
                        master_password,
                    )
                    try:
                        with database_connection.cursor() as cursor:
                            cursor.execute(
                                sql.SQL(
                                    "ALTER ROLE {} IN DATABASE {} "
                                    "SET search_path TO {}"
                                ).format(
                                    sql.Identifier(service["role"]),
                                    sql.Identifier(service["database"]),
                                    sql.Literal(service["schema"]),
                                )
                            )
                    finally:
                        database_connection.close()

                    verify_application_login(
                        host,
                        port,
                        service,
                        credentials,
                    )

                config.load_incluster_config()
                kubernetes_api = client.CoreV1Api()

                for service, credentials in provisioned:
                    sync_kubernetes_secret(
                        kubernetes_api,
                        namespace,
                        service,
                        credentials,
                    )

            finally:
                cursor.execute(
                    "SELECT pg_advisory_unlock(%s, %s)",
                    LOCK_ID,
                )
                logger.info("Released database provisioning lock")

    finally:
        connection.close()


if __name__ == "__main__":
    try:
        provision()
        logger.info("Database bootstrap completed successfully")
    except (
        ValueError,
        KeyError,
        BotoCoreError,
        ClientError,
        psycopg.Error,
        ApiException,
        RuntimeError,
    ) as exc:
        logger.error("Database bootstrap failed: %s", exc)
        sys.exit(1)
