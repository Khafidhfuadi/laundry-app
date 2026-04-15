-- Add packaging metadata for laundry delivery readiness

alter table if exists public.transactions
add column if not exists plastic_bag_count integer not null default 0;

alter table if exists public.transactions
add column if not exists packaging_fee_per_plastic numeric(12,2) not null default 2000;

comment on column public.transactions.plastic_bag_count is
  'Jumlah plastik yang dipakai untuk membungkus laundry sebelum siap dikirim.';

comment on column public.transactions.packaging_fee_per_plastic is
  'Tarif biaya bungkus per plastik.';
