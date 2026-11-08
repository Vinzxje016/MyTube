alter table public.songs
  add column if not exists source_filename text;

create unique index if not exists songs_source_filename_uidx
  on public.songs (source_filename);
