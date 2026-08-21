alter table public.standalone_teams enable row level security;
alter table public.standalone_matches enable row level security;
alter table public.standalone_events enable row level security;

grant select, insert on public.standalone_teams to authenticated;
grant select, insert, update on public.standalone_matches to authenticated;
grant select, insert, delete on public.standalone_events to authenticated;
grant select on public.v_standalone_team_stats to authenticated;
grant select on public.v_standalone_player_stats to authenticated;
grant select on public.v_standalone_goalkeeper_stats to authenticated;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'standalone_teams'
      and policyname = 'standalone teams select authenticated'
  ) then
    create policy "standalone teams select authenticated"
    on public.standalone_teams
    for select
    to authenticated
    using (true);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'standalone_teams'
      and policyname = 'standalone teams insert authenticated'
  ) then
    create policy "standalone teams insert authenticated"
    on public.standalone_teams
    for insert
    to authenticated
    with check (true);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'standalone_matches'
      and policyname = 'standalone matches select authenticated'
  ) then
    create policy "standalone matches select authenticated"
    on public.standalone_matches
    for select
    to authenticated
    using (true);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'standalone_matches'
      and policyname = 'standalone matches insert authenticated'
  ) then
    create policy "standalone matches insert authenticated"
    on public.standalone_matches
    for insert
    to authenticated
    with check (true);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'standalone_matches'
      and policyname = 'standalone matches update authenticated'
  ) then
    create policy "standalone matches update authenticated"
    on public.standalone_matches
    for update
    to authenticated
    using (true)
    with check (true);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'standalone_events'
      and policyname = 'standalone events select authenticated'
  ) then
    create policy "standalone events select authenticated"
    on public.standalone_events
    for select
    to authenticated
    using (true);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'standalone_events'
      and policyname = 'standalone events insert authenticated'
  ) then
    create policy "standalone events insert authenticated"
    on public.standalone_events
    for insert
    to authenticated
    with check (true);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'standalone_events'
      and policyname = 'standalone events delete authenticated'
  ) then
    create policy "standalone events delete authenticated"
    on public.standalone_events
    for delete
    to authenticated
    using (true);
  end if;
end $$;
