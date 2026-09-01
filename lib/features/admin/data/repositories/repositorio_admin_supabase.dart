import 'package:supabase/supabase.dart';

import '../../../../core/servicios/servicio_supabase.dart';

class ClienteAdmin {
  const ClienteAdmin({
    required this.perfilId,
    required this.nombreCompleto,
    required this.ci,
    required this.correo,
    required this.inicioMensualidad,
    required this.finMensualidad,
    required this.estadoManual,
  });

  final String perfilId;
  final String nombreCompleto;
  final String ci;
  final String correo;
  final DateTime inicioMensualidad;
  final DateTime finMensualidad;
  final bool? estadoManual;

  ClienteAdmin copyWith({
    bool? estadoManual,
    bool limpiarEstadoManual = false,
  }) {
    return ClienteAdmin(
      perfilId: perfilId,
      nombreCompleto: nombreCompleto,
      ci: ci,
      correo: correo,
      inicioMensualidad: inicioMensualidad,
      finMensualidad: finMensualidad,
      estadoManual: limpiarEstadoManual
          ? null
          : estadoManual ?? this.estadoManual,
    );
  }

  bool get mensualidadVencida {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final finOnly = DateTime(
      finMensualidad.year,
      finMensualidad.month,
      finMensualidad.day,
    );
    return todayOnly.isAfter(finOnly);
  }

  bool get estaActivo {
    if (estadoManual != null) {
      return estadoManual!;
    }
    return !mensualidadVencida;
  }
}

class RegistroClienteAdmin {
  const RegistroClienteAdmin({
    required this.nombreCompleto,
    required this.ci,
    required this.correo,
    required this.contrasena,
    required this.inicioMensualidad,
    required this.finMensualidad,
  });

  final String nombreCompleto;
  final String ci;
  final String correo;
  final String contrasena;
  final DateTime inicioMensualidad;
  final DateTime finMensualidad;
}

class RepositorioAdminSupabase {
  const RepositorioAdminSupabase();

  SupabaseClient get _cliente => ServicioSupabase.cliente;

  Future<List<ClienteAdmin>> listarClientes() async {
    final datos = await _cliente
        .from('clientes')
        .select(
          'perfil_id, ci, inicio_mensualidad, fin_mensualidad, estado_manual, perfiles!clientes_perfil_id_fkey(nombre_completo, correo)',
        )
        .order('creado_en', ascending: false);

    return datos
        .map<ClienteAdmin>((item) => _clienteDesdeMapa(item))
        .toList(growable: false);
  }

  Future<ClienteAdmin> registrarCliente(RegistroClienteAdmin registro) async {
    final token = _cliente.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Sesion requerida.');
    }

    try {
      final respuesta = await _cliente.functions.invoke(
        'registrar-cliente',
        headers: {'Authorization': 'Bearer $token'},
        body: {
          'nombre_completo': registro.nombreCompleto,
          'ci': registro.ci,
          'correo': registro.correo,
          'contrasena': registro.contrasena,
          'inicio_mensualidad': _fechaIso(registro.inicioMensualidad),
          'fin_mensualidad': _fechaIso(registro.finMensualidad),
        },
      );

      final data = respuesta.data;
      if (data is Map && data['cliente'] is Map) {
        return _clienteDesdeMapa(Map<String, dynamic>.from(data['cliente']));
      }

      throw Exception('Respuesta invalida.');
    } on FunctionsHttpException catch (error) {
      throw Exception(_mensajeFuncion(error.details));
    } on FunctionsRelayException catch (error) {
      throw Exception(_mensajeFuncion(error.details));
    } on FunctionsFetchException {
      throw Exception('No se pudo conectar con Supabase.');
    }
  }

  Future<void> editarEstado(String perfilId, bool activo) async {
    await _cliente
        .from('clientes')
        .update({'estado_manual': activo})
        .eq('perfil_id', perfilId);
  }

  Future<void> restaurarEstadoAutomatico(String perfilId) async {
    await _cliente
        .from('clientes')
        .update({'estado_manual': null})
        .eq('perfil_id', perfilId);
  }

  ClienteAdmin _clienteDesdeMapa(Map<String, dynamic> item) {
    final perfil = item['perfiles'] is Map
        ? Map<String, dynamic>.from(item['perfiles'])
        : <String, dynamic>{};

    return ClienteAdmin(
      perfilId: item['perfil_id'] as String,
      nombreCompleto:
          (item['nombre_completo'] as String?) ??
          (perfil['nombre_completo'] as String?) ??
          'Usuario GymPro',
      ci: (item['ci'] as String?) ?? '',
      correo:
          (item['correo'] as String?) ?? (perfil['correo'] as String?) ?? '',
      inicioMensualidad: DateTime.parse(item['inicio_mensualidad'] as String),
      finMensualidad: DateTime.parse(item['fin_mensualidad'] as String),
      estadoManual: item['estado_manual'] as bool?,
    );
  }

  String _mensajeFuncion(Object? details) {
    if (details is Map && details['error'] is String) {
      return details['error'] as String;
    }

    if (details is String && details.trim().isNotEmpty) {
      return details;
    }

    return 'No se pudo completar la operacion.';
  }

  String _fechaIso(DateTime fecha) {
    final month = fecha.month.toString().padLeft(2, '0');
    final day = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$month-$day';
  }
}
