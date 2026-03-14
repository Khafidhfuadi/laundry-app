-- Add refund tracking columns for cancelled paid transactions

alter table if exists public.transactions
add column if not exists refund_amount numeric(12,2) not null default 0;

alter table if exists public.transactions
add column if not exists refund_at timestamptz;

create index if not exists idx_transactions_refund_at
  on public.transactions (refund_at desc);
