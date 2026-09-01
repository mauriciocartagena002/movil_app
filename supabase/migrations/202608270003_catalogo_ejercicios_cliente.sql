create table if not exists public.ejercicios_cliente (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.perfiles(id) on delete cascade,
  musculo_id uuid not null references public.musculos(id) on delete cascade,
  parte_musculo_id uuid not null references public.partes_musculo(id) on delete cascade,
  nombre text not null,
  es_predeterminado boolean not null default false,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create index if not exists ejercicios_cliente_usuario_idx
on public.ejercicios_cliente (usuario_id);

create index if not exists ejercicios_cliente_parte_idx
on public.ejercicios_cliente (parte_musculo_id);

drop trigger if exists ejercicios_cliente_actualizado_en on public.ejercicios_cliente;

create trigger ejercicios_cliente_actualizado_en
before update on public.ejercicios_cliente
for each row
execute function public.marcar_actualizado_en();

do $$
declare
  catalogo jsonb := '[
    {"nombre":"Pecho","partes":[
      {"nombre":"Superior","ejercicios":["Press inclinado","Aperturas inclinadas","Cruce alto"]},
      {"nombre":"Medio","ejercicios":["Press banca","Aperturas planas","Flexiones"]},
      {"nombre":"Inferior","ejercicios":["Fondos","Press declinado","Cruce bajo"]}
    ]},
    {"nombre":"Hombro","partes":[
      {"nombre":"Deltoide anterior","ejercicios":["Press militar","Elevacion frontal","Press Arnold"]},
      {"nombre":"Deltoide posterior","ejercicios":["Face pull","Pajaros","Remo alto posterior"]},
      {"nombre":"Deltoide medial","ejercicios":["Elevaciones laterales","Remo al menton","Press maquina"]}
    ]},
    {"nombre":"Triceps","partes":[
      {"nombre":"Cabeza larga","ejercicios":["Extension sobre cabeza","Press frances","Copa mancuerna"]},
      {"nombre":"Cabeza lateral","ejercicios":["Extension en polea","Fondos en paralelas","Press cerrado"]},
      {"nombre":"Cabeza medial","ejercicios":["Jalon inverso","Patada triceps","Extension cuerda"]}
    ]},
    {"nombre":"Espalda","partes":[
      {"nombre":"Espalda alta","ejercicios":["Dominadas","Jalon al pecho","Remo sentado"]},
      {"nombre":"Deltoides","ejercicios":["Face pull","Pajaros","Remo alto posterior"]},
      {"nombre":"Espalda baja","ejercicios":["Peso muerto","Hiperextensiones","Buenos dias"]}
    ]},
    {"nombre":"Biceps","partes":[
      {"nombre":"Cabeza larga","ejercicios":["Curl inclinado","Curl barra recta","Curl concentrado"]},
      {"nombre":"Cabeza corta","ejercicios":["Curl predicador","Curl spider","Curl polea baja"]},
      {"nombre":"Braquiales","ejercicios":["Curl martillo","Curl reverso","Curl cuerda"]}
    ]},
    {"nombre":"Antebrazo","partes":[
      {"nombre":"Flexores","ejercicios":["Curl muneca","Agarre estatico","Farmer hold"]},
      {"nombre":"Extensores","ejercicios":["Curl reverso muneca","Extension dedos","Rodillo antebrazo"]},
      {"nombre":"Braquiorradial","ejercicios":["Curl martillo","Curl reverso","Curl Zottman"]}
    ]},
    {"nombre":"Gluteos","partes":[
      {"nombre":"Gluteo mayor","ejercicios":["Hip thrust","Peso muerto rumano","Sentadilla profunda"]},
      {"nombre":"Gluteo medio","ejercicios":["Abduccion cadera","Caminata lateral","Step up lateral"]},
      {"nombre":"Gluteo menor","ejercicios":["Clamshell","Patada lateral","Puente unilateral"]}
    ]},
    {"nombre":"Pierna","partes":[
      {"nombre":"Cuadriceps","ejercicios":["Sentadilla","Prensa","Extension de cuadriceps"]},
      {"nombre":"Femorales","ejercicios":["Curl femoral","Peso muerto rumano","Buenos dias"]},
      {"nombre":"Pantorrillas","ejercicios":["Elevacion de talones","Gemelo sentado","Gemelo prensa"]},
      {"nombre":"Aductores","ejercicios":["Aductor maquina","Zancada lateral","Sentadilla sumo"]}
    ]},
    {"nombre":"Abdominales","partes":[
      {"nombre":"Recto abdominal","ejercicios":["Crunch","Elevacion de piernas","Ab wheel"]},
      {"nombre":"Oblicuos","ejercicios":["Plancha lateral","Giro ruso","Woodchopper"]},
      {"nombre":"Transverso","ejercicios":["Plancha","Dead bug","Vacuum abdominal"]}
    ]}
  ]'::jsonb;
  musculo jsonb;
  parte jsonb;
  ejercicio text;
  v_musculo_id uuid;
  v_parte_id uuid;
  v_ejercicio_id uuid;
  musculo_orden int := 0;
  parte_orden int;
  ejercicio_orden int;
