-- Add explicit ordering support for service catalog drag-and-drop.
alter table public.services
add column if not exists sort_order integer not null default 0;

alter table public.service_variants
add column if not exists sort_order integer not null default 0;

-- Backfill deterministic ordering for existing rows.
with ordered_services as (
  select id, row_number() over (order by created_at asc, name asc, id asc) - 1 as new_order
  from public.services
)
update public.services s
set sort_order = os.new_order
from ordered_services os
where os.id = s.id;

with ordered_variants as (
  select
    id,
    row_number() over (
      partition by service_id
      order by created_at asc, variant asc, id asc
    ) - 1 as new_order
  from public.service_variants
)
update public.service_variants sv
set sort_order = ov.new_order
from ordered_variants ov
where ov.id = sv.id;

create index if not exists idx_services_sort_order
on public.services (sort_order);

create index if not exists idx_service_variants_service_sort_order
on public.service_variants (service_id, sort_order);
