import 'package:supabase/supabase.dart';

import '../../../core/servicios/servicio_supabase.dart';

class RutinaClienteGuardada {
  const RutinaClienteGuardada({required this.musculosPorDia});

  final Map<String, Set<String>> musculosPorDia;
}

class RepositorioRutinasClienteSupabase {
  const RepositorioRutinasClienteSupabase();

  static const _routineName = 'Rutina principal';
  static const _weekDays = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
  static const _weekDayNames = [
    'Lunes',
    'Martes',
    'Miercoles',
    'Jueves',
    'Viernes',
    'Sabado',
    'Domingo',
  ];

  SupabaseClient get _cliente => ServicioSupabase.cliente;

  Future<RutinaClienteGuardada> cargar(String usuarioId) async {
    final rutina = await _buscarRutina(usuarioId);
    if (rutina == null) {
      return const RutinaClienteGuardada(musculosPorDia: {});
    }

    final rutinaId = rutina['id'] as String;
    final dias = await _cliente
        .from('rutina_dias')
        .select('id, dia_semana')
        .eq('rutina_id', rutinaId)
        .order('orden');

    if (dias.isEmpty) {
      return const RutinaClienteGuardada(musculosPorDia: {});
    }

    final diaPorId = <String, int>{};
    for (final dia in dias) {
      diaPorId[dia['id'] as String] = dia['dia_semana'] as int;
    }

    final registros = await _cliente
        .from('rutina_dia_musculos')
        .select('rutina_dia_id, musculo_id')
        .inFilter('rutina_dia_id', diaPorId.keys.toList())
        .order('orden');

    if (registros.isEmpty) {
      return const RutinaClienteGuardada(musculosPorDia: {});
    }

    final musculos = await _cliente
        .from('musculos')
        .select('id, nombre')
        .eq('estado', 'activo');
    final musculoPorId = {
      for (final musculo in musculos)
        musculo['id'] as String: musculo['nombre'] as String,
    };

    final resultado = <String, Set<String>>{};
    for (final registro in registros) {
      final diaSemana = diaPorId[registro['rutina_dia_id']];
      final nombreMusculo = musculoPorId[registro['musculo_id']];
      if (diaSemana == null ||
          diaSemana < 1 ||
          diaSemana > _weekDays.length ||
          nombreMusculo == null) {
        continue;
      }

      resultado
          .putIfAbsent(_weekDays[diaSemana - 1], () => <String>{})
          .add(nombreMusculo);
    }

    return RutinaClienteGuardada(musculosPorDia: resultado);
  }

  Future<void> guardar({
    required String usuarioId,
    required Map<String, Set<String>> musculosPorDia,
  }) async {
    final rutinaId = await _obtenerRutinaId(usuarioId);
    final diasActuales = await _cliente
        .from('rutina_dias')
        .select('id')
        .eq('rutina_id', rutinaId);
    final diasActualesIds = [
      for (final dia in diasActuales) dia['id'] as String,
    ];

    if (diasActualesIds.isNotEmpty) {
      await _cliente
          .from('rutina_dia_musculos')
          .delete()
          .inFilter('rutina_dia_id', diasActualesIds);
      await _cliente
          .from('rutina_dias')
          .delete()
          .inFilter('id', diasActualesIds);
    }

    final musculos = await _cliente
        .from('musculos')
        .select('id, nombre')
        .eq('estado', 'activo');
    final musculoIdPorNombre = {
      for (final musculo in musculos)
        (musculo['nombre'] as String).toLowerCase(): musculo['id'] as String,
    };

    for (var index = 0; index < _weekDays.length; index++) {
      final dia = _weekDays[index];
      final nombresMusculos = musculosPorDia[dia] ?? const <String>{};
      if (nombresMusculos.isEmpty) {
        continue;
      }

      final diaCreado = await _cliente
          .from('rutina_dias')
          .insert({
            'rutina_id': rutinaId,
            'dia_semana': index + 1,
            'nombre_dia': _weekDayNames[index],
            'orden': index + 1,
          })
          .select('id')
          .single();

      final rutinaDiaId = diaCreado['id'] as String;
      final registros = <Map<String, Object?>>[];
      var orden = 0;
      for (final nombreMusculo in nombresMusculos) {
        final musculoId = musculoIdPorNombre[nombreMusculo.toLowerCase()];
        if (musculoId == null) {
          continue;
        }

        orden++;
        registros.add({
          'rutina_dia_id': rutinaDiaId,
          'musculo_id': musculoId,
          'orden': orden,
        });
      }

      if (registros.isNotEmpty) {
        await _cliente.from('rutina_dia_musculos').insert(registros);
      }
    }
  }

  Future<Map<String, dynamic>?> _buscarRutina(String usuarioId) async {
    final data = await _cliente
        .from('rutinas')
        .select('id')
        .eq('usuario_id', usuarioId)
        .eq('nombre', _routineName)
        .order('creado_en')
        .limit(1);

    if (data.isEmpty) {
      return null;
    }

    return data.first;
  }

  Future<String> _obtenerRutinaId(String usuarioId) async {
    final existente = await _buscarRutina(usuarioId);
    if (existente != null) {
      return existente['id'] as String;
    }

    final creada = await _cliente
        .from('rutinas')
        .insert({
          'usuario_id': usuarioId,
          'nombre': _routineName,
          'descripcion': null,
          'es_publica': false,
          'creada_por_admin': false,
          'estado': 'activo',
        })
        .select('id')
        .single();

    return creada['id'] as String;
  }
}
