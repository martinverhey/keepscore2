-- Accept a join code however it was typed.
--
-- Codes get read aloud, written down and pasted out of messages, so they
-- arrive lower-cased, padded with spaces, or carrying hyphens the user added
-- themselves. The Flutter client already normalises before sending; doing it
-- here as well means every client gets the same behaviour and the rule lives
-- with the data.

create function public.normalize_join_code(p_code text)
returns text
language sql
immutable
set search_path = ''
as $$
  select upper(regexp_replace(coalesce(p_code, ''), '[^0-9A-Za-z]', '', 'g'));
$$;

grant execute on function public.normalize_join_code(text) to authenticated;

create or replace function public.preview_competition(p_join_code text)
returns table (
  competition_id uuid,
  name           text,
  owner_name     text,
  player_count   integer,
  already_member boolean,
  unclaimed      jsonb
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_comp public.competitions;
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

  competition_id := v_comp.id;
  name           := v_comp.name;
  already_member := public.is_member(v_comp.id);

  select p.display_name into owner_name
    from public.profiles p where p.id = v_comp.owner_id;

  -- Every column here must be table-qualified: the OUT parameters share names
  -- with columns on players, and an unqualified reference is ambiguous.
  select count(*)::integer into player_count
    from public.players p
   where p.competition_id = v_comp.id and p.is_active;

  select coalesce(
           jsonb_agg(jsonb_build_object('id', p.id, 'display_name', p.display_name)
                     order by p.display_name),
           '[]'::jsonb)
    into unclaimed
    from public.players p
   where p.competition_id = v_comp.id
     and p.user_id is null
     and p.is_active;

  return next;
end;
$$;

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
    insert into public.players (competition_id, display_name, user_id)
    values (v_comp.id, coalesce(v_name, 'Player'), auth.uid())
    returning * into v_player;
  end if;

  return v_player;
end;
$$;
