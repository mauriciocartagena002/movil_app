import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type RegistroCliente = {
  nombre_completo?: string;
  ci?: string;
  correo?: string;
  contrasena?: string;
  inicio_mensualidad?: string;
  fin_mensualidad?: string;
};

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function limpiarTexto(value: unknown) {
  return typeof value === "string" ? value.trim() : "";
}

function validarFecha(value: string) {
  return /^\d{4}-\d{2}-\d{2}$/.test(value);
}

async function buscarUsuarioPorCorreo(adminClient: ReturnType<typeof createClient>, correo: string) {
  let page = 1;

  while (page <= 10) {
    const { data, error } = await adminClient.auth.admin.listUsers({
      page,
      perPage: 100,
    });

    if (error) {
      throw error;
    }

    const usuario = data.users.find((item) => item.email === correo);
    if (usuario) {
      return usuario;
    }

    if (data.users.length < 100) {
      return null;
    }

    page += 1;
  }

  return null;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse({ error: "Metodo no permitido." }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: "Servidor no configurado." }, 500);
  }

  const token = request.headers.get("Authorization")?.replace("Bearer ", "");
  if (!token) {
    return jsonResponse({ error: "Sesion requerida." }, 401);
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: sesion, error: sesionError } = await adminClient.auth.getUser(
    token,
  );

  if (sesionError || !sesion.user) {
    return jsonResponse({ error: "Sesion no valida." }, 401);
  }

  const { data: perfilAdmin, error: perfilAdminError } = await adminClient
    .from("perfiles")
    .select("rol")
    .eq("id", sesion.user.id)
    .maybeSingle();

  if (perfilAdminError) {
    return jsonResponse({ error: "No se pudo validar el acceso." }, 500);
  }

  if (perfilAdmin?.rol !== "administrador") {
    return jsonResponse({ error: "Acceso restringido." }, 403);
  }

  let body: RegistroCliente;
  try {
    body = await request.json();
  } catch (_) {
    return jsonResponse({ error: "Datos invalidos." }, 400);
  }

  const nombreCompleto = limpiarTexto(body.nombre_completo);
  const ci = limpiarTexto(body.ci);
  const correo = limpiarTexto(body.correo).toLowerCase();
  const contrasena = limpiarTexto(body.contrasena);
  const inicioMensualidad = limpiarTexto(body.inicio_mensualidad);
  const finMensualidad = limpiarTexto(body.fin_mensualidad);

  if (nombreCompleto.length < 4) {
    return jsonResponse({ error: "Nombre invalido." }, 400);
  }

  if (!ci) {
    return jsonResponse({ error: "CI requerido." }, 400);
  }

  if (!correo.includes("@")) {
    return jsonResponse({ error: "Correo invalido." }, 400);
  }

  if (contrasena.length < 6) {
    return jsonResponse({ error: "Contrasena invalida." }, 400);
  }

  if (!validarFecha(inicioMensualidad) || !validarFecha(finMensualidad)) {
    return jsonResponse({ error: "Fechas invalidas." }, 400);
  }

  let usuarioAuth = await buscarUsuarioPorCorreo(adminClient, correo);

  if (!usuarioAuth) {
    const { data: nuevoUsuario, error: crearError } =
      await adminClient.auth.admin.createUser({
        email: correo,
        password: contrasena,
        email_confirm: true,
        user_metadata: { nombre_completo: nombreCompleto },
      });

    if (crearError || !nuevoUsuario.user) {
      return jsonResponse(
        { error: crearError?.message ?? "No se pudo crear el usuario." },
        400,
      );
    }

    usuarioAuth = nuevoUsuario.user;
  }

  const { error: metadataError } = await adminClient.auth.admin.updateUserById(
    usuarioAuth.id,
    {
      app_metadata: { rol: "usuario" },
      user_metadata: { nombre_completo: nombreCompleto },
    },
  );

  if (metadataError) {
    return jsonResponse({ error: "No se pudo actualizar Auth." }, 500);
  }

  const { data: perfilExistente } = await adminClient
    .from("perfiles")
    .select("id_publico")
    .eq("id", usuarioAuth.id)
    .maybeSingle();

  let idPublico = perfilExistente?.id_publico;
  if (!idPublico) {
    const { data: generado } = await adminClient.rpc("generar_id_publico");
    idPublico = typeof generado === "string"
      ? generado
      : String(Math.floor(1000000 + Math.random() * 9000000));
  }

  const { error: perfilError } = await adminClient.from("perfiles").upsert({
    id: usuarioAuth.id,
    id_publico: idPublico,
    nombre_completo: nombreCompleto,
    correo,
    rol: "usuario",
  }, { onConflict: "id" });

  if (perfilError) {
    return jsonResponse({ error: "No se pudo guardar el perfil." }, 500);
  }

  const { data: cliente, error: clienteError } = await adminClient
    .from("clientes")
    .upsert({
      perfil_id: usuarioAuth.id,
      ci,
      inicio_mensualidad: inicioMensualidad,
      fin_mensualidad: finMensualidad,
      estado_manual: null,
    }, { onConflict: "perfil_id" })
    .select(
      "perfil_id, ci, inicio_mensualidad, fin_mensualidad, estado_manual",
    )
    .single();

  if (clienteError) {
    return jsonResponse({ error: "No se pudo guardar el cliente." }, 500);
  }

  return jsonResponse({
    cliente: {
      ...cliente,
      nombre_completo: nombreCompleto,
      correo,
    },
  });
});
