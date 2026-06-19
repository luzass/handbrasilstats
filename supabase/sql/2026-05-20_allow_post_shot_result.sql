alter table public.shot_events
drop constraint if exists shot_events_shot_result_check;

alter table public.shot_events
add constraint shot_events_shot_result_check
check (
  shot_result in ('goal', 'saved', 'out', 'blocked', 'post')
);
