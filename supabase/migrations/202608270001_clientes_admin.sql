create table if not exists public.clientes (
  perfil_id uuid primary key references public.perfiles(id) on delete cascade,
  ci text not null unique,
  inicio_mensualidad date not null,
  fin_mensualidad date not null,
  estado_manual boolean,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create index if not exists clientes_fin_mensualidad_idx
  on public.clientes (fin_mensualidad);

create or replace function public.es_administrador()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.perfiles
    where id = auth.uid()
      and rol = 'administrador'
  );
$$;

create or replace function public.marcar_actualizado_en()
returns trigger
language plpgsql
as $$
begin
  new.actualizado_en = now();
  return new;
end;
$$;

drop trigger if exists clientes_actualizado_en on public.clientes;

create trigger clientes_actualizado_en
before update on public.clientes
for each row
execute function public.marcar_actualizado_en();

alter table public.clientes enable row level security;

drop policy if exists clientes_select_admin on public.clientes;
drop policy if exists clientes_insert_admin on public.clientes;
drop policy if exists clientes_update_admin on public.clientes;
drop policy if exists clientes_delete_admin on public.clientes;
drop policy if exists clientes_select_propio on public.clientes;

create policy clientes_select_admin
on public.clientes
for select
using (public.es_administrador());

create policy clientes_insert_admin
on public.clientes
for insert
with check (public.es_administrador());

create policy clientes_update_admin
on public.clientes
for update
using (public.es_administrador())
with check (public.es_administrador());

create policy clientes_delete_admin
on public.clientes
for delete
using (public.es_administrador());

create policy clientes_select_propio
on public.clientes
for select
using (perfil_id = auth.uid());

drop policy if exists perfiles_select_admin on public.perfiles;

create policy perfiles_select_admin
on public.perfiles
for select
using (public.es_administrador());
