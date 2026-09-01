create or replace function public.es_duenio_rutina(p_rutina_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.rutinas
    where id = p_rutina_id
      and usuario_id = auth.uid()
  );
$$;

create or replace function public.es_duenio_rutina_dia(p_rutina_dia_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.rutina_dias rd
    join public.rutinas r on r.id = rd.rutina_id
    where rd.id = p_rutina_dia_id
      and r.usuario_id = auth.uid()
  );
$$;

alter table public.rutinas enable row level security;
alter table public.rutina_dias enable row level security;
alter table public.rutina_dia_musculos enable row level security;

drop policy if exists rutinas_select_propio on public.rutinas;
drop policy if exists rutinas_insert_propio on public.rutinas;
drop policy if exists rutinas_update_propio on public.rutinas;
drop policy if exists rutinas_delete_propio on public.rutinas;

create policy rutinas_select_propio
on public.rutinas
for select
using (usuario_id = auth.uid());

create policy rutinas_insert_propio
on public.rutinas
for insert
with check (usuario_id = auth.uid());

create policy rutinas_update_propio
on public.rutinas
for update
using (usuario_id = auth.uid())
with check (usuario_id = auth.uid());

create policy rutinas_delete_propio
on public.rutinas
for delete
using (usuario_id = auth.uid());

drop policy if exists rutina_dias_select_propio on public.rutina_dias;
drop policy if exists rutina_dias_insert_propio on public.rutina_dias;
drop policy if exists rutina_dias_update_propio on public.rutina_dias;
drop policy if exists rutina_dias_delete_propio on public.rutina_dias;

create policy rutina_dias_select_propio
on public.rutina_dias
for select
using (public.es_duenio_rutina(rutina_id));

create policy rutina_dias_insert_propio
on public.rutina_dias
for insert
with check (public.es_duenio_rutina(rutina_id));

create policy rutina_dias_update_propio
on public.rutina_dias
for update
using (public.es_duenio_rutina(rutina_id))
with check (public.es_duenio_rutina(rutina_id));

create policy rutina_dias_delete_propio
on public.rutina_dias
for delete
using (public.es_duenio_rutina(rutina_id));

drop policy if exists rutina_dia_musculos_select_propio on public.rutina_dia_musculos;
drop policy if exists rutina_dia_musculos_insert_propio on public.rutina_dia_musculos;
drop policy if exists rutina_dia_musculos_update_propio on public.rutina_dia_musculos;
drop policy if exists rutina_dia_musculos_delete_propio on public.rutina_dia_musculos;

create policy rutina_dia_musculos_select_propio
on public.rutina_dia_musculos
for select
using (public.es_duenio_rutina_dia(rutina_dia_id));

create policy rutina_dia_musculos_insert_propio
on public.rutina_dia_musculos
for insert
with check (public.es_duenio_rutina_dia(rutina_dia_id));

create policy rutina_dia_musculos_update_propio
on public.rutina_dia_musculos
for update
using (public.es_duenio_rutina_dia(rutina_dia_id))
with check (public.es_duenio_rutina_dia(rutina_dia_id));

create policy rutina_dia_musculos_delete_propio
on public.rutina_dia_musculos
for delete
using (public.es_duenio_rutina_dia(rutina_dia_id));
