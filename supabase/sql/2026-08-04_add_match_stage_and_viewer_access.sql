alter table public.matches
add column if not exists match_stage text not null default 'classificatoria';

alter table public.matches
drop constraint if exists matches_match_stage_check;

alter table public.matches
add constraint matches_match_stage_check
check (
  match_stage in (
    'classificatoria',
    'final',
    'terceiro_lugar',
    'semifinal',
    'quartas',
    'outro'
  )
);

update public.matches
set match_stage = 'classificatoria'
where match_stage is null;

update public.competitions
set is_featured_for_viewer = true
where name in (
  'Campeonato W.A Masculino',
  'Campeonato W.A Feminino'
);

alter table public.profiles
alter column role set default 'viewer';

alter table public.profiles
alter column is_active set default true;

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
    role,
    is_active
  )
  values (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    new.email,
    new.raw_user_meta_data ->> 'phone',
    'viewer',
    true
  )
  on conflict (id) do update
  set
    full_name = excluded.full_name,
    email = excluded.email,
    phone = excluded.phone,
    role = coalesce(public.profiles.role, 'viewer'),
    is_active = coalesce(public.profiles.is_active, true);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();
