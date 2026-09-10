-- Player display names must be unique within a competition (case- and
-- whitespace-insensitive), checked at the two paths that can create one:
-- join_competition (joining as a new player) and add_dummy_player (the
-- owner adding a placeholder).
--
-- Not enforced as a table constraint: the live project already carries
-- duplicate names from earlier manual testing, and a unique index would
-- refuse to build over that data. These RAISEs are the source of truth for
-- new writes; they are not race-free against two concurrent joins picking
-- the same name at once, which this app's usage pattern makes vanishingly
-- unlikely.

create or replace function public.join_competition(
  p_join_code       text,
  p_display_name    text default null,
  p_claim_player_id uuid default null
)
returns public.players
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_comp   public.competitions;
  v_player public.players;
  v_name   text;
begin
  if auth.uid() is null then
    raise exception 'Sign in first' using errcode = 'P0001';
  end if;

  select * into v_comp
    from public.competitions c
   where c.join_code = public.normalize_join_code(p_join_code);

  if not found then
    raise exception 'No competition with that code' using errcode = 'P0001';
  end if;

  select * into v_player
    from public.players p
   where p.competition_id = v_comp.id and p.user_id = auth.uid();

  if found then
    return v_player;
  end if;

  select coalesce(nullif(btrim(p_display_name), ''), p.display_name)
    into v_name
    from public.profiles p where p.id = auth.uid();

  if p_claim_player_id is not null then
    -- Claiming inherits the placeholder's rating and match history: the
    -- player row keeps its id, so nothing downstream has to be rewritten.
    update public.players p
       set user_id = auth.uid(),
           display_name = coalesce(nullif(btrim(p_display_name), ''), p.display_name)
     where p.id = p_claim_player_id
       and p.competition_id = v_comp.id
       and p.user_id is null
       and p.is_active
    returning * into v_player;

    if not found then
      raise exception 'That player has already been claimed'
        using errcode = 'P0001';
    end if;
  else
    v_name := coalesce(v_name, 'Player');

    if exists (
      select 1 from public.players p
       where p.competition_id = v_comp.id
         and lower(btrim(p.display_name)) = lower(v_name)
    ) then
      raise exception 'A player named "%" already exists in this competition', v_name
        using errcode = 'P0001';
    end if;

    insert into public.players (competition_id, display_name, user_id)
    values (v_comp.id, v_name, auth.uid())
    returning * into v_player;
  end if;

  return v_player;
end;
$$;

revoke all on function public.join_competition(p_join_code text, p_display_name text, p_claim_player_id uuid) from public, anon, authenticated;
grant execute on function public.join_competition(p_join_code text, p_display_name text, p_claim_player_id uuid) to authenticated;
