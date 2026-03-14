-- Add payment timestamp for cash-basis reporting
-- Omset  : based on transactions.created_at
-- Revenue: based on transactions.payment_received_at

alter table if exists public.transactions
add column if not exists payment_received_at timestamptz;

-- Backfill legacy rows:
-- If transaction already has paid amount (> 0) but no payment timestamp,
-- use created_at as best-effort fallback.
update public.transactions
set payment_received_at = created_at
where paid_amount > 0
  and payment_received_at is null;

-- Helpful index for report filters by payment date.
create index if not exists idx_transactions_payment_received_at
  on public.transactions (payment_received_at desc);
