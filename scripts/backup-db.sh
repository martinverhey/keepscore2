#!/usr/bin/env bash
# Snapshot the live project into backups/<utc-timestamp>/ before anything
# writes to it. Nothing here is committed — see /backups/ in .gitignore.
#
#   scripts/backup-db.sh
#   scripts/backup-db.sh --verify    # also restore it into Docker and count rows
#
# Dumps public (schema + data, owners and privileges kept) in both plain SQL
# and pg_dump's custom format, plus auth, whose users table every players.user_id
# and profiles.id points at — a public-only dump cannot be read back without it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERIFY=false
[[ "${1:-}" == "--verify" ]] && VERIFY=true

if [[ ! -f "$ROOT/.env" ]]; then
  echo "Missing $ROOT/.env" >&2; exit 1
fi
set -a
# shellcheck disable=SC1091
source "$ROOT/.env"
set +a
: "${SUPABASE_PROJECT_REF:?not set in .env}"
: "${SUPABASE_DB_PASSWORD:?not set in .env}"

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PGPASSWORD="$SUPABASE_DB_PASSWORD"
HOST="db.${SUPABASE_PROJECT_REF}.supabase.co"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$ROOT/backups/$STAMP"
mkdir -p "$OUT"

dump() { pg_dump --host "$HOST" --port 5432 --username postgres --dbname postgres "$@"; }
query() { psql --host "$HOST" --port 5432 --username postgres --dbname postgres -tA -c "$1"; }

echo "==> public (plain + custom)"
dump --schema=public --file="$OUT/public.sql"
dump --schema=public --format=custom --file="$OUT/public.dump"

echo "==> auth"
dump --schema=auth --file="$OUT/auth.sql"

echo "==> privileges, RLS, policies, realtime"
query "$(cat "$ROOT/scripts/schema_acl_probe.sql")" > "$OUT/acl_snapshot.txt"

echo "==> row counts"
query "select n.nspname||'.'||c.relname||' '||
              (xpath('/row/c/text()',
                query_to_xml(format('select count(*) as c from %I.%I', n.nspname, c.relname),
                             false, true, '')))[1]::text::bigint
         from pg_class c join pg_namespace n on n.oid=c.relnamespace
        where n.nspname in ('public','auth') and c.relkind='r'
        order by 1" > "$OUT/row_counts.txt"

SERVER="$(query 'show server_version')"
cat > "$OUT/MANIFEST.txt" <<EOF
KeepScore 2 — live database snapshot
project     $SUPABASE_PROJECT_REF
taken       $STAMP (UTC)
server      PostgreSQL $SERVER
dumped by   $(pg_dump --version)

public.sql       plain SQL, schema + data, owners and privileges kept
public.dump      same, pg_dump custom format (use with pg_restore)
auth.sql         the auth schema, schema + data
acl_snapshot.txt privileges / RLS / policies / realtime membership
row_counts.txt   exact row count per table at snapshot time

Restore the public schema over a damaged one, same cluster:

  psql "\$CONN" -c 'drop schema public cascade; create schema public;'
  psql "\$CONN" -f public.sql

Selective restore of a single table's data:

  pg_restore --data-only --table=matches --dbname "\$CONN" public.dump

Restoring into a *different* cluster needs --no-owner, since the roles here
(postgres, anon, authenticated, service_role, supabase_admin) will not exist
there. auth.sql is Supabase-managed: restore it only into a project that has
no auth schema of its own, never over a live one.
EOF

echo
echo "==> $OUT"
ls -la "$OUT" | tail -n +2 | awk '{printf "    %-18s %s\n", $9, $5}'

fail=0
for f in public.sql public.dump auth.sql acl_snapshot.txt row_counts.txt; do
  [[ -s "$OUT/$f" ]] || { echo "EMPTY: $f" >&2; fail=1; }
done
for t in competitions players matches match_players player_ratings profiles seasons; do
  grep -q "COPY public.$t " "$OUT/public.sql" || { echo "MISSING DATA: public.$t" >&2; fail=1; }
done
[[ $fail -eq 0 ]] && echo "    all seven public tables carry a COPY block"

if [[ "$VERIFY" == true ]]; then
  echo
  echo "==> restoring into a throwaway postgres:17 to prove it loads"
  C=keepscore-restore-check
  docker rm -f "$C" >/dev/null 2>&1 || true
  docker run -d --name "$C" -e POSTGRES_PASSWORD=x postgres:17 >/dev/null
  for _ in $(seq 1 60); do docker exec "$C" pg_isready -U postgres >/dev/null 2>&1 && break; sleep 1; done
  docker exec -i "$C" psql -U postgres -q < "$ROOT/supabase/shadow/supabase_stubs.sql" 2>&1 \
    | grep -v 'wal_level\|HINT' || true
  # the stub owns a placeholder auth.users; the dump brings the real one
  docker exec -i "$C" psql -U postgres -q -c 'drop schema auth cascade' >/dev/null
  docker exec -i "$C" psql -U postgres -q < "$OUT/auth.sql" >/dev/null 2>&1 || true
  docker exec -i "$C" psql -U postgres -q < "$OUT/public.sql" >/dev/null 2>&1 || true
  docker exec -i "$C" psql -U postgres -tA -c "
    select 'public.'||c.relname||' '||
           (xpath('/row/c/text()',
             query_to_xml(format('select count(*) as c from public.%I', c.relname),
                          false, true, '')))[1]::text::bigint
      from pg_class c join pg_namespace n on n.oid=c.relnamespace
     where n.nspname='public' and c.relkind='r' order by 1" > "$OUT/restored_counts.txt"
  docker rm -f "$C" >/dev/null 2>&1
  echo "    live vs restored:"
  if diff <(grep '^public\.' "$OUT/row_counts.txt") "$OUT/restored_counts.txt"; then
    echo "    every public table restored with an identical row count"
  else
    echo "    MISMATCH — the backup does not round-trip" >&2; exit 1
  fi
fi
