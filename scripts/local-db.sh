#!/usr/bin/env bash
# A local, inspectable copy of the live database in Docker, loaded from the
# newest snapshot in backups/. Nothing here talks to the live project.
#
#   scripts/local-db.sh up [<backup-dir>]   create the container and load a backup
#   scripts/local-db.sh <table> [n]         first n rows of a table or view (25)
#   scripts/local-db.sh tables              every table and view, with row counts
#   scripts/local-db.sh codes               every competition and its join code
#   scripts/local-db.sh comp <join-code>    one competition, top to bottom
#   scripts/local-db.sh psql [args...]      open psql against it
#   scripts/local-db.sh as <uuid> [args]    psql impersonating that auth user
#   scripts/local-db.sh stop | start        without losing the data
#   scripts/local-db.sh down                delete the container and its volume
#   scripts/local-db.sh status
#
# A bare name is looked up as a relation, so `local-db.sh competitions` and
# `local-db.sh auth.users 50` both work; public wins over auth on a bare name.
#
# Connect from the host, or from any GUI client:
#   postgresql://postgres:keepscore@localhost:55432/keepscore
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAME=keepscore-local
VOLUME=keepscore-local-data
PORT=55432
PASS=keepscore
DB=keepscore
CMD="${1:-status}"
shift || true

psql_in() { docker exec -i "$NAME" psql -U postgres -d "$DB" "$@"; }
export -f psql_in 2>/dev/null || true
# -t only when there really is a terminal, so `local-db.sh psql -c '...'` works
# from a script or a pipe as well as interactively
tty_flags() { [[ -t 0 && -t 1 ]] && printf -- '-it' || printf -- '-i'; }
psql_tty() { docker exec "$(tty_flags)" "$NAME" psql -U postgres -d "$DB" "$@"; }

case "$CMD" in
up)
  BACKUP="${1:-$(ls -d "$ROOT"/backups/*/ 2>/dev/null | tail -1)}"
  [[ -n "$BACKUP" && -f "$BACKUP/public.sql" ]] || {
    echo "No backup found. Run scripts/backup-db.sh first." >&2; exit 1; }
  echo "==> loading $(basename "${BACKUP%/}")"

  docker rm -f "$NAME" >/dev/null 2>&1 || true
  docker volume rm "$VOLUME" >/dev/null 2>&1 || true
  docker volume create "$VOLUME" >/dev/null
  docker run -d --name "$NAME" -e POSTGRES_PASSWORD="$PASS" -e POSTGRES_DB="$DB" \
    -p "$PORT:5432" -v "$VOLUME:/var/lib/postgresql/data" postgres:17 >/dev/null
  for _ in $(seq 1 60); do
    docker exec "$NAME" pg_isready -U postgres >/dev/null 2>&1 && break; sleep 1
  done

  # Roles only. Deliberately NOT Supabase's default privileges: pg_dump already
  # captured live's real ACLs as explicit GRANTs, and a default-privileges rule
  # here would silently widen every restored object beyond what live has.
  psql_in -v ON_ERROR_STOP=1 -q <<'SQL'