begin
  for musculo in select * from jsonb_array_elements(catalogo)
  loop
    musculo_orden := musculo_orden + 1;
    v_musculo_id := null;

    select id into v_musculo_id
    from public.musculos
    where lower(nombre) = lower(musculo->>'nombre')
    limit 1;

    if v_musculo_id is null then
      insert into public.musculos (nombre, orden, estado)
      values (musculo->>'nombre', musculo_orden, 'activo')
      returning id into v_musculo_id;
    else
      update public.musculos
      set orden = musculo_orden, estado = 'activo'
      where id = v_musculo_id;
    end if;

    parte_orden := 0;
    for parte in select * from jsonb_array_elements(musculo->'partes')
    loop
      parte_orden := parte_orden + 1;
      v_parte_id := null;

      select id into v_parte_id
      from public.partes_musculo
      where public.partes_musculo.musculo_id = v_musculo_id
        and lower(nombre) = lower(parte->>'nombre')
      limit 1;

      if v_parte_id is null then
        insert into public.partes_musculo (musculo_id, nombre, orden, estado)
        values (v_musculo_id, parte->>'nombre', parte_orden, 'activo')
        returning id into v_parte_id;
      else
        update public.partes_musculo
        set orden = parte_orden, estado = 'activo'
        where id = v_parte_id;
      end if;

      ejercicio_orden := 0;
      for ejercicio in select value::text from jsonb_array_elements_text(parte->'ejercicios')
      loop
        ejercicio_orden := ejercicio_orden + 1;
        v_ejercicio_id := null;

        select id into v_ejercicio_id
        from public.ejercicios
        where public.ejercicios.musculo_id = v_musculo_id
          and parte_musculo_id = v_parte_id
          and lower(nombre) = lower(ejercicio)
        limit 1;

        if v_ejercicio_id is null then
          insert into public.ejercicios (
            musculo_id,
            parte_musculo_id,
            nombre,
            estado
          )
          values (v_musculo_id, v_parte_id, ejercicio, 'activo')
          returning id into v_ejercicio_id;
        else
          update public.ejercicios
          set estado = 'activo'
          where id = v_ejercicio_id;
        end if;
      end loop;
    end loop;
  end loop;
end $$;

create or replace function public.sincronizar_ejercicios_cliente(p_usuario_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(auth.role(), '') <> 'service_role'
    and current_user not in ('postgres', 'supabase_admin')
    and (auth.uid() is null or p_usuario_id <> auth.uid())
    and not public.es_administrador() then
    raise exception 'Acceso restringido.';
  end if;

  insert into public.ejercicios_cliente (
    usuario_id,
    musculo_id,
    parte_musculo_id,
    nombre,
    es_predeterminado
  )
  select
    p_usuario_id,
    e.musculo_id,
    e.parte_musculo_id,
    e.nombre,
    true
  from public.ejercicios e
  where e.estado = 'activo'
    and not exists (
      select 1
      from public.ejercicios_cliente ec
      where ec.usuario_id = p_usuario_id
        and ec.parte_musculo_id = e.parte_musculo_id
        and lower(ec.nombre) = lower(e.nombre)
    );
end;
$$;

create or replace function public.reiniciar_ejercicios_cliente()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Sesion requerida.';
  end if;

  delete from public.ejercicios_cliente
  where usuario_id = auth.uid();

  perform public.sincronizar_ejercicios_cliente(auth.uid());
end;
$$;

create or replace function public.sincronizar_ejercicios_cliente_trigger()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.rol = 'usuario' then
    perform public.sincronizar_ejercicios_cliente(new.id);
  end if;
  return new;
end;
$$;

drop trigger if exists perfiles_sincronizar_ejercicios_cliente on public.perfiles;

create trigger perfiles_sincronizar_ejercicios_cliente
after insert or update of rol on public.perfiles
for each row
execute function public.sincronizar_ejercicios_cliente_trigger();

select public.sincronizar_ejercicios_cliente(id)
from public.perfiles
where rol = 'usuario';

alter table public.ejercicios_cliente enable row level security;

drop policy if exists ejercicios_cliente_select_propio on public.ejercicios_cliente;
drop policy if exists ejercicios_cliente_insert_propio on public.ejercicios_cliente;
drop policy if exists ejercicios_cliente_update_propio on public.ejercicios_cliente;
drop policy if exists ejercicios_cliente_delete_propio on public.ejercicios_cliente;

create policy ejercicios_cliente_select_propio
on public.ejercicios_cliente
for select
using (usuario_id = auth.uid());

create policy ejercicios_cliente_insert_propio
on public.ejercicios_cliente
for insert
with check (usuario_id = auth.uid());

create policy ejercicios_cliente_update_propio
on public.ejercicios_cliente
for update
using (usuario_id = auth.uid())
with check (usuario_id = auth.uid());

create policy ejercicios_cliente_delete_propio
on public.ejercicios_cliente
for delete
using (usuario_id = auth.uid());

drop policy if exists musculos_select_autenticado on public.musculos;
drop policy if exists partes_musculo_select_autenticado on public.partes_musculo;
drop policy if exists ejercicios_select_autenticado on public.ejercicios;

create policy musculos_select_autenticado
on public.musculos
for select
using (auth.uid() is not null);

create policy partes_musculo_select_autenticado
on public.partes_musculo
for select
using (auth.uid() is not null);

create policy ejercicios_select_autenticado
on public.ejercicios
for select
using (auth.uid() is not null);
