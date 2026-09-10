create or replace function public.is_owner(p_competition_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.competitions
     where id = p_competition_id
       and owner_id = auth.uid()
  );
$$;

revoke all on function public.is_owner(p_competition_id uuid) from public, anon, authenticated;
grant execute on function public.is_owner(p_competition_id uuid) to anon, authenticated;
