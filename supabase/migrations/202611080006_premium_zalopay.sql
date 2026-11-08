create table public.zalopay_payment_orders (
  app_trans_id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  amount_vnd integer not null check (amount_vnd = 10000),
  status text not null default 'pending' check (status in ('pending', 'paid', 'failed')),
  zalopay_transaction_id text,
  created_at timestamptz not null default now(),
  paid_at timestamptz
);

create index zalopay_payment_orders_user_created_idx
  on public.zalopay_payment_orders(user_id, created_at desc);

alter table public.zalopay_payment_orders enable row level security;
grant select on public.zalopay_payment_orders to authenticated;
grant all on public.zalopay_payment_orders to service_role;
revoke insert, update, delete on public.zalopay_payment_orders from anon, authenticated;

create policy "Users can read their ZaloPay payment orders"
  on public.zalopay_payment_orders for select to authenticated
  using (user_id = (select auth.uid()));

create or replace function public.confirm_zalopay_payment(
  p_app_trans_id text,
  p_amount_vnd integer,
  p_transaction_id text
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  payment public.zalopay_payment_orders%rowtype;
begin
  select * into payment
  from public.zalopay_payment_orders
  where app_trans_id = p_app_trans_id
  for update;

  if not found then return 'not_found'; end if;
  if payment.amount_vnd <> p_amount_vnd then return 'amount_mismatch'; end if;
  if payment.status = 'paid' then return 'duplicate'; end if;
  if payment.status <> 'pending' then return 'not_pending'; end if;

  update public.zalopay_payment_orders
  set status = 'paid', zalopay_transaction_id = p_transaction_id, paid_at = now()
  where app_trans_id = p_app_trans_id;

  insert into public.premium_subscriptions (user_id, expires_at, updated_at)
  values (payment.user_id, now() + interval '30 days', now())
  on conflict (user_id) do update
    set expires_at = greatest(public.premium_subscriptions.expires_at, now()) + interval '30 days',
        updated_at = now();

  return 'confirmed';
end;
$$;

revoke all on function public.confirm_zalopay_payment(text, integer, text) from public, anon, authenticated;
grant execute on function public.confirm_zalopay_payment(text, integer, text) to service_role;
