import 'dart:convert';

import 'package:supabase/supabase.dart';

import '../../../core/servicios/servicio_supabase.dart';

class RegistroSeguimientoCliente {
  const RegistroSeguimientoCliente({
    this.id,
    this.seguimientoId,
    required this.fecha,
    required this.musculo,
    required this.parte,
    required this.ejercicio,
    required this.series,
    required this.repeticiones,
  });

  final String? id;
  final String? seguimientoId;
  final DateTime fecha;
  final String musculo;
  final String parte;
  final String ejercicio;
  final int series;
  final int repeticiones;
}

class RepositorioSeguimientoClienteSupabase {
  const RepositorioSeguimientoClienteSupabase();

  SupabaseClient get _cliente => ServicioSupabase.cliente;

  Future<List<RegistroSeguimientoCliente>> listarMes({
    required String usuarioId,
    required DateTime mes,
  }) async {
    final inicio = DateTime(mes.year, mes.month);
    final fin = DateTime(mes.year, mes.month + 1, 0);

    final seguimientos = await _cliente
        .from('seguimientos_musculares')
        .select('id, fecha')
        .eq('usuario_id', usuarioId)
        .gte('fecha', _fechaIso(inicio))
        .lte('fecha', _fechaIso(fin));

    final seguimientoPorId = <String, DateTime>{};
    for (final item in seguimientos) {
      seguimientoPorId[item['id'] as String] = DateTime.parse(
        item['fecha'] as String,
      );
    }

    if (seguimientoPorId.isEmpty) {
      return const [];
    }

    final ejercicios = await _cliente
        .from('seguimiento_ejercicios')
        .select(
          'id, seguimiento_id, ejercicio_manual, series, repeticiones_por_serie, notas, orden',
        )
        .inFilter('seguimiento_id', seguimientoPorId.keys.toList())
        .order('orden');

    return ejercicios
        .map<RegistroSeguimientoCliente>((item) {
          final notas = _leerNotas(item['notas'] as String?);
          final seguimientoId = item['seguimiento_id'] as String;
          return RegistroSeguimientoCliente(
            id: item['id'] as String,
            seguimientoId: seguimientoId,
            fecha: seguimientoPorId[seguimientoId]!,
            musculo: notas['musculo'] ?? '',
            parte: notas['parte'] ?? '',
            ejercicio: (item['ejercicio_manual'] as String?) ?? '',
            series: item['series'] as int,
            repeticiones: item['repeticiones_por_serie'] as int,
          );
        })
        .toList(growable: false);
  }

  Future<RegistroSeguimientoCliente> guardar({
    required String usuarioId,
    required RegistroSeguimientoCliente registro,
  }) async {
    final seguimientoId = await _obtenerSeguimientoId(
      usuarioId: usuarioId,
      fecha: registro.fecha,
    );

    final body = <String, Object?>{
      'seguimiento_id': seguimientoId,
      'ejercicio_manual': registro.ejercicio,
      'series': registro.series,
      'repeticiones_por_serie': registro.repeticiones,
      'notas': jsonEncode({
        'musculo': registro.musculo,
        'parte': registro.parte,
      }),
    };

    if (registro.id == null) {
      body['orden'] = await _siguienteOrden(seguimientoId);
    }

    final data = registro.id == null
        ? await _cliente
              .from('seguimiento_ejercicios')
              .insert(body)
              .select('id')
              .single()
        : await _cliente
              .from('seguimiento_ejercicios')
              .update(body)
              .eq('id', registro.id!)
              .select('id')
              .single();

    return RegistroSeguimientoCliente(
      id: data['id'] as String,
      seguimientoId: seguimientoId,
      fecha: registro.fecha,
      musculo: registro.musculo,
      parte: registro.parte,
      ejercicio: registro.ejercicio,
      series: registro.series,
      repeticiones: registro.repeticiones,
    );
  }

  Future<void> eliminar(RegistroSeguimientoCliente registro) async {
    final id = registro.id;
    if (id == null) {
      return;
    }

    await _cliente.from('seguimiento_ejercicios').delete().eq('id', id);

    final seguimientoId = registro.seguimientoId;
    if (seguimientoId == null) {
      return;
    }

    final restantes = await _cliente
        .from('seguimiento_ejercicios')
        .select('id')
        .eq('seguimiento_id', seguimientoId)
        .limit(1);

    if (restantes.isEmpty) {
      await _cliente
          .from('seguimientos_musculares')
          .delete()
          .eq('id', seguimientoId);
    }
  }

  Future<String> _obtenerSeguimientoId({
    required String usuarioId,
    required DateTime fecha,
  }) async {
    final fechaTexto = _fechaIso(fecha);
    final existente = await _cliente
        .from('seguimientos_musculares')
        .select('id')
        .eq('usuario_id', usuarioId)
        .eq('fecha', fechaTexto)
        .maybeSingle();

    if (existente != null) {
      return existente['id'] as String;
    }

    final creado = await _cliente
        .from('seguimientos_musculares')
        .insert({'usuario_id': usuarioId, 'fecha': fechaTexto})
        .select('id')
        .single();

    return creado['id'] as String;
  }

  Future<int> _siguienteOrden(String seguimientoId) async {
    final data = await _cliente
        .from('seguimiento_ejercicios')
        .select('orden')
        .eq('seguimiento_id', seguimientoId)
        .order('orden', ascending: false)
        .limit(1);

    if (data.isEmpty) {
      return 1;
    }

    final ultimoOrden = (data.first['orden'] as int?) ?? 0;
    return ultimoOrden + 1;
  }

  Map<String, String> _leerNotas(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const {};
    }

    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return {
          'musculo': (decoded['musculo'] as String?) ?? '',
          'parte': (decoded['parte'] as String?) ?? '',
        };
      }
    } catch (_) {}

    return const {};
  }

  String _fechaIso(DateTime fecha) {
    final month = fecha.month.toString().padLeft(2, '0');
    final day = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$month-$day';
  }
}