create role anon nologin noinherit;
create role authenticated nologin noinherit;
create role service_role nologin noinherit bypassrls;
create role supabase_admin login superuser createrole createdb replication bypassrls;
create role supabase_auth_admin login noinherit createrole;
create role dashboard_user login createrole createdb replication;
grant anon, authenticated, service_role, supabase_auth_admin, dashboard_user to postgres;
create publication supabase_realtime;
SQL

  # auth first (public's foreign keys point into auth.users), then public. The
  # on_auth_user_created trigger in auth.sql cannot resolve public.handle_new_user
  # yet, so it is recreated afterwards.
  echo "==> auth"
  psql_in -q < "$BACKUP/auth.sql" 2>&1 | grep -iE '^ERROR' | grep -v 'handle_new_user' || true
  echo "==> public"
  psql_in -q < "$BACKUP/public.sql" 2>&1 | grep -iE '^ERROR' | grep -v 'schema "public" already exists' || true
  psql_in -v ON_ERROR_STOP=1 -q -c \
    'create trigger on_auth_user_created after insert on auth.users
       for each row execute function public.handle_new_user();'

  # Publication membership is cluster-level, so a --schema=public dump omits it;
  # replay it from the snapshot's own REALTIME lines rather than hardcoding.
  if [[ -f "$BACKUP/acl_snapshot.txt" ]]; then
    # built as one script and piped once: a docker exec -i per loop iteration
    # would swallow the rest of the table list off stdin
    grep '^REALTIME ' "$BACKUP/acl_snapshot.txt" | awk \
      '{print "alter publication supabase_realtime add table public." $2 ";"}' \
      | psql_in -v ON_ERROR_STOP=1 -q
  fi

  echo "==> verifying against the snapshot"
  status=0
  psql_in -tA -c "select n.nspname||'.'||c.relname||' '||
      (xpath('/row/c/text()', query_to_xml(format('select count(*) as c from %I.%I', n.nspname, c.relname), false, true, '')))[1]::text::bigint
    from pg_class c join pg_namespace n on n.oid=c.relnamespace
   where n.nspname in ('public','auth') and c.relkind='r' order by 1" > /tmp/.ks_counts
  if diff -q "$BACKUP/row_counts.txt" /tmp/.ks_counts >/dev/null; then
    echo "    row counts match ($(grep -c . /tmp/.ks_counts) tables)"
  else
    echo "    ROW COUNTS DIFFER:"; diff "$BACKUP/row_counts.txt" /tmp/.ks_counts | head; status=1
  fi
  psql_in -tA -c "$(cat "$ROOT/scripts/schema_acl_probe.sql")" > /tmp/.ks_acl
  if diff -q "$BACKUP/acl_snapshot.txt" /tmp/.ks_acl >/dev/null; then
    echo "    privileges, RLS, policies, realtime match ($(grep -c . /tmp/.ks_acl) checks)"
  else
    echo "    ACL DIFFERS:"; diff "$BACKUP/acl_snapshot.txt" /tmp/.ks_acl | head -20; status=1
  fi
  echo
  echo "    postgresql://postgres:$PASS@localhost:$PORT/$DB"
  echo "    scripts/local-db.sh psql            # or your own client"
  echo "    scripts/local-db.sh as <user-uuid>  # to see it as the app does"
  exit $status
  ;;
psql)   psql_tty "$@" ;;
comp)
  CODE="${1:?usage: local-db.sh comp <join-code>}"
  psql_tty -v code="$CODE" -f /dev/stdin < "$ROOT/supabase/inspect/competition.sql"
  ;;
codes)  psql_tty -c "
  select c.join_code, c.name, c.season_length,
         count(distinct p.id) filter (where p.is_active) as players,
         count(distinct m.id) as matches
    from public.competitions c
    left join public.players p on p.competition_id = c.id
    left join public.matches m on m.competition_id = c.id
   group by c.id, c.join_code, c.name, c.season_length
   order by matches desc;" ;;
as)
  # Sets the GUC PostgREST sets, so auth.uid() answers and every RLS policy,
  # security-definer membership check and view behaves as it does for that user.
  WHO="${1:?usage: local-db.sh as <auth-user-uuid>}"; shift || true
  docker exec "$(tty_flags)" "$NAME" env PGOPTIONS="-c request.jwt.claim.sub=$WHO" \
    psql -U postgres -d "$DB" "$@"
  ;;
stop)   docker stop "$NAME" >/dev/null && echo "stopped (data kept in volume $VOLUME)" ;;
start)  docker start "$NAME" >/dev/null && echo "started on localhost:$PORT" ;;
down)   docker rm -f "$NAME" >/dev/null 2>&1 || true
        docker volume rm "$VOLUME" >/dev/null 2>&1 || true
        echo "container and volume removed" ;;
status)
  if docker ps --filter "name=$NAME" --format '{{.Names}}' | grep -q "$NAME"; then
    echo "running: postgresql://postgres:$PASS@localhost:$PORT/$DB"
    psql_in -tA -c "select '  '||n.nspname||'.'||c.relname||' = '||
        (xpath('/row/c/text()', query_to_xml(format('select count(*) as c from %I.%I', n.nspname, c.relname), false, true, '')))[1]::text::bigint
      from pg_class c join pg_namespace n on n.oid=c.relnamespace
     where n.nspname='public' and c.relkind='r' order by 1"
  else
    docker ps -a --filter "name=$NAME" --format '{{.Names}}' | grep -q "$NAME" \
      && echo "stopped — scripts/local-db.sh start" \
      || echo "not created — scripts/local-db.sh up"
  fi ;;
tables)
  # A plain count over every relation trips on public.leaderboard, which calls
  # player_streak and raises for a session that is not a member of anything.
  # A session-local pg_temp wrapper turns that into a null instead.
  psql_tty -c "
    create or replace function pg_temp.safe_count(rel text) returns bigint
      language plpgsql as \$\$
      begin
        return (xpath('/row/c/text()',
          query_to_xml(format('select count(*) as c from %s', rel),
                       false, true, '')))[1]::text::bigint;
      exception when others then return null;
      end \$\$;

    select n.nspname as schema, c.relname as name,
           case c.relkind when 'r' then 'table' else 'view' end as kind,
           pg_temp.safe_count(format('%I.%I', n.nspname, c.relname)) as rows
      from pg_class c join pg_namespace n on n.oid=c.relnamespace
     where n.nspname in ('public','auth') and c.relkind in ('r','v')
     order by n.nspname, c.relkind, c.relname;" ;;
