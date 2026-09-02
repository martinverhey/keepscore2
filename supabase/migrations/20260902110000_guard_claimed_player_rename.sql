-- A claimed player's name belongs to the person behind it. The owner keeps
-- every other lever over the roster — adding placeholders, deactivating and
-- restoring anyone — but changing a display_name is theirs only while the row
-- is unclaimed, or when it is their own.
--
-- players_update_owner_or_self stays as it is: RLS cannot express this,
-- because a policy sees either the existing row (USING) or the incoming one
-- (WITH CHECK) and never both, and the rule is a comparison between them.
--
-- auth.uid() is null outside a request (psql, service role), which makes the
-- guard's condition NULL rather than true, so seeding and admin repairs are
-- deliberately still allowed through.

create or replace function public.guard_player_rename()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.display_name is distinct from old.display_name
     and old.user_id is not null
     and old.user_id <> auth.uid() then
    raise exception 'Only that player can change their own name'
      using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists players_guard_rename on public.players;

create trigger players_guard_rename
  before update on public.players
  for each row
  execute function public.guard_player_rename();
