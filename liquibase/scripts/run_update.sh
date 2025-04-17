#!/usr/bin/env bash
set -e

# ─── 1) Carga variables de entorno ─────────────────────────────
set -o allexport
source "$(dirname "$0")/../../.env"
set +o allexport

echo "=== [3/3] Aplicando cambios con update ==="

# ─── 2) Localiza el último changelog limpio ────────────────────
LATEST_FILE=$(ls -t changelogs/auto-diff/*_diff.snowflake.clean.snowflake.sql 2>/dev/null | head -n 1)
if [[ -z "$LATEST_FILE" ]] || ! grep -E -q "CREATE TABLE|DROP TABLE|ALTER TABLE" "$LATEST_FILE"; then
  echo "✅ No hay cambios que aplicar. Saliendo."
  exit 0
fi

# ─── 3) Taguea el estado actual de PROD ───────────────────────
TAG="prod_rollback_$(date +%Y%m%d_%H%M%S)"
echo "=== Etiquetando PROD antes de update: $TAG ==="
liquibase \
  --classpath="$JDBC_PATH" \
  --username="$SNOWFLAKE_USER" \
  --password="$SNOWFLAKE_PASSWORD" \
  --url="jdbc:snowflake://${SNOWFLAKE_ACCOUNT}.snowflakecomputing.com/?warehouse=${SNOWFLAKE_WAREHOUSE_PROD}&db=${SNOWFLAKE_DATABASE_PROD}&schema=${SNOWFLAKE_SCHEMA_PROD}" \
  tag "$TAG"

# ─── 4) Ejecuta el update para aplicar los changesets ─────────
liquibase \
  --classpath="$JDBC_PATH" \
  --username="$SNOWFLAKE_USER" \
  --password="$SNOWFLAKE_PASSWORD" \
  --url="jdbc:snowflake://${SNOWFLAKE_ACCOUNT}.snowflakecomputing.com/?warehouse=${SNOWFLAKE_WAREHOUSE_PROD}&db=${SNOWFLAKE_DATABASE_PROD}&schema=${SNOWFLAKE_SCHEMA_PROD}" \
  --changeLogFile="$LATEST_FILE" \
  update

echo "✅ Update completado. Si necesitas hacer rollback, usa:"
echo "   liquibase rollback $TAG"
