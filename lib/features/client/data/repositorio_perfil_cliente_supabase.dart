import 'package:supabase/supabase.dart';

import '../../../core/servicios/servicio_supabase.dart';
import '../../auth/domain/entities/usuario_autenticado.dart';

class PerfilCliente {
  const PerfilCliente({
    required this.nombreCompleto,
    required this.correo,
    required this.ci,
    this.pesoKg,
    this.alturaCm,
  });

  final String nombreCompleto;
  final String correo;
  final String ci;
  final num? pesoKg;
  final num? alturaCm;
}

class RepositorioPerfilClienteSupabase {
  const RepositorioPerfilClienteSupabase();

  SupabaseClient get _cliente => ServicioSupabase.cliente;

  Future<PerfilCliente> cargarPerfil(UsuarioAutenticado usuario) async {
    final perfil = await _cliente
        .from('perfiles')
        .select('nombre_completo, correo, peso_kg, altura_cm')
        .eq('id', usuario.id)
        .maybeSingle();

    final cliente = await _cliente
        .from('clientes')
        .select('ci')
        .eq('perfil_id', usuario.id)
        .maybeSingle();

    return PerfilCliente(
      nombreCompleto:
          (perfil?['nombre_completo'] as String?) ?? usuario.nombreCompleto,
      correo: (perfil?['correo'] as String?) ?? usuario.correo,
      ci: (cliente?['ci'] as String?) ?? '',
      pesoKg: perfil?['peso_kg'] as num?,
      alturaCm: perfil?['altura_cm'] as num?,
    );
  }

  Future<void> guardarPerfil({
    required String usuarioId,
    required String nombreCompleto,
    required num? pesoKg,
    required num? alturaCm,
  }) async {
    await _cliente
        .from('perfiles')
        .update({
          'nombre_completo': nombreCompleto,
          'peso_kg': pesoKg,
          'altura_cm': alturaCm,
        })
        .eq('id', usuarioId);
  }
}
