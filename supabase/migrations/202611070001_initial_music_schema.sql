create extension if not exists pgcrypto;

create table public.songs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  artist text not null,
  album text not null default '',
  duration_seconds integer not null default 0 check (duration_seconds >= 0),
  audio_path text not null unique,
  cover_path text,
  tags text[] not null default '{}',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.playlists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.playlist_songs (
  playlist_id uuid not null references public.playlists(id) on delete cascade,
  song_id uuid not null references public.songs(id) on delete cascade,
  position integer not null default 0 check (position >= 0),
  added_at timestamptz not null default now(),
  primary key (playlist_id, song_id)
);

create table public.liked_songs (
  user_id uuid not null references auth.users(id) on delete cascade,
  song_id uuid not null references public.songs(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, song_id)
);

create table public.listening_history (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  song_id uuid not null references public.songs(id) on delete cascade,
  started_at timestamptz not null default now()
);

create index playlists_user_updated_idx on public.playlists(user_id, updated_at desc);
create index playlist_songs_order_idx on public.playlist_songs(playlist_id, position);
create index listening_history_user_started_idx on public.listening_history(user_id, started_at desc);

grant select on public.songs to authenticated;
grant select, insert, update, delete on public.playlists to authenticated;
grant select, insert, update, delete on public.playlist_songs to authenticated;
grant select, insert, delete on public.liked_songs to authenticated;
grant select, insert on public.listening_history to authenticated;
grant usage, select on sequence public.listening_history_id_seq to authenticated;

alter table public.songs enable row level security;
alter table public.playlists enable row level security;
alter table public.playlist_songs enable row level security;
alter table public.liked_songs enable row level security;
alter table public.listening_history enable row level security;

create policy "Authenticated users can read active songs"
  on public.songs for select to authenticated
  using (is_active);

create policy "Users can read their playlists"
  on public.playlists for select to authenticated
  using (user_id = (select auth.uid()));
create policy "Users can create their playlists"
  on public.playlists for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy "Users can rename their playlists"
  on public.playlists for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy "Users can delete their playlists"
  on public.playlists for delete to authenticated
  using (user_id = (select auth.uid()));

create policy "Users can read songs in their playlists"
  on public.playlist_songs for select to authenticated
  using (exists (
    select 1 from public.playlists p
    where p.id = playlist_id and p.user_id = (select auth.uid())
  ));
create policy "Users can add songs to their playlists"
  on public.playlist_songs for insert to authenticated
  with check (exists (
    select 1 from public.playlists p
    where p.id = playlist_id and p.user_id = (select auth.uid())
  ));
create policy "Users can reorder or remove songs from their playlists"
  on public.playlist_songs for update to authenticated
  using (exists (
    select 1 from public.playlists p
    where p.id = playlist_id and p.user_id = (select auth.uid())
  ))
  with check (exists (
    select 1 from public.playlists p
    where p.id = playlist_id and p.user_id = (select auth.uid())
  ));
create policy "Users can remove songs from their playlists"
  on public.playlist_songs for delete to authenticated
  using (exists (
    select 1 from public.playlists p
    where p.id = playlist_id and p.user_id = (select auth.uid())
  ));

create policy "Users can read their liked songs"
  on public.liked_songs for select to authenticated
  using (user_id = (select auth.uid()));
create policy "Users can like songs"
  on public.liked_songs for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy "Users can unlike songs"
  on public.liked_songs for delete to authenticated
  using (user_id = (select auth.uid()));

create policy "Users can read their listening history"
  on public.listening_history for select to authenticated
  using (user_id = (select auth.uid()));
create policy "Users can record their listening history"
  on public.listening_history for insert to authenticated
  with check (user_id = (select auth.uid()));

insert into storage.buckets (id, name, public, allowed_mime_types)
values ('tracks', 'tracks', false, array['audio/mpeg'])
on conflict (id) do update set
  public = false,
  allowed_mime_types = array['audio/mpeg'];

insert into storage.buckets (id, name, public, allowed_mime_types)
values ('covers', 'covers', true, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set
  public = true,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

create policy "Authenticated users can stream catalog tracks"
  on storage.objects for select to authenticated
  using (bucket_id = 'tracks');
