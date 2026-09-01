import 'package:supabase/supabase.dart';

import '../../../../core/servicios/servicio_supabase.dart';
import '../../domain/entities/usuario_autenticado.dart';

class RepositorioAutenticacionSupabase {
  const RepositorioAutenticacionSupabase();

  SupabaseClient get _cliente => ServicioSupabase.cliente;

  Future<UsuarioAutenticado?> obtenerUsuarioActual() async {
    if (!ServicioSupabase.estaInicializado) {
      return null;
    }

    final usuario = _cliente.auth.currentUser;
    if (usuario == null) {
      return null;
    }

    return _obtenerPerfil(usuario);
  }

  Future<UsuarioAutenticado> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final respuesta = await _cliente.auth.signInWithPassword(
      email: correo,
      password: contrasena,
    );

    final usuario = respuesta.user;
    if (usuario == null) {
      throw const AuthException('No se pudo iniciar sesion.');
    }

    return _obtenerPerfil(usuario);
  }

  Future<void> cerrarSesion() async {
    if (!ServicioSupabase.estaInicializado) {
      return;
    }

    await _cliente.auth.signOut();
  }

  Future<UsuarioAutenticado> _obtenerPerfil(User usuario) async {
    final correo = usuario.email ?? '';

    try {
      final perfil = await _cliente
          .from('perfiles')
          .select('id, id_publico, nombre_completo, correo, rol')
          .eq('id', usuario.id)
          .maybeSingle();

      if (perfil != null) {
        return UsuarioAutenticado(
          id: perfil['id'] as String,
          correo: (perfil['correo'] as String?) ?? correo,
          nombreCompleto:
              (perfil['nombre_completo'] as String?) ?? 'Usuario GymPro',
          rol: (perfil['rol'] as String?) ?? _rolDesdeMetadata(usuario),
          idPublico: (perfil['id_publico'] as String?) ?? '',
        );
      }
    } catch (_) {}

    return UsuarioAutenticado(
      id: usuario.id,
      correo: correo,
      nombreCompleto:
          (usuario.userMetadata?['nombre_completo'] as String?) ??
          'Usuario GymPro',
      rol: _rolDesdeMetadata(usuario),
      idPublico: '',
    );
  }

  String _rolDesdeMetadata(User usuario) {
    return (usuario.appMetadata['rol'] as String?) ?? 'usuario';
  }
}
