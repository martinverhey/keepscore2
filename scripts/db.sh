#!/usr/bin/env bash
# Thin psql wrapper for this project.
#
# Reads SUPABASE_PROJECT_REF and SUPABASE_DB_PASSWORD from the project-root
# .env (tooling secrets, gitignored — never the bundled assets/.env).
#
# Usage:
#   scripts/db.sh -f supabase/migrations/0001_schema.sql
#   scripts/db.sh -c "select count(*) from public.competitions"
#   scripts/db.sh --apply-schema          # re-apply every replaceable object
#   scripts/db.sh --apply-schema --dry-run
#
# --apply-schema concatenates supabase/schema/**.sql in filename order into one
# transaction: functions, then views (numerically prefixed for dependency
# order), then triggers, policies and grants. Every statement in there is
# idempotent, so it is safe to run against a database that is already current --
# that is the point of keeping those objects out of the migration log.
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

PSQL_ARGS=()
if [[ "${1:-}" == "--apply-schema" ]]; then
  shift
  DRY_RUN=false
  [[ "${1:-}" == "--dry-run" ]] && { DRY_RUN=true; shift; }

  SCHEMA_DIR="$ROOT/supabase/schema"
  [[ -d "$SCHEMA_DIR" ]] || { echo "Missing $SCHEMA_DIR" >&2; exit 1; }

  BUNDLE="$(mktemp -t keepscore-schema)"
  trap 'rm -f "$BUNDLE"' EXIT
  while IFS= read -r file; do
    printf '\n\\echo %s\n' "${file#"$ROOT/"}" >> "$BUNDLE"
    cat "$file" >> "$BUNDLE"
  done < <(find "$SCHEMA_DIR" -name '*.sql' | sort)

  if [[ "$DRY_RUN" == true ]]; then
    echo "$(grep -c '^\\echo ' "$BUNDLE") files, $(wc -l < "$BUNDLE" | tr -d ' ') lines:"
    grep '^\\echo ' "$BUNDLE" | sed 's/^\\echo /  /'
    exit 0
  fi

  set -- --single-transaction -f "$BUNDLE"
fi

exec psql \
  --host "db.${SUPABASE_PROJECT_REF}.supabase.co" \
  --port 5432 \
  --username postgres \
  --dbname postgres \
  --set ON_ERROR_STOP=1 \
  "$@"
