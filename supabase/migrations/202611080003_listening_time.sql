create table if not exists public.user_listening_time (
  user_id uuid primary key references auth.users(id) on delete cascade,
  total_milliseconds bigint not null default 0 check (total_milliseconds >= 0),
  updated_at timestamptz not null default now()
);

alter table public.user_listening_time enable row level security;
grant select on public.user_listening_time to authenticated;

drop policy if exists "Users can read their listening time"
  on public.user_listening_time;
create policy "Users can read their listening time"
  on public.user_listening_time for select to authenticated
  using (user_id = (select auth.uid()));

create or replace function public.add_listening_time(p_milliseconds bigint)
returns bigint
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  updated_total bigint;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if p_milliseconds <= 0 or p_milliseconds > 30000 then
    raise exception 'Invalid listening-time increment';
  end if;

  insert into public.user_listening_time (user_id, total_milliseconds)
  values (auth.uid(), p_milliseconds)
  on conflict (user_id) do update
    set total_milliseconds = public.user_listening_time.total_milliseconds + excluded.total_milliseconds,
        updated_at = now()
  returning total_milliseconds into updated_total;

  return updated_total;
end;
$$;

revoke all on function public.add_listening_time(bigint) from public;
grant execute on function public.add_listening_time(bigint) to authenticated;
