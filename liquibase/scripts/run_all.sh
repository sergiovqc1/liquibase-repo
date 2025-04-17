#!/usr/bin/env bash
set -e

echo ">>> Pipeline completo de Liquibase <<<"
bash "$(dirname "$0")/run_diff.sh"
bash "$(dirname "$0")/run_updateSQL.sh"
bash "$(dirname "$0")/run_update.sh"
echo "✅ Pipeline completado sin errores."
