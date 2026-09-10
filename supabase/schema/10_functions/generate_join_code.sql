-- Competition write API

create or replace function public.generate_join_code()
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  v_alphabet constant text := '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  v_code     text;
  v_i        integer;
begin
  for _attempt in 1..20 loop
    v_code := '';
    for v_i in 1..6 loop
      v_code := v_code
        || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::integer, 1);
    end loop;
    if not exists (select 1 from public.competitions where join_code = v_code) then
      return v_code;
    end if;
  end loop;
  raise exception 'Could not allocate a unique join code' using errcode = 'P0001';
end;
$$;

revoke all on function public.generate_join_code() from public, anon, authenticated;