*)
  # Anything else is taken as a table or view name: `local-db.sh competitions`.
  # public wins over auth on a bare name; qualify it (auth.users) to be explicit.
  LIMIT="${1:-25}"
  [[ "$LIMIT" =~ ^[0-9]+$ ]] || { echo "row limit must be a number: $LIMIT" >&2; exit 1; }

  # `|| true`: read returns 1 at EOF, which under set -e would kill the script
  # before the "no such table" message below ever runs
  SCHEMA=''; REL=''
  read -r SCHEMA REL < <(psql_in -tA -F' ' -c "
    select n.nspname, c.relname
      from pg_class c join pg_namespace n on n.oid=c.relnamespace
     where n.nspname in ('public','auth') and c.relkind in ('r','v')
       and (c.relname = '${CMD##*.}')
       and ('${CMD}' not like '%.%' or n.nspname = '${CMD%%.*}')
     order by (n.nspname='public') desc limit 1") || true

  if [[ -z "${REL:-}" ]]; then
    echo "no table or view called '$CMD'." >&2
    # substring first, then a prefix of the first four characters, so a typo
    # like "playerz" still finds players / player_ratings / player_totals
    SUGG="$(psql_in -tA -c "
      select '  '||n.nspname||'.'||c.relname
        from pg_class c join pg_namespace n on n.oid=c.relnamespace
       where n.nspname in ('public','auth') and c.relkind in ('r','v')
         and (c.relname like '%'||'${CMD##*.}'||'%'
              or c.relname like left('${CMD##*.}', 4)||'%'
              or left(c.relname, 4) = left('${CMD##*.}', 4))
       order by 1 limit 8")"
    if [[ -n "$SUGG" ]]; then
      echo "did you mean:" >&2
      echo "$SUGG" >&2
    fi
    echo "  scripts/local-db.sh tables    lists all $(psql_in -tA -c "
      select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace
       where n.nspname in ('public','auth') and c.relkind in ('r','v')")" >&2
    exit 1
  fi

  # Newest-first on whichever timestamp the table actually has, else the primary
  # key, else nothing — so the 25 rows you get are the interesting ones rather
  # than whatever order the heap happens to be in.
  ORDER="$(psql_in -tA -c "
    select coalesce(
      (select quote_ident(a.attname)||' desc'
         from pg_attribute a
        where a.attrelid = '${SCHEMA}.${REL}'::regclass and a.attnum > 0 and not a.attisdropped
          and a.attname in ('played_at','created_at','starts_at','updated_at')
        order by array_position(array['played_at','created_at','starts_at','updated_at'], a.attname)
        limit 1),
      (select string_agg(quote_ident(a.attname), ', ' order by k.ord)
         from pg_index i
         join lateral unnest(i.indkey) with ordinality k(attnum, ord) on true
         join pg_attribute a on a.attrelid = i.indrelid and a.attnum = k.attnum
        where i.indrelid = '${SCHEMA}.${REL}'::regclass and i.indisprimary),
      '')")"

  TOTAL="$(psql_in -tA -c "select count(*) from ${SCHEMA}.${REL}" 2>/dev/null || echo '?')"
  echo "${SCHEMA}.${REL} — showing up to $LIMIT of $TOTAL rows${ORDER:+, ordered by $ORDER}"

  SQL="select * from ${SCHEMA}.${REL}${ORDER:+ order by $ORDER} limit ${LIMIT};"
  # expanded=auto drops to one-field-per-line when a row is too wide for the
  # terminal; as -P it applies silently, where \x auto announces itself
  if ! psql_tty -P pager=off -P expanded=auto -c "$SQL" 2>/tmp/.ks_browse_err; then
    if grep -q 'not in this competition' /tmp/.ks_browse_err; then
      echo >&2
      echo "This view checks membership through auth.uid(), so it cannot be browsed" >&2
      echo "across all competitions at once. Use one competition at a time:" >&2
      echo "    scripts/local-db.sh comp <join-code>     (scripts/local-db.sh codes)" >&2
    else
      cat /tmp/.ks_browse_err >&2
    fi
    exit 1
  fi ;;
esac
