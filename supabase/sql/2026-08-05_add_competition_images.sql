alter table public.competitions
add column if not exists image_url text;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'competition-images',
  'competition-images',
  true,
  5242880,
  array['image/png', 'image/jpeg', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public read competition images" on storage.objects;
drop policy if exists "Authenticated upload competition images" on storage.objects;
drop policy if exists "Authenticated update competition images" on storage.objects;
drop policy if exists "Authenticated delete competition images" on storage.objects;

create policy "Public read competition images"
on storage.objects
for select
using (bucket_id = 'competition-images');

create policy "Authenticated upload competition images"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'competition-images');

create policy "Authenticated update competition images"
on storage.objects
for update
to authenticated
using (bucket_id = 'competition-images')
with check (bucket_id = 'competition-images');

create policy "Authenticated delete competition images"
on storage.objects
for delete
to authenticated
using (bucket_id = 'competition-images');
