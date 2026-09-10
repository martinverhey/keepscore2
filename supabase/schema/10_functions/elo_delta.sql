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
  v_expected_a  numeric;
  v_actual_a    numeric;
  v_margin      integer;
  v_mov         numeric := 1.0;
  v_winner_edge numeric;
begin
  v_expected_a := 1.0 / (1.0 + power(10.0, (p_rating_b - p_rating_a) / 400.0));

  v_actual_a := case
    when p_score_a > p_score_b then 1.0
    when p_score_a < p_score_b then 0.0
    else 0.5
  end;

  v_margin := abs(p_score_a - p_score_b);

  if p_mov_enabled and v_margin > 0 then
    -- How much stronger the winner already was. Without this damper a
    -- dominant player who keeps winning big runs away with the ladder,
    -- because Elo's self-correction is exactly what the multiplier scales up.
    v_winner_edge := greatest(
      0,
      case when v_actual_a = 1.0
           then p_rating_a - p_rating_b
           else p_rating_b - p_rating_a
      end
    );

    -- ln(margin+1)/ln(2): a 1-point win scores 1.0, 3 points 2.0, 7 points 3.0.
    v_mov := (ln(v_margin + 1) / ln(2.0)) * (2.2 / (0.001 * v_winner_edge + 2.2));
    v_mov := least(p_mov_cap, greatest(1.0, v_mov));
  end if;

  return round(p_k * v_mov * (v_actual_a - v_expected_a), 2);
end;
$$;

comment on function public.elo_delta is
  'Rating change for team A. Zero-sum: team B moves by the negation. Mirrored in Dart by EloCalculator, and the two are tested against the same fixtures.';
revoke all on function public.elo_delta(p_rating_a numeric, p_rating_b numeric, p_score_a integer, p_score_b integer, p_k integer, p_mov_enabled boolean, p_mov_cap numeric) from public, anon, authenticated;
grant execute on function public.elo_delta(p_rating_a numeric, p_rating_b numeric, p_score_a integer, p_score_b integer, p_k integer, p_mov_enabled boolean, p_mov_cap numeric) to anon, authenticated;
