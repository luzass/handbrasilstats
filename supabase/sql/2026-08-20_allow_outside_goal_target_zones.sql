alter table public.shot_events
drop constraint if exists shot_events_goal_zone_id_check;

alter table public.shot_events
add constraint shot_events_goal_zone_id_check
check (
  goal_zone_id is null
  or goal_zone_id between 1 and 20
);
