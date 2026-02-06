#!/bin/sh
set -e

export PGPASSWORD="${POSTGRES_PASSWORD}"

create_user_and_database() {
  DB_NAME="$1"
  DB_USERNAME="$2"
  DB_PASSWORD="$3"

  echo "Ensuring database ${DB_NAME} exists"
  psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1 \
    || psql -U postgres -c "CREATE DATABASE ${DB_NAME};"

  echo "Ensuring user ${DB_USERNAME} exists"
  psql -U postgres -tc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USERNAME}'" | grep -q 1 \
    || psql -U postgres -c "CREATE USER ${DB_USERNAME};"

  echo "Setting password for ${DB_USERNAME}"
  psql -U postgres -c "ALTER USER ${DB_USERNAME} WITH ENCRYPTED PASSWORD '${DB_PASSWORD}';"

  echo "Granting privileges on ${DB_NAME} to ${DB_USERNAME}"
  psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USERNAME};"
}

create_user_and_database "${DCM4CHEE_DB_NAME}" "${DCM4CHEE_DB_USERNAME}" "${DCM4CHEE_DB_PASSWORD}"
create_user_and_database "${PACS_INTEGRATION_DB_NAME}" "${PACS_INTEGRATION_DB_USERNAME}" "${PACS_INTEGRATION_DB_PASSWORD}"
