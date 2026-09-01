import 'package:flutter/material.dart';

import '../../../admin/presentation/pages/pantalla_inicio_admin.dart';
import '../../../client/presentation/pages/pantalla_cliente.dart';
import '../../../client/presentation/theme/colores_cliente.dart';
import '../../../../core/servicios/servicio_supabase.dart';
import '../../data/repositories/repositorio_autenticacion_supabase.dart';
import '../../domain/entities/usuario_autenticado.dart';
import 'pantalla_login.dart';

class PuertaAutenticacion extends StatefulWidget {
  const PuertaAutenticacion({super.key});

  @override
  State<PuertaAutenticacion> createState() => _PuertaAutenticacionState();
}

class _PuertaAutenticacionState extends State<PuertaAutenticacion> {
  final _repositorio = const RepositorioAutenticacionSupabase();
  late final Future<UsuarioAutenticado?> _usuarioInicial;
  UsuarioAutenticado? _usuario;

  @override
  void initState() {
    super.initState();
    _usuarioInicial = _prepararSesion();
  }

  Future<UsuarioAutenticado?> _prepararSesion() async {
    await ServicioSupabase.inicializar();
    return _repositorio.obtenerUsuarioActual();
  }

  void _actualizarSesion(UsuarioAutenticado usuario) {
    setState(() {
      _usuario = usuario;
    });
  }

  Future<void> _cerrarSesion() async {
    await _repositorio.cerrarSesion();
    if (!mounted) {
      return;
    }

    setState(() {
      _usuario = null;
    });
  }

  Widget _pantallaParaUsuario(UsuarioAutenticado usuario) {
    if (usuario.esAdministrador) {
      return PantallaInicioAdmin(
        usuario: usuario,
        onCerrarSesion: _cerrarSesion,
      );
    }

    return ClientShellPage(usuario: usuario, onCerrarSesion: _cerrarSesion);
  }

  @override
  Widget build(BuildContext context) {
    final usuarioActual = _usuario;
    if (usuarioActual != null) {
      return _pantallaParaUsuario(usuarioActual);
    }

    return FutureBuilder<UsuarioAutenticado?>(
      future: _usuarioInicial,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _PantallaCargaSesion();
        }

        final usuario = snapshot.data;
        if (usuario != null) {
          return _pantallaParaUsuario(usuario);
        }

        return PantallaLogin(onSesionIniciada: _actualizarSesion);
      },
    );
  }
}

class _PantallaCargaSesion extends StatelessWidget {
  const _PantallaCargaSesion();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: ClientColors.background,
      body: Center(child: CircularProgressIndicator(color: ClientColors.red)),
    );
  }
}
