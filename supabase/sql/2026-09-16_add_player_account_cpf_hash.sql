create extension if not exists pgcrypto;

create or replace function public.normalize_cpf(value text)
returns text
language sql
immutable
as $$
  select nullif(regexp_replace(coalesce(value, ''), '[^0-9]', '', 'g'), '');
$$;

create or replace function public.hash_cpf(value text)
returns text
language sql
immutable
as $$
  select case
    when length(public.normalize_cpf(value)) = 11 then
      encode(digest(public.normalize_cpf(value), 'sha256'), 'hex')
    else null
  end;
$$;

alter table public.profiles
add column if not exists profile_type text not null default 'visitor';

alter table public.profiles
add column if not exists cpf_hash text;

alter table public.profiles
add column if not exists cpf_last4 text;

alter table public.players
add column if not exists cpf_hash text;

update public.players
set cpf_hash = public.hash_cpf(cpf)
where cpf is not null
  and cpf_hash is null;

create index if not exists players_cpf_hash_idx
on public.players (cpf_hash)
where cpf_hash is not null;

create index if not exists profiles_cpf_hash_idx
on public.profiles (cpf_hash)
where cpf_hash is not null;

create or replace function public.set_player_cpf_hash()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.cpf_hash = public.hash_cpf(new.cpf);
  return new;
end;
$$;

drop trigger if exists set_player_cpf_hash_before_write on public.players;

create trigger set_player_cpf_hash_before_write
before insert or update of cpf on public.players
for each row execute function public.set_player_cpf_hash();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    full_name,
    email,
    phone,
    profile_type,
    cpf_hash,
    cpf_last4,
    role,
    is_active
  )
  values (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    new.email,
    new.raw_user_meta_data ->> 'phone',
    coalesce(new.raw_user_meta_data ->> 'profile_type', 'visitor'),
    new.raw_user_meta_data ->> 'cpf_hash',
    new.raw_user_meta_data ->> 'cpf_last4',
    'viewer',
    true
  )
  on conflict (id) do update
  set
    full_name = excluded.full_name,
    email = excluded.email,
    phone = excluded.phone,
    profile_type = coalesce(excluded.profile_type, public.profiles.profile_type, 'visitor'),
    cpf_hash = coalesce(excluded.cpf_hash, public.profiles.cpf_hash),
    cpf_last4 = coalesce(excluded.cpf_last4, public.profiles.cpf_last4),
    role = coalesce(public.profiles.role, 'viewer'),
    is_active = coalesce(public.profiles.is_active, true);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.get_current_player_competitions()
returns table (
  player_id uuid,
  player_name text,
  photo_url text,
  team_id uuid,
  team_name text,
  team_short_name text,
  competition_id uuid,
  competition_name text,
  year integer,
  category text,
  gender text
)
language sql
security definer
set search_path = public
as $$
  with current_profile as (
    select cpf_hash
    from public.profiles
    where id = auth.uid()
      and profile_type = 'player'
      and is_active = true
  ),
  current_players as (
    select player.*
    from public.players player
    join current_profile profile
      on profile.cpf_hash is not null
     and profile.cpf_hash = player.cpf_hash
    where player.is_active = true
  )
  select distinct
    player.id as player_id,
    player.full_name as player_name,
    player.photo_url,
    team.id as team_id,
    team.name as team_name,
    team.short_name as team_short_name,
    competition.id as competition_id,
    competition.name as competition_name,
    competition.year,
    competition.category,
    competition.gender
  from current_players player
  left join public.team_players team_player
    on team_player.player_id = player.id
   and coalesce(team_player.is_active, true) = true
  left join public.teams team
    on team.id = team_player.team_id
  left join public.matches match
    on match.home_team_id = team.id
    or match.away_team_id = team.id
  left join public.competitions competition
    on competition.id = match.competition_id
  order by competition.year desc nulls last,
    competition.name nulls last,
    team.name nulls last,
    player.full_name;
$$;

