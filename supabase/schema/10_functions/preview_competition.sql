-- Lets the join screen show what you are about to join, and which placeholder
-- players are free to claim, without granting read access to the whole
-- competition first.

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

revoke all on function public.preview_competition(p_join_code text) from public, anon, authenticated;
grant execute on function public.preview_competition(p_join_code text) to authenticated;
