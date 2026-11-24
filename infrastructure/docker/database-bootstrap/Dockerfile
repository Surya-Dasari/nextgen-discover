FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN pip install --no-cache-dir \
    boto3 \
    "psycopg[binary]"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && curl -fsSL https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem \
       -o /etc/ssl/certs/rds-global-bundle.pem \
    && chmod 0644 /etc/ssl/certs/rds-global-bundle.pem \
    && rm -rf /var/lib/apt/lists/*
COPY bootstrap.py .

USER 10001:10001

ENTRYPOINT ["python", "/app/bootstrap.py"]
