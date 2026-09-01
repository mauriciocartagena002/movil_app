import 'package:supabase/supabase.dart';
import '../../../core/servicios/servicio_supabase.dart';

class RegistroPeso {
  const RegistroPeso({
    required this.id,
    required this.usuarioId,
    required this.peso,
    required this.fecha,
  });

  final String id;
  final String usuarioId;
  final double peso;
  final DateTime fecha;
}

class RepositorioPesoClienteSupabase {
  const RepositorioPesoClienteSupabase();

  SupabaseClient get _cliente => ServicioSupabase.cliente;

  Future<List<RegistroPeso>> obtenerRegistros(String usuarioId) async {
    final respuesta = await _cliente
        .from('registros_peso')
        .select()
        .eq('usuario_id', usuarioId)
        .order('fecha', ascending: false);

    return (respuesta as List)
        .map(
          (registro) => RegistroPeso(
            id: registro['id'].toString(),
            usuarioId: registro['usuario_id'].toString(),
            peso: (registro['peso'] as num).toDouble(),
            fecha: DateTime.parse(registro['fecha'].toString()),
          ),
        )
        .toList();
  }

  Future<void> crearRegistro({
    required String usuarioId,
    required double peso,
    required DateTime fecha,
  }) async {
    await _cliente.from('registros_peso').insert({
      'usuario_id': usuarioId,
      'peso': peso,
      'fecha': fecha.toIso8601String().split('T').first,
    });
  }

  Future<void> actualizarRegistro({
    required String id,
    required double peso,
    required DateTime fecha,
  }) async {
    await _cliente
        .from('registros_peso')
        .update({
          'peso': peso,
          'fecha': fecha.toIso8601String().split('T').first,
        })
        .eq('id', id);
  }

  Future<void> eliminarRegistro(String id) async {
    await _cliente.from('registros_peso').delete().eq('id', id);
  }
}