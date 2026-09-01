import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/servicios/servicio_supabase.dart';
import '../../../client/presentation/theme/colores_cliente.dart';
import '../../data/repositories/repositorio_autenticacion_supabase.dart';
import '../../domain/entities/usuario_autenticado.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key, required this.onSesionIniciada});

  final ValueChanged<UsuarioAutenticado> onSesionIniciada;

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _repositorio = const RepositorioAutenticacionSupabase();

  var _cargando = false;
  var _ocultarContrasena = true;

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    await _cerrarTeclado();

    if (!ServicioSupabase.estaInicializado) {
      _mostrarMensaje(
        'Supabase no esta configurado. Ejecuta la app desde tools/ejecutar_app.ps1.',
      );
      return;
    }

    if (!_formKey.currentState!.validate() || _cargando) {
      return;
    }

    setState(() => _cargando = true);

    try {
      final usuario = await _repositorio.iniciarSesion(
        correo: _correoController.text.trim(),
        contrasena: _contrasenaController.text,
      );

      if (!mounted) {
        return;
      }

      await _cerrarTeclado();
      widget.onSesionIniciada(usuario);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje('Correo o contrasena incorrectos.');
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _cerrarTeclado() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mensaje,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ClientColors.red,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _cerrarTeclado,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(22, 36, 22, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 430,
                      minHeight: constraints.maxHeight - 60,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _LoginBrand(),
                        const SizedBox(height: 32),
                        _LoginFormCard(
                          formKey: _formKey,
                          correoController: _correoController,
                          contrasenaController: _contrasenaController,
                          cargando: _cargando,
                          ocultarContrasena: _ocultarContrasena,
                          onIniciarSesion: _iniciarSesion,
                          onCerrarTeclado: _cerrarTeclado,
                          onToggleContrasena: () {
                            setState(() {
                              _ocultarContrasena = !_ocultarContrasena;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginBrand extends StatelessWidget {
  const _LoginBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ClientColors.red,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: ClientColors.red.withValues(alpha: 0.28),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Text(
            'GP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'GymPro',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({
    required this.formKey,
    required this.correoController,
    required this.contrasenaController,
    required this.cargando,
    required this.ocultarContrasena,
    required this.onIniciarSesion,
    required this.onCerrarTeclado,
    required this.onToggleContrasena,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController correoController;
  final TextEditingController contrasenaController;
  final bool cargando;
  final bool ocultarContrasena;
  final Future<void> Function() onIniciarSesion;
  final Future<void> Function() onCerrarTeclado;
  final VoidCallback onToggleContrasena;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ClientColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!ServicioSupabase.estaInicializado) ...[
              const _SupabaseWarning(),
              const SizedBox(height: 16),
            ],
            const Text(
              'Iniciar sesion',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: correoController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.email],
              style: const TextStyle(color: Colors.white),
              onTapOutside: (_) => onCerrarTeclado(),
              decoration: _inputDecoration(
                label: 'Correo electronico',
                icon: Icons.mail_outline,
              ),
              validator: (value) {
                final correo = value?.trim() ?? '';
                if (correo.isEmpty || !correo.contains('@')) {
                  return 'Ingresa un correo valido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: contrasenaController,
              obscureText: ocultarContrasena,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onIniciarSesion(),
              style: const TextStyle(color: Colors.white),
              onTapOutside: (_) => onCerrarTeclado(),
              decoration: _inputDecoration(
                label: 'Contrasena',
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  tooltip: ocultarContrasena
                      ? 'Mostrar contrasena'
                      : 'Ocultar contrasena',
                  onPressed: onToggleContrasena,
                  icon: Icon(
                    ocultarContrasena
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if ((value ?? '').length < 6) {
                  return 'La contrasena debe tener minimo 6 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: ClientColors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: cargando ? null : onIniciarSesion,
              icon: cargando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login),
              label: Text(cargando ? 'Validando' : 'Ingresar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupabaseWarning extends StatelessWidget {
  const _SupabaseWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ClientColors.redSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ClientColors.red.withValues(alpha: 0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: ClientColors.red, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Configuracion pendiente.',
              style: TextStyle(color: Colors.white, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: ClientColors.textMuted),
    prefixIcon: Icon(icon, color: ClientColors.red),
    suffixIcon: suffixIcon,
    suffixIconColor: ClientColors.textMuted,
    filled: true,
    fillColor: ClientColors.surfaceSoft,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: ClientColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: ClientColors.red, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: ClientColors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: ClientColors.red, width: 1.4),
    ),
  );
}
