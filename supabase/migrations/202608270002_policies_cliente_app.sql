create or replace function public.es_duenio_seguimiento(p_seguimiento_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.seguimientos_musculares
    where id = p_seguimiento_id
      and usuario_id = auth.uid()
  );
$$;

drop policy if exists seguimientos_select_propio on public.seguimientos_musculares;
drop policy if exists seguimientos_insert_propio on public.seguimientos_musculares;
drop policy if exists seguimientos_update_propio on public.seguimientos_musculares;
drop policy if exists seguimientos_delete_propio on public.seguimientos_musculares;

alter table public.seguimientos_musculares enable row level security;

create policy seguimientos_select_propio
on public.seguimientos_musculares
for select
using (usuario_id = auth.uid());

create policy seguimientos_insert_propio
on public.seguimientos_musculares
for insert
with check (usuario_id = auth.uid());

create policy seguimientos_update_propio
on public.seguimientos_musculares
for update
using (usuario_id = auth.uid())
with check (usuario_id = auth.uid());

create policy seguimientos_delete_propio
on public.seguimientos_musculares
for delete
using (usuario_id = auth.uid());

drop policy if exists seguimiento_ejercicios_select_propio on public.seguimiento_ejercicios;
drop policy if exists seguimiento_ejercicios_insert_propio on public.seguimiento_ejercicios;
drop policy if exists seguimiento_ejercicios_update_propio on public.seguimiento_ejercicios;
drop policy if exists seguimiento_ejercicios_delete_propio on public.seguimiento_ejercicios;

alter table public.seguimiento_ejercicios enable row level security;

create policy seguimiento_ejercicios_select_propio
on public.seguimiento_ejercicios
for select
using (public.es_duenio_seguimiento(seguimiento_id));

create policy seguimiento_ejercicios_insert_propio
on public.seguimiento_ejercicios
for insert
with check (public.es_duenio_seguimiento(seguimiento_id));

create policy seguimiento_ejercicios_update_propio
on public.seguimiento_ejercicios
for update
using (public.es_duenio_seguimiento(seguimiento_id))
with check (public.es_duenio_seguimiento(seguimiento_id));

create policy seguimiento_ejercicios_delete_propio
on public.seguimiento_ejercicios
for delete
using (public.es_duenio_seguimiento(seguimiento_id));

drop policy if exists perfiles_select_propio on public.perfiles;
drop policy if exists perfiles_update_propio on public.perfiles;

create policy perfiles_select_propio
on public.perfiles
for select
using (id = auth.uid());

create policy perfiles_update_propio
on public.perfiles
for update
using (id = auth.uid())
with check (id = auth.uid());
