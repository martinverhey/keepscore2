#!/usr/bin/env bash
# Rebuild the whole public schema on a throwaway Postgres in Docker, then diff
# it against the live project. Proves supabase/migrations/ + supabase/schema/
# still reproduce what is actually deployed.
#
#   scripts/verify-schema.sh
#
# Exits non-zero on any difference, so it is usable as a gate. Needs Docker and
# the same .env scripts/db.sh reads.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTAINER=keepscore-shadow
WORK="$(mktemp -d)"
trap 'docker rm -f "$CONTAINER" >/dev/null 2>&1 || true; rm -rf "$WORK"' EXIT

set -a
# shellcheck disable=SC1091
source "$ROOT/.env"
set +a
: "${SUPABASE_PROJECT_REF:?not set in .env}"
: "${SUPABASE_DB_PASSWORD:?not set in .env}"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

echo "==> starting $CONTAINER"
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
docker run -d --name "$CONTAINER" -e POSTGRES_PASSWORD=shadow postgres:17 >/dev/null
for _ in $(seq 1 60); do
  docker exec "$CONTAINER" pg_isready -U postgres >/dev/null 2>&1 && break
  sleep 1
done

shadow() { docker exec -i "$CONTAINER" psql -U postgres -v ON_ERROR_STOP=1 -q "$@"; }

echo "==> stubs + baseline + schema"
shadow < "$ROOT/supabase/shadow/supabase_stubs.sql" 2>&1 | grep -v 'wal_level\|HINT' || true
for f in "$ROOT"/supabase/migrations/*.sql; do shadow < "$f"; done
while IFS= read -r f; do cat "$f"; printf '\n'; done \
  < <(find "$ROOT/supabase/schema" -name '*.sql' | sort) \
  > "$WORK/bundle.sql"
shadow --single-transaction < "$WORK/bundle.sql" 2>/dev/null

echo "==> dumping both"
PGPASSWORD="$SUPABASE_DB_PASSWORD" pg_dump \
  --host "db.${SUPABASE_PROJECT_REF}.supabase.co" --port 5432 \
  --username postgres --dbname postgres \
  --schema-only --schema=public --no-owner --no-privileges > "$WORK/live.sql"
docker exec "$CONTAINER" pg_dump -U postgres -d postgres \
  --schema-only --schema=public --no-owner --no-privileges > "$WORK/shadow.sql"

norm() { grep -vE '^(--|SET |SELECT pg_catalog|\\restrict|\\unrestrict|$)' "$1" | sed -E 's/[[:space:]]+$//'; }
norm "$WORK/live.sql"   > "$WORK/a.txt"
norm "$WORK/shadow.sql" > "$WORK/b.txt"

# privileges, RLS, policies and realtime membership are invisible to the
# --no-privileges dump above, and are exactly where a grant mistake hides
ACL_SQL="$(cat "$ROOT/scripts/schema_acl_probe.sql")"
PGPASSWORD="$SUPABASE_DB_PASSWORD" psql -h "db.${SUPABASE_PROJECT_REF}.supabase.co" \
  -U postgres -d postgres -tA -c "$ACL_SQL" > "$WORK/acl_live.txt"
docker exec -i "$CONTAINER" psql -U postgres -tA -c "$ACL_SQL" > "$WORK/acl_shadow.txt"

status=0
echo "==> structure"
diff "$WORK/a.txt" "$WORK/b.txt" && echo "    identical ($(wc -l < "$WORK/a.txt" | tr -d ' ') lines)" || status=1
echo "==> privileges, RLS, policies, realtime"
diff "$WORK/acl_live.txt" "$WORK/acl_shadow.txt" && echo "    identical ($(grep -c . "$WORK/acl_live.txt") checks)" || status=1
exit $status
