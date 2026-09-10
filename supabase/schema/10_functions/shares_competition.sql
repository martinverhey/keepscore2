-- SECURITY DEFINER to avoid recursing through the players policy.

create or replace function public.shares_competition(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.players mine
      join public.players theirs
        on theirs.competition_id = mine.competition_id
     where mine.user_id = auth.uid()
       and theirs.user_id = p_profile_id
  );
$$;

revoke all on function public.shares_competition(p_profile_id uuid) from public, anon, authenticated;
grant execute on function public.shares_competition(p_profile_id uuid) to anon, authenticated;
