-- update_match_score — boundary is the earlier of the match's old and new
-- position (same match id either way, so the tuple comparison reduces to
-- comparing played_at). A season change needs both seasons replayed from
-- this match's position in each of them.

create or replace function public.update_match_score(
  p_match_id  uuid,
  p_score_a   integer,
  p_score_b   integer,
  p_played_at timestamptz default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_match          public.matches;
  v_comp           public.competitions;
  v_new_season     uuid;
  v_new_played_at  timestamptz;
  v_boundary       timestamptz;
begin
  select * into v_match from public.matches where id = p_match_id;
  if not found then
    raise exception 'Match not found' using errcode = 'P0001';
  end if;

  if not public.is_registered()
     or not (v_match.created_by = auth.uid()
             or public.is_owner(v_match.competition_id)) then
    raise exception 'Only the person who logged this match, or the competition owner, can change it'
      using errcode = 'P0001';
  end if;

  select * into strict v_comp
    from public.competitions where id = v_match.competition_id;

  if p_score_a < 0 or p_score_b < 0 then
    raise exception 'Scores cannot be negative' using errcode = 'P0001';
  end if;
  if p_score_a = p_score_b and not v_comp.allow_draws then
    raise exception 'This competition does not allow draws' using errcode = 'P0001';
  end if;

  v_new_played_at := coalesce(p_played_at, v_match.played_at);

  -- Moving a match in time can move it into a different season entirely.
  v_new_season := case
    when p_played_at is null then v_match.season_id
    else public.ensure_season(v_match.competition_id, p_played_at)
  end;

  update public.matches
     set team_a_score = p_score_a,
         team_b_score = p_score_b,
         played_at    = v_new_played_at,
         season_id    = v_new_season
   where id = p_match_id;

  if v_new_season = v_match.season_id then
    -- Same match id either side, so the tuple boundary comparison reduces to
    -- the earlier of the two timestamps: whichever position moves first is
    -- where anything downstream could start differing.
    v_boundary := least(v_match.played_at, v_new_played_at);
    perform public.recalc_season_from(v_match.season_id, v_boundary, p_match_id);
  else
    perform public.recalc_season_from(
      v_match.season_id, v_match.played_at, p_match_id
    );
    perform public.recalc_season_from(v_new_season, v_new_played_at, p_match_id);
  end if;
end;
$$;

revoke all on function public.update_match_score(p_match_id uuid, p_score_a integer, p_score_b integer, p_played_at timestamp with time zone) from public, anon, authenticated;
grant execute on function public.update_match_score(p_match_id uuid, p_score_a integer, p_score_b integer, p_played_at timestamp with time zone) to authenticated;
