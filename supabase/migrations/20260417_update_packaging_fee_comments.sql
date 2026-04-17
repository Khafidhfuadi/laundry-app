-- Align packaging column comments with the new input flow on transaction creation

comment on column public.transactions.plastic_bag_count is
  'Jumlah plastik yang dicatat saat transaksi dibuat.';

comment on column public.transactions.packaging_fee_per_plastic is
  'Tarif biaya bungkus per plastik yang dicatat saat transaksi dibuat.';
