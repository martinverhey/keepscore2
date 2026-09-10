-- KeepScore 2 — rating engine and write API.
--
-- Every write the app performs goes through a SECURITY DEFINER function in
-- this file. The tables themselves grant no direct INSERT/UPDATE/DELETE
-- (see 0003_rls.sql), so validation cannot be bypassed by talking to PostgREST
-- directly, and a match plus its participants plus their ratings always land
-- in one transaction.
-- Authorisation helpers

create or replace function public.is_registered()
returns boolean
language sql
stable
set search_path = ''
as $$
  select auth.uid() is not null
     and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false;
$$;

comment on function public.is_registered() is
  'True for a signed-in user with a real account. Guests (anonymous sign-in) are excluded: they may join and read, never create.';
revoke all on function public.is_registered() from public, anon, authenticated;
grant execute on function public.is_registered() to anon, authenticated;
