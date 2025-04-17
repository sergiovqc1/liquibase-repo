#!/usr/bin/env bash
set -e

# Carga variables de entorno
set -o allexport
source "$(dirname "$0")/../../.env"
set +o allexport

DATE=$(date +"%Y%m%d_%H%M%S")
RAW_FILE="changelogs/auto-diff/${DATE}_diff.snowflake.sql"

echo "=== [1/3] Generando diffChangeLog ==="
liquibase \
  --classpath="$JDBC_PATH" \
  --username="$SNOWFLAKE_USER" \
  --password="$SNOWFLAKE_PASSWORD" \
  --url="jdbc:snowflake://${SNOWFLAKE_ACCOUNT}.snowflakecomputing.com/?warehouse=${SNOWFLAKE_WAREHOUSE_PROD}&db=${SNOWFLAKE_DATABASE_PROD}&schema=${SNOWFLAKE_SCHEMA_PROD}" \
  --referenceUrl="jdbc:snowflake://${SNOWFLAKE_ACCOUNT}.snowflakecomputing.com/?warehouse=${SNOWFLAKE_WAREHOUSE_DEV}&db=${SNOWFLAKE_DATABASE_DEV}&schema=${SNOWFLAKE_SCHEMA_DEV}" \
  --referenceUsername="$SNOWFLAKE_USER" \
  --referencePassword="$SNOWFLAKE_PASSWORD" \
  --defaultSchemaName="${SNOWFLAKE_SCHEMA_PROD}" \
  --referenceDefaultSchemaName="${SNOWFLAKE_SCHEMA_DEV}" \
  --changeLogFile="$RAW_FILE" \
  diffChangeLog

# Si no hay DDL real, salimos
if ! grep -E -q "CREATE TABLE|DROP TABLE|ALTER TABLE" "$RAW_FILE"; then
  echo "✅ No se detectaron diferencias entre DEV y PROD. Pipeline detenido."
  exit 0
fi

echo "=== Post‑procesado: limpiando changelog ==="
python3 "$(dirname "$0")/clean_changelog.py" "$RAW_FILE"
