create table if not exists public.genres (
  code text primary key,
  name text not null unique check (length(trim(name)) between 1 and 80),
  created_at timestamptz not null default now()
);

create table if not exists public.song_genres (
  song_id uuid not null references public.songs(id) on delete cascade,
  genre_code text not null references public.genres(code) on update cascade on delete restrict,
  primary key (song_id, genre_code)
);

create index if not exists song_genres_genre_code_idx
  on public.song_genres (genre_code, song_id);

insert into public.genres (code, name)
select 'g_' || md5(lower(trim(genre_name))), min(trim(genre_name))
from public.songs
cross join lateral unnest(tags) as genre(genre_name)
where trim(genre_name) <> ''
group by lower(trim(genre_name))
on conflict (code) do nothing;

insert into public.song_genres (song_id, genre_code)
select distinct s.id, 'g_' || md5(lower(trim(genre_name)))
from public.songs s
cross join lateral unnest(s.tags) as genre(genre_name)
where trim(genre_name) <> ''
on conflict do nothing;

grant select on public.genres to authenticated;
grant select on public.song_genres to authenticated;

alter table public.genres enable row level security;
alter table public.song_genres enable row level security;

drop policy if exists "Authenticated users can read genres" on public.genres;
create policy "Authenticated users can read genres"
  on public.genres for select to authenticated
  using (true);

drop policy if exists "Authenticated users can read genres for active songs" on public.song_genres;
create policy "Authenticated users can read genres for active songs"
  on public.song_genres for select to authenticated
  using (exists (
    select 1 from public.songs s
    where s.id = song_id and s.is_active
  ));
