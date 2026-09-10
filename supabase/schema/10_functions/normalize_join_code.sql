-- Accept a join code however it was typed.
--
-- Codes get read aloud, written down and pasted out of messages, so they
-- arrive lower-cased, padded with spaces, or carrying hyphens the user added
-- themselves. The Flutter client already normalises before sending; doing it
-- here as well means every client gets the same behaviour and the rule lives
-- with the data.

create or replace function public.normalize_join_code(p_code text)
returns text
language sql
immutable
set search_path = ''
as $$
  select upper(regexp_replace(coalesce(p_code, ''), '[^0-9A-Za-z]', '', 'g'));
$$;

revoke all on function public.normalize_join_code(p_code text) from public, anon, authenticated;
grant execute on function public.normalize_join_code(p_code text) to anon, authenticated;