create or replace function public.get_current_player_stats()
returns table (
  player_id uuid,
  player_name text,
  photo_url text,
  competition_id uuid,
  competition_name text,
  team_id uuid,
  team_name text,
  team_short_name text,
  matches_count bigint,
  shots bigint,
  goals bigint,
  saved_shots bigint,
  outs bigint,
  posts bigint,
  blocked bigint,
  shot_percentage numeric,
  yellow_cards bigint,
  red_cards bigint,
  blue_cards bigint,
  two_minutes bigint,
  goalkeeper_shots_faced bigint,
  goalkeeper_saves bigint,
  goalkeeper_goals_conceded bigint,
  save_percentage numeric
)
language sql
security definer
set search_path = public
as $$
  with current_profile as (
    select cpf_hash
    from public.profiles
    where id = auth.uid()
      and profile_type = 'player'
      and is_active = true
  ),
  current_players as (
    select player.*
    from public.players player
    join current_profile profile
      on profile.cpf_hash is not null
     and profile.cpf_hash = player.cpf_hash
    where player.is_active = true
  ),
  match_counts as (
    select
      match_player.player_id,
      match.competition_id,
      match_player.team_id,
      count(distinct match_player.match_id) as matches_count
    from public.match_players match_player
    join public.matches match
      on match.id = match_player.match_id
    join current_players player
      on player.id = match_player.player_id
    group by match_player.player_id, match.competition_id, match_player.team_id
  ),
  shot_stats as (
    select
      shot.player_id,
      shot.competition_id,
      shot.team_id,
      count(*) as shots,
      count(*) filter (where shot.shot_result = 'goal') as goals,
      count(*) filter (where shot.shot_result = 'saved') as saved_shots,
      count(*) filter (where shot.shot_result = 'out') as outs,
      count(*) filter (where shot.shot_result = 'post') as posts,
      count(*) filter (where shot.shot_result = 'blocked') as blocked
    from public.shot_events shot
    join current_players player
      on player.id = shot.player_id
    group by shot.player_id, shot.competition_id, shot.team_id
  ),
  discipline_stats as (
    select
      event.player_id,
      event.competition_id,
      event.team_id,
      count(*) filter (where event.event_type = 'yellow_card') as yellow_cards,
      count(*) filter (where event.event_type = 'red_card') as red_cards,
      count(*) filter (where event.event_type = 'blue_card') as blue_cards,
      count(*) filter (where event.event_type = 'suspension_2min') as two_minutes
    from public.match_events event
    join current_players player
      on player.id = event.player_id
    group by event.player_id, event.competition_id, event.team_id
  ),
  goalkeeper_stats as (
    select
      shot.goalkeeper_player_id as player_id,
      shot.competition_id,
      case
        when shot.team_id = match.home_team_id then match.away_team_id
        else match.home_team_id
      end as team_id,
      count(*) filter (where shot.shot_result in ('goal', 'saved')) as shots_faced,
      count(*) filter (where shot.shot_result = 'saved') as saves,
      count(*) filter (where shot.shot_result = 'goal') as goals_conceded
    from public.shot_events shot
    join public.matches match
      on match.id = shot.match_id
    join current_players player
      on player.id = shot.goalkeeper_player_id
    where shot.goalkeeper_player_id is not null
    group by
      shot.goalkeeper_player_id,
      shot.competition_id,
      case
        when shot.team_id = match.home_team_id then match.away_team_id
        else match.home_team_id
      end
  ),
  stat_keys as (
    select player_id, competition_id, team_id from match_counts
    union
    select player_id, competition_id, team_id from shot_stats
    union
    select player_id, competition_id, team_id from discipline_stats
    union
    select player_id, competition_id, team_id from goalkeeper_stats
  )
  select
    key.player_id,
    player.full_name as player_name,
    player.photo_url,
    key.competition_id,
    competition.name as competition_name,
    key.team_id,
    team.name as team_name,
    team.short_name as team_short_name,
    coalesce(match_counts.matches_count, 0) as matches_count,
    coalesce(shot_stats.shots, 0) as shots,
    coalesce(shot_stats.goals, 0) as goals,
    coalesce(shot_stats.saved_shots, 0) as saved_shots,
    coalesce(shot_stats.outs, 0) as outs,
    coalesce(shot_stats.posts, 0) as posts,
    coalesce(shot_stats.blocked, 0) as blocked,
    case
      when coalesce(shot_stats.shots, 0) = 0 then null
      else round((shot_stats.goals::numeric / shot_stats.shots::numeric) * 100, 1)
    end as shot_percentage,
    coalesce(discipline_stats.yellow_cards, 0) as yellow_cards,
    coalesce(discipline_stats.red_cards, 0) as red_cards,
    coalesce(discipline_stats.blue_cards, 0) as blue_cards,
    coalesce(discipline_stats.two_minutes, 0) as two_minutes,
    coalesce(goalkeeper_stats.shots_faced, 0) as goalkeeper_shots_faced,
    coalesce(goalkeeper_stats.saves, 0) as goalkeeper_saves,
    coalesce(goalkeeper_stats.goals_conceded, 0) as goalkeeper_goals_conceded,
    case
      when coalesce(goalkeeper_stats.shots_faced, 0) = 0 then null
      else round((goalkeeper_stats.saves::numeric / goalkeeper_stats.shots_faced::numeric) * 100, 1)
    end as save_percentage
  from stat_keys key
  join current_players player
    on player.id = key.player_id
  join public.competitions competition
    on competition.id = key.competition_id
  join public.teams team
    on team.id = key.team_id
  left join match_counts
    on match_counts.player_id = key.player_id
   and match_counts.competition_id = key.competition_id
   and match_counts.team_id = key.team_id
  left join shot_stats
    on shot_stats.player_id = key.player_id
   and shot_stats.competition_id = key.competition_id
   and shot_stats.team_id = key.team_id
  left join discipline_stats
    on discipline_stats.player_id = key.player_id
   and discipline_stats.competition_id = key.competition_id
   and discipline_stats.team_id = key.team_id
  left join goalkeeper_stats
    on goalkeeper_stats.player_id = key.player_id
   and goalkeeper_stats.competition_id = key.competition_id
   and goalkeeper_stats.team_id = key.team_id
  order by competition.year desc nulls last,
    competition.name,
    team.name,
    player.full_name;
$$;

grant execute on function public.get_current_player_competitions() to authenticated;
grant execute on function public.get_current_player_stats() to authenticated;
