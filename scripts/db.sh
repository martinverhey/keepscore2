#!/usr/bin/env bash
# Thin psql wrapper for this project.
#
# Reads SUPABASE_PROJECT_REF and SUPABASE_DB_PASSWORD from the project-root
# .env (tooling secrets, gitignored — never the bundled assets/.env).
#
# Usage:
#   scripts/db.sh -f supabase/migrations/0001_schema.sql
#   scripts/db.sh -c "select count(*) from public.competitions"
#
# The direct host is IPv6-only on this project, which is why the pooler is not
# used here.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -f "$ROOT/.env" ]]; then
  echo "Missing $ROOT/.env — create it with SUPABASE_PROJECT_REF and SUPABASE_DB_PASSWORD" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source "$ROOT/.env"
set +a

: "${SUPABASE_PROJECT_REF:?not set in .env}"
: "${SUPABASE_DB_PASSWORD:?not set in .env}"

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PGPASSWORD="$SUPABASE_DB_PASSWORD"

exec psql \
  --host "db.${SUPABASE_PROJECT_REF}.supabase.co" \
  --port 5432 \
  --username postgres \
  --dbname postgres \
  --set ON_ERROR_STOP=1 \
  "$@"
