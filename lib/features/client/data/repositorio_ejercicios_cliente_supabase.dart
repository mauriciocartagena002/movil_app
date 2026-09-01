import 'package:supabase/supabase.dart';

import '../../../core/servicios/servicio_supabase.dart';

class EjercicioCliente {
  const EjercicioCliente({
    required this.id,
    required this.musculoId,
    required this.parteMusculoId,
    required this.musculo,
    required this.parte,
    required this.nombre,
    required this.esPredeterminado,
  });

  final String id;
  final String musculoId;
  final String parteMusculoId;
  final String musculo;
  final String parte;
  final String nombre;
  final bool esPredeterminado;
}

class OpcionMusculoCliente {
  const OpcionMusculoCliente({required this.id, required this.nombre});

  final String id;
  final String nombre;
}

class OpcionParteMusculoCliente {
  const OpcionParteMusculoCliente({
    required this.id,
    required this.musculoId,
    required this.nombre,
  });

  final String id;
  final String musculoId;
  final String nombre;
}

class CatalogoEjerciciosCliente {
  const CatalogoEjerciciosCliente({
    required this.musculos,
    required this.partes,
    required this.ejercicios,
  });

  final List<OpcionMusculoCliente> musculos;
  final List<OpcionParteMusculoCliente> partes;
  final List<EjercicioCliente> ejercicios;
}

class RepositorioEjerciciosClienteSupabase {
  const RepositorioEjerciciosClienteSupabase();

  SupabaseClient get _cliente => ServicioSupabase.cliente;

  Future<CatalogoEjerciciosCliente> cargar(String usuarioId) async {
    final musculosData = await _cliente
        .from('musculos')
        .select('id, nombre')
        .eq('estado', 'activo')
        .order('orden');

    final partesData = await _cliente
        .from('partes_musculo')
        .select('id, musculo_id, nombre')
        .eq('estado', 'activo')
        .order('orden');

    final ejerciciosData = await _cliente
        .from('ejercicios_cliente')
        .select('id, musculo_id, parte_musculo_id, nombre, es_predeterminado')
        .eq('usuario_id', usuarioId)
        .order('nombre');

    final musculos = musculosData
        .map<OpcionMusculoCliente>(
          (item) => OpcionMusculoCliente(
            id: item['id'] as String,
            nombre: item['nombre'] as String,
          ),
        )
        .toList(growable: false);

    final partes = partesData
        .map<OpcionParteMusculoCliente>(
          (item) => OpcionParteMusculoCliente(
            id: item['id'] as String,
            musculoId: item['musculo_id'] as String,
            nombre: item['nombre'] as String,
          ),
        )
        .toList(growable: false);

    final musculoPorId = {for (final item in musculos) item.id: item.nombre};
    final partePorId = {for (final item in partes) item.id: item.nombre};

    final ejercicios = ejerciciosData
        .map<EjercicioCliente>(
          (item) => EjercicioCliente(
            id: item['id'] as String,
            musculoId: item['musculo_id'] as String,
            parteMusculoId: item['parte_musculo_id'] as String,
            musculo: musculoPorId[item['musculo_id']] ?? '',
            parte: partePorId[item['parte_musculo_id']] ?? '',
            nombre: item['nombre'] as String,
            esPredeterminado: (item['es_predeterminado'] as bool?) ?? false,
          ),
        )
        .toList(growable: false);

    return CatalogoEjerciciosCliente(
      musculos: musculos,
      partes: partes,
      ejercicios: ejercicios,
    );
  }

  Future<void> agregar({
    required String usuarioId,
    required String musculoId,
    required String parteMusculoId,
    required String nombre,
  }) async {
    await _cliente.from('ejercicios_cliente').insert({
      'usuario_id': usuarioId,
      'musculo_id': musculoId,
      'parte_musculo_id': parteMusculoId,
      'nombre': nombre,
      'es_predeterminado': false,
    });
  }

  Future<void> eliminar(String id) async {
    await _cliente.from('ejercicios_cliente').delete().eq('id', id);
  }

  Future<void> reiniciar() async {
    await _cliente.rpc('reiniciar_ejercicios_cliente');
  }
}
