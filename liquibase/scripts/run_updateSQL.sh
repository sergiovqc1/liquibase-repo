#!/usr/bin/env bash
set -e

# Carga variables de entorno
set -o allexport
source "$(dirname "$0")/../../.env"
set +o allexport

echo "=== [2/3] Previsualizando cambios con updateSQL ==="
LATEST_FILE=$(ls -t changelogs/auto-diff/*clean.snowflake.sql 2>/dev/null | head -n 1)
if [[ -z "$LATEST_FILE" ]] || ! grep -E -q "CREATE TABLE|DROP TABLE|ALTER TABLE" "$LATEST_FILE"; then
  echo "✅ No hay cambios que previsualizar. Saliendo."
  exit 0
fi

liquibase \
  --classpath="$JDBC_PATH" \
  --username="$SNOWFLAKE_USER" \
  --password="$SNOWFLAKE_PASSWORD" \
  --url="jdbc:snowflake://${SNOWFLAKE_ACCOUNT}.snowflakecomputing.com/?warehouse=${SNOWFLAKE_WAREHOUSE_PROD}&db=${SNOWFLAKE_DATABASE_PROD}&schema=${SNOWFLAKE_SCHEMA_PROD}" \
  --changeLogFile="$LATEST_FILE" \
  updateSQL
