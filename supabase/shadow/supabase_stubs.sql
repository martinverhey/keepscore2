-- What Supabase provides that a bare postgres:17 does not, stubbed just far
-- enough for the baseline and supabase/schema/ to apply and be diffed against
-- the live project. Not a Supabase emulation: no GoTrue, no PostgREST, no
-- realtime server. auth.uid()/auth.jwt() read the same request settings
-- PostgREST sets, so RLS policies compile and can be exercised by hand with
-- set local request.jwt.claim.sub = '<uuid>'.
--
-- The default privileges at the bottom are load-bearing. Supabase grants anon
-- and authenticated ALL on every newly created table, which is why the views
-- carry write privileges nobody granted them; without this line the shadow
-- comes out narrower than live and the diff lies.

create role anon nologin noinherit;
create role authenticated nologin noinherit;
create role service_role nologin noinherit bypassrls;
grant anon, authenticated, service_role to postgres;

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create schema if not exists auth;
create table auth.users (
  id uuid primary key default gen_random_uuid(),
  email text,
  raw_user_meta_data jsonb,
  is_anonymous boolean not null default false
);
create or replace function auth.uid() returns uuid language sql stable
  as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
create or replace function auth.jwt() returns jsonb language sql stable
  as $$ select coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb $$;

create publication supabase_realtime;

alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
grant usage on schema public to anon, authenticated, service_role;
