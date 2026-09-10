select p.proname||'('||pg_get_function_identity_arguments(p.oid)||') auth='
       ||has_function_privilege('authenticated',p.oid,'EXECUTE')::text||' anon='
       ||has_function_privilege('anon',p.oid,'EXECUTE')::text
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='public' order by 1;
select c.relname||' '||r.rolname
       ||' select='||has_table_privilege(r.rolname,c.oid,'SELECT')::text
       ||' insert='||has_table_privilege(r.rolname,c.oid,'INSERT')::text
       ||' update='||has_table_privilege(r.rolname,c.oid,'UPDATE')::text
       ||' delete='||has_table_privilege(r.rolname,c.oid,'DELETE')::text
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
 cross join (select unnest(array['anon','authenticated']) rolname) r
 where n.nspname='public' and c.relkind in ('r','v') order by 1;
select 'COLGRANT '||table_name||'.'||column_name||' '||grantee||' '||privilege_type
  from information_schema.column_privileges
 where table_schema='public' and grantee in ('anon','authenticated') order by 1;
select 'REALTIME '||tablename from pg_publication_tables
 where pubname='supabase_realtime' order by 1;
select 'RLS '||c.relname||'='||c.relrowsecurity::text
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
 where n.nspname='public' and c.relkind='r' order by 1;
select 'POLICY '||polname||' on '||c.relname
  from pg_policy p join pg_class c on c.oid=p.polrelid order by 1;
