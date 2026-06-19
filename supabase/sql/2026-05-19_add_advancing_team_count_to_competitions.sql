alter table public.competitions
add column if not exists advancing_team_count integer;

alter table public.competitions
drop constraint if exists competitions_advancing_team_count_check;

alter table public.competitions
add constraint competitions_advancing_team_count_check
check (advancing_team_count is null or advancing_team_count >= 0);
