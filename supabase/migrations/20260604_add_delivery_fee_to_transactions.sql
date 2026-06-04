-- Add delivery fee to transactions for shipping options

alter table if exists public.transactions
add column if not exists delivery_fee numeric(12,2) not null default 0;

comment on column public.transactions.delivery_fee is
  'Biaya ongkir untuk pengiriman laundry.';
