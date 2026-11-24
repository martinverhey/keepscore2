-- Elo

create or replace function public.elo_delta(
  p_rating_a    numeric,
  p_rating_b    numeric,
  p_score_a     integer,
  p_score_b     integer,
  p_k           integer,
  p_mov_enabled boolean,
  p_mov_cap     numeric
)
returns numeric
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_expected_a        numeric;
  v_winner_expected   numeric;
  v_extra             numeric := 0;
  v_points            numeric;
begin
  v_expected_a := 1.0 / (1.0 + power(10.0, (p_rating_b - p_rating_a) / 400.0));

  if p_score_a = p_score_b then
    return round(p_k * (0.5 - v_expected_a));
  end if;

  -- Margin of victory adds bonus points to the pot: one per point of
  -- difference up to mov_cap, doubled when the loser scored nothing.
  if p_mov_enabled then
    v_extra := least(abs(p_score_a - p_score_b), p_mov_cap);
    if least(p_score_a, p_score_b) = 0 then
      v_extra := v_extra * 2;
    end if;
  end if;

  v_winner_expected := case
    when p_score_a > p_score_b then v_expected_a
    else 1.0 - v_expected_a
  end;

  -- Whole points, and a win is always worth at least one.
  v_points := greatest(1, round((p_k + v_extra) * (1.0 - v_winner_expected)));

  return case when p_score_a > p_score_b then v_points else -v_points end;
end;
$$;

comment on function public.elo_delta is
  'Rating change for team A, in whole points. Zero-sum: team B moves by the negation. Mirrored in Dart by EloCalculator, and the two are tested against the same fixtures.';
revoke all on function public.elo_delta(p_rating_a numeric, p_rating_b numeric, p_score_a integer, p_score_b integer, p_k integer, p_mov_enabled boolean, p_mov_cap numeric) from public, anon, authenticated;
grant execute on function public.elo_delta(p_rating_a numeric, p_rating_b numeric, p_score_a integer, p_score_b integer, p_k integer, p_mov_enabled boolean, p_mov_cap numeric) to anon, authenticated;
