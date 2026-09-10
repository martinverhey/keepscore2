create or replace function public.compute_game_type(p_team_a_size integer, p_team_b_size integer)
returns public.game_type
language sql
immutable
set search_path = ''
as $$
  select case
    when p_team_a_size = p_team_b_size and p_team_a_size between 1 and 4
      then (p_team_a_size || 'v' || p_team_b_size)::public.game_type
    else 'mixed'::public.game_type
  end;
$$;

revoke all on function public.compute_game_type(p_team_a_size integer, p_team_b_size integer) from public, anon, authenticated;
