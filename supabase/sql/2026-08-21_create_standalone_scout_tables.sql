create table if not exists public.standalone_teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  name_key text not null unique,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.standalone_matches (
  id uuid primary key default gen_random_uuid(),
  home_standalone_team_id uuid not null references public.standalone_teams(id),
  away_standalone_team_id uuid not null references public.standalone_teams(id),
  home_team_name text not null,
  away_team_name text not null,
  home_score integer not null default 0,
  away_score integer not null default 0,
  status text not null default 'in_progress',
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint standalone_matches_score_check
    check (home_score >= 0 and away_score >= 0),
  constraint standalone_matches_status_check
    check (status in ('in_progress', 'finished', 'cancelled')),
  constraint standalone_matches_different_teams_check
    check (home_standalone_team_id <> away_standalone_team_id)
);

create table if not exists public.standalone_events (
  id uuid primary key default gen_random_uuid(),
  standalone_match_id uuid not null references public.standalone_matches(id) on delete cascade,
  standalone_team_id uuid not null references public.standalone_teams(id),
  opponent_standalone_team_id uuid not null references public.standalone_teams(id),
  event_kind text not null,
  event_type text not null,
  player_number text,
  goalkeeper_number text,
  shot_zone_id integer,
  goal_zone_id integer,
  period text not null,
  minute integer not null default 0,
  second integer not null default 0,
  sequence_order integer not null,
  home_score_after integer not null default 0,
  away_score_after integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint standalone_events_kind_check
    check (event_kind in ('shot', 'team')),
  constraint standalone_events_type_check
    check (
      event_type in (
        'goal',
        'out',
        'post',
        'saved',
        'pass_error',
        'technical_error'
      )
    ),
  constraint standalone_events_period_check
    check (
      period in (
        'first_half',
        'second_half',
        'extra_1',
        'extra_2',
        'shootout'
      )
    ),
  constraint standalone_events_time_check
    check (minute >= 0 and second >= 0 and second < 60),
  constraint standalone_events_score_check
    check (home_score_after >= 0 and away_score_after >= 0),
  constraint standalone_events_sequence_check
    check (sequence_order > 0),
  constraint standalone_events_shot_zone_check
    check (shot_zone_id is null or shot_zone_id between 1 and 11),
  constraint standalone_events_goal_zone_check
    check (goal_zone_id is null or goal_zone_id between 1 and 20),
  constraint standalone_events_shot_required_fields_check
    check (
      event_kind <> 'shot'
      or (
        event_type in ('goal', 'out', 'post', 'saved')
        and player_number is not null
        and length(trim(player_number)) > 0
        and shot_zone_id is not null
      )
    ),
  constraint standalone_events_team_required_fields_check
    check (
      event_kind <> 'team'
      or event_type in ('pass_error', 'technical_error')
    ),
  constraint standalone_events_saved_goalkeeper_check
    check (
      event_type <> 'saved'
      or (
        goalkeeper_number is not null
        and length(trim(goalkeeper_number)) > 0
      )
    )
);

create unique index if not exists standalone_events_match_sequence_key
on public.standalone_events (standalone_match_id, sequence_order);

create index if not exists standalone_matches_created_at_idx
on public.standalone_matches (created_at desc);

create index if not exists standalone_events_match_created_at_idx
on public.standalone_events (standalone_match_id, created_at desc);

create or replace view public.v_standalone_team_stats as
select
  event.standalone_match_id,
  event.standalone_team_id,
  team.name as team_name,
  count(*) filter (where event.event_kind in ('shot', 'team')) as attacks,
  count(*) filter (where event.event_kind = 'shot') as shots,
  count(*) filter (where event.event_type = 'goal') as goals,
  count(*) filter (where event.event_type = 'post') as posts,
  count(*) filter (where event.event_type = 'out') as outs,
  count(*) filter (where event.event_type = 'saved') as saved_shots,
  count(*) filter (where event.event_type = 'pass_error') as pass_errors,
  count(*) filter (where event.event_type = 'technical_error') as technical_errors
from public.standalone_events event
join public.standalone_teams team
  on team.id = event.standalone_team_id
group by
  event.standalone_match_id,
  event.standalone_team_id,
  team.name;

create or replace view public.v_standalone_player_stats as
select
  event.standalone_match_id,
  event.standalone_team_id,
  team.name as team_name,
  event.player_number,
  count(*) as shots,
  count(*) filter (where event.event_type = 'goal') as goals,
  count(*) filter (where event.event_type = 'post') as posts,
  count(*) filter (where event.event_type = 'out') as outs,
  count(*) filter (where event.event_type = 'saved') as saved_shots,
  round(
    (
      count(*) filter (where event.event_type = 'goal')::numeric
      / nullif(count(*), 0)
    ) * 100,
    1
  ) as goal_percentage
from public.standalone_events event
join public.standalone_teams team
  on team.id = event.standalone_team_id
where event.event_kind = 'shot'
group by
  event.standalone_match_id,
  event.standalone_team_id,
  team.name,
  event.player_number;

create or replace view public.v_standalone_player_stats_total as
select
  event.standalone_team_id,
  team.name as team_name,
  event.player_number,
  count(distinct event.standalone_match_id) as matches,
  count(*) as shots,
  count(*) filter (where event.event_type = 'goal') as goals,
  count(*) filter (where event.event_type = 'post') as posts,
  count(*) filter (where event.event_type = 'out') as outs,
  count(*) filter (where event.event_type = 'saved') as saved_shots,
  round(
    (
      count(*) filter (where event.event_type = 'goal')::numeric
      / nullif(count(*), 0)
    ) * 100,
    1
  ) as goal_percentage
from public.standalone_events event
join public.standalone_teams team
  on team.id = event.standalone_team_id
where event.event_kind = 'shot'
group by
  event.standalone_team_id,
  team.name,
  event.player_number;

create or replace view public.v_standalone_goalkeeper_stats as
select
  event.standalone_match_id,
  event.opponent_standalone_team_id as standalone_team_id,
  opponent.name as team_name,
  event.goalkeeper_number,
  count(*) as saves
from public.standalone_events event
join public.standalone_teams opponent
  on opponent.id = event.opponent_standalone_team_id
where event.event_kind = 'shot'
  and event.event_type = 'saved'
  and event.goalkeeper_number is not null
group by
  event.standalone_match_id,
  event.opponent_standalone_team_id,
  opponent.name,
  event.goalkeeper_number;
