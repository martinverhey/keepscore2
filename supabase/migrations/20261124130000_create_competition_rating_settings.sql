-- create_competition gains k_factor / mov_enabled / mov_cap parameters
-- (supabase/schema/10_functions/create_competition.sql). A new signature is a
-- new overload rather than a replacement, so the old one is dropped here,
-- before --apply-schema creates the new one.

drop function public.create_competition(text, public.season_length, text, text);
