import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_admin_supabase.dart';
import '../../../auth/domain/entities/usuario_autenticado.dart';
import '../../../client/presentation/theme/colores_cliente.dart';

class PantallaInicioAdmin extends StatefulWidget {
  const PantallaInicioAdmin({
    super.key,
    required this.usuario,
    required this.onCerrarSesion,
  });

  final UsuarioAutenticado usuario;
  final Future<void> Function() onCerrarSesion;

  @override
  State<PantallaInicioAdmin> createState() => _PantallaInicioAdminState();
}

class _PantallaInicioAdminState extends State<PantallaInicioAdmin> {
  final _repositorio = const RepositorioAdminSupabase();
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _ciController = TextEditingController();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _inicioController = TextEditingController();
  final _finController = TextEditingController();

  var _selectedIndex = 0;
  var _cargandoClientes = true;
  var _registrando = false;
  DateTime? _inicioMensualidad;
  DateTime? _finMensualidad;

  List<ClienteAdmin> _usuarios = [];

  static const _tabs = [
    _AdminTab('Registro', Icons.person_add_alt_outlined),
    _AdminTab('Usuarios', Icons.people_outline),
    _AdminTab('Perfil', Icons.admin_panel_settings_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ciController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    _inicioController.dispose();
    _finController.dispose();
    super.dispose();
  }

  Future<void> _cargarClientes({bool mostrarCarga = true}) async {
    if (mostrarCarga) {
      setState(() => _cargandoClientes = true);
    }

    try {
      final clientes = await _repositorio.listarClientes();
      if (!mounted) {
        return;
      }

      setState(() {
        _usuarios = clientes;
        _cargandoClientes = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _cargandoClientes = false);
      _mostrarMensaje(_limpiarError(error));
    }
  }

  Future<void> _seleccionarInicio() async {
    final fecha = await _mostrarSelectorFecha(
      initialDate: _inicioMensualidad ?? DateTime.now(),
    );
    if (fecha == null) {
      return;
    }

    final finAutomatico = _calcularFinMensualidad(fecha);
    setState(() {
      _inicioMensualidad = fecha;
      _finMensualidad = finAutomatico;
      _inicioController.text = _formatearFecha(fecha);
      _finController.text = _formatearFecha(finAutomatico);
    });
  }

  Future<void> _seleccionarFin() async {
    final fecha = await _mostrarSelectorFecha(
      initialDate:
          _finMensualidad ??
          _calcularFinMensualidad(_inicioMensualidad ?? DateTime.now()),
    );
    if (fecha == null) {
      return;
    }

    setState(() {
      _finMensualidad = fecha;
      _finController.text = _formatearFecha(fecha);
    });
  }

  Future<DateTime?> _mostrarSelectorFecha({required DateTime initialDate}) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
      builder: (context, child) {
        final baseTheme = Theme.of(context);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 330, maxHeight: 500),
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(0.9)),
              child: Theme(
                data: baseTheme.copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: ClientColors.red,
                    onPrimary: Colors.white,
                    surface: ClientColors.surface,
                    onSurface: Colors.white,
                  ),
                  datePickerTheme: DatePickerThemeData(
                    backgroundColor: ClientColors.surface,
                    headerBackgroundColor: ClientColors.red,
                    headerForegroundColor: Colors.white,
                    dividerColor: ClientColors.border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: ClientColors.border),
                    ),
                    dayStyle: const TextStyle(fontSize: 12),
                    weekdayStyle: const TextStyle(
                      color: ClientColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                    yearStyle: const TextStyle(fontSize: 12),
                    todayBorder: const BorderSide(color: ClientColors.red),
                    todayForegroundColor: const WidgetStatePropertyAll(
                      Colors.white,
                    ),
                    dayForegroundColor: WidgetStateProperty.resolveWith((
                      states,
                    ) {
                      if (states.contains(WidgetState.disabled)) {
                        return ClientColors.textMuted.withValues(alpha: 0.35);
                      }
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return Colors.white;
                    }),
                    dayBackgroundColor: WidgetStateProperty.resolveWith((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return ClientColors.red;
                      }
                      return Colors.transparent;
                    }),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: child!,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final inicio = _inicioMensualidad;
    final fin = _finMensualidad;
    if (inicio == null || fin == null) {
      _mostrarMensaje('Selecciona las fechas de mensualidad.');
      return;
    }

    setState(() => _registrando = true);

    try {
      final cliente = await _repositorio.registrarCliente(
        RegistroClienteAdmin(
          nombreCompleto: _nombreController.text.trim(),
          ci: _ciController.text.trim(),
          correo: _correoController.text.trim(),
          contrasena: _contrasenaController.text,
          inicioMensualidad: inicio,
          finMensualidad: fin,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _usuarios = [
          cliente,
          ..._usuarios.where((item) => item.perfilId != cliente.perfilId),
        ];
        _nombreController.clear();
        _ciController.clear();
        _correoController.clear();
        _contrasenaController.clear();
        _inicioController.clear();
        _finController.clear();
        _inicioMensualidad = null;
        _finMensualidad = null;
        _selectedIndex = 1;
        _registrando = false;
      });

      _mostrarMensaje('Usuario registrado.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _registrando = false);
      _mostrarMensaje(_limpiarError(error));
    }
  }

  Future<void> _editarEstado(ClienteAdmin usuario, bool activo) async {
    try {
      await _repositorio.editarEstado(usuario.perfilId, activo);
      if (!mounted) {
        return;
      }

      setState(() {
        _usuarios = [
          for (final item in _usuarios)
            item.perfilId == usuario.perfilId
                ? item.copyWith(estadoManual: activo)
                : item,
        ];
      });

      _mostrarMensaje(activo ? 'Usuario activo.' : 'Usuario inactivo.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(_limpiarError(error));
    }
  }

  Future<void> _limpiarEstadoManual(ClienteAdmin usuario) async {
    try {
      await _repositorio.restaurarEstadoAutomatico(usuario.perfilId);
      if (!mounted) {
        return;
      }

      setState(() {
        _usuarios = [
          for (final item in _usuarios)
            item.perfilId == usuario.perfilId
                ? item.copyWith(limpiarEstadoManual: true)
                : item,
        ];
      });

      _mostrarMensaje('Estado actualizado.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(_limpiarError(error));
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            mensaje,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ClientColors.surfaceSoft,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
  }

  String _limpiarError(Object error) {
    final mensaje = error.toString();
    return mensaje.replaceFirst('Exception: ', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final paginas = [
      _RegistroPage(
        formKey: _formKey,
        nombreController: _nombreController,
        ciController: _ciController,
        correoController: _correoController,
        contrasenaController: _contrasenaController,
        inicioController: _inicioController,
        finController: _finController,
        onSeleccionarInicio: _seleccionarInicio,
        onSeleccionarFin: _seleccionarFin,
        onRegistrar: _registrarUsuario,
        registrando: _registrando,
      ),
      _UsuariosPage(
        usuarios: _usuarios,
        cargando: _cargandoClientes,
        onRecargar: _cargarClientes,
        onEditarEstado: _editarEstado,
        onRestaurarAutomatico: _limpiarEstadoManual,
      ),
      _PerfilAdminPage(
        usuario: widget.usuario,
        onCerrarSesion: widget.onCerrarSesion,
      ),
    ];

    return Scaffold(
      backgroundColor: ClientColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _AdminHeader(
              selectedIndex: _selectedIndex,
              onSelect: (index) => setState(() => _selectedIndex = index),
            ),
            Expanded(
              child: IndexedStack(index: _selectedIndex, children: paginas),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistroPage extends StatelessWidget {
  const _RegistroPage({
    required this.formKey,
    required this.nombreController,
    required this.ciController,
    required this.correoController,
    required this.contrasenaController,
    required this.inicioController,
    required this.finController,
    required this.onSeleccionarInicio,
    required this.onSeleccionarFin,
    required this.onRegistrar,
    required this.registrando,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nombreController;
  final TextEditingController ciController;
  final TextEditingController correoController;
  final TextEditingController contrasenaController;
  final TextEditingController inicioController;
  final TextEditingController finController;
  final VoidCallback onSeleccionarInicio;
  final VoidCallback onSeleccionarFin;
  final VoidCallback onRegistrar;
  final bool registrando;

  @override
  Widget build(BuildContext context) {
    return _AdminScrollPage(
      children: [
        const _PageIntro(
          icon: Icons.person_add_alt_outlined,
          title: 'Registro',
        ),
        const SizedBox(height: 18),
        _AdminPanel(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AdminTextField(
                  controller: nombreController,
                  label: 'Nombre completo',
                  icon: Icons.badge_outlined,
                  validator: (value) {
                    if ((value ?? '').trim().length < 4) {
                      return 'Ingresa el nombre completo.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _AdminTextField(
                  controller: ciController,
                  label: 'CI',
                  icon: Icons.credit_card_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Ingresa el CI.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _AdminTextField(
                  controller: correoController,
                  label: 'Correo electronico',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final correo = value?.trim() ?? '';
                    if (correo.isEmpty || !correo.contains('@')) {
                      return 'Ingresa un correo valido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _AdminTextField(
                  controller: contrasenaController,
                  label: 'Contrasena',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (value) {
                    if ((value ?? '').length < 6) {
                      return 'Minimo 6 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _DateField(
                  controller: inicioController,
                  label: 'Inicio de mensualidad',
                  onTap: onSeleccionarInicio,
                ),
                const SizedBox(height: 14),
                _DateField(
                  controller: finController,
                  label: 'Fin de mensualidad',
                  onTap: onSeleccionarFin,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: _filledButtonStyle(),
                  onPressed: registrando ? null : onRegistrar,
                  icon: registrando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    registrando ? 'Registrando' : 'Registrar usuario',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UsuariosPage extends StatelessWidget {
  const _UsuariosPage({
    required this.usuarios,
    required this.cargando,
    required this.onRecargar,
    required this.onEditarEstado,
    required this.onRestaurarAutomatico,
  });

  final List<ClienteAdmin> usuarios;
  final bool cargando;
  final Future<void> Function({bool mostrarCarga}) onRecargar;
  final void Function(ClienteAdmin usuario, bool activo) onEditarEstado;
  final ValueChanged<ClienteAdmin> onRestaurarAutomatico;

  @override
  Widget build(BuildContext context) {
    final activos = usuarios.where((usuario) => usuario.estaActivo).length;
    final inactivos = usuarios.length - activos;

    return _AdminScrollPage(
      children: [
        const _PageIntro(icon: Icons.people_outline, title: 'Usuarios'),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _MiniMetric(value: '${usuarios.length}', label: 'Total'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniMetric(value: '$activos', label: 'Activos'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniMetric(value: '$inactivos', label: 'Inactivos'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (cargando)
          const _AdminPanel(
            child: Center(
              child: CircularProgressIndicator(color: ClientColors.red),
            ),
          )
        else if (usuarios.isEmpty)
          const _InfoPanel(
            title: 'Sin usuarios',
            text: 'Sin registros disponibles.',
            icon: Icons.person_search_outlined,
          )
        else ...[
          Align(
            alignment: Alignment.centerRight,
            child: IconButton.filled(
              tooltip: 'Actualizar',
              style: IconButton.styleFrom(
                backgroundColor: ClientColors.surfaceSoft,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => onRecargar(mostrarCarga: false),
              icon: const Icon(Icons.refresh),
            ),
          ),
          const SizedBox(height: 12),
          for (final usuario in usuarios) ...[
            _UsuarioCard(
              usuario: usuario,
              onEditarEstado: (activo) => onEditarEstado(usuario, activo),
              onRestaurarAutomatico: () => onRestaurarAutomatico(usuario),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _PerfilAdminPage extends StatelessWidget {
  const _PerfilAdminPage({required this.usuario, required this.onCerrarSesion});

  final UsuarioAutenticado usuario;
  final Future<void> Function() onCerrarSesion;

  @override
  Widget build(BuildContext context) {
    return _AdminScrollPage(
      children: [
        const _PageIntro(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Perfil',
        ),
        const SizedBox(height: 18),
        _AdminPanel(
          child: Column(
            children: [
              Container(
                width: 82,
                height: 82,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ClientColors.red,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: ClientColors.red.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                usuario.nombreCompleto.isEmpty
                    ? 'Administrador GymPro'
                    : usuario.nombreCompleto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                usuario.correo,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ClientColors.textMuted),
              ),
              const SizedBox(height: 20),
              const _ProfileInfoTile(
                icon: Icons.badge_outlined,
                label: 'Nombre completo',
                value: 'Administrador GymPro',
              ),
              const SizedBox(height: 10),
              const _ProfileInfoTile(
                icon: Icons.credit_card_outlined,
                label: 'CI',
                value: 'No registrado',
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: _outlinedButtonStyle(),
                  onPressed: onCerrarSesion,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesion'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: ClientColors.background,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Panel administrador',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (
                var index = 0;
                index < _PantallaInicioAdminState._tabs.length;
                index++
              ) ...[
                Expanded(
                  child: _AdminTabButton(
                    tab: _PantallaInicioAdminState._tabs[index],
                    selected: selectedIndex == index,
                    onTap: () => onSelect(index),
                  ),
                ),
                if (index != _PantallaInicioAdminState._tabs.length - 1)
                  const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminTabButton extends StatelessWidget {
  const _AdminTabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _AdminTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ClientColors.red : ClientColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? ClientColors.red : ClientColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tab.icon, color: Colors.white, size: 19),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminScrollPage extends StatelessWidget {
  const _AdminScrollPage({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ClientColors.redSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: ClientColors.red),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminPanel extends StatelessWidget {
  const _AdminPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ClientColors.border),
      ),
      child: child,
    );
  }
}

class _AdminTextField extends StatelessWidget {
  const _AdminTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: _fieldDecoration(label: label, icon: icon),
      validator: validator,
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.controller,
    required this.label,
    required this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: const TextStyle(color: Colors.white),
      decoration: _fieldDecoration(
        label: label,
        icon: Icons.calendar_month_outlined,
      ),
      validator: (value) {
        if ((value ?? '').isEmpty) {
          return 'Selecciona una fecha.';
        }
        return null;
      },
    );
  }
}

class _UsuarioCard extends StatelessWidget {
  const _UsuarioCard({
    required this.usuario,
    required this.onEditarEstado,
    required this.onRestaurarAutomatico,
  });

  final ClienteAdmin usuario;
  final ValueChanged<bool> onEditarEstado;
  final VoidCallback onRestaurarAutomatico;

  @override
  Widget build(BuildContext context) {
    final activo = usuario.estaActivo;
    final vencida = usuario.mensualidadVencida;
    final color = activo ? ClientColors.success : ClientColors.red;

    return _AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _iniciales(usuario.nombreCompleto),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.nombreCompleto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CI ${usuario.ci}',
                      style: const TextStyle(color: ClientColors.textMuted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      usuario.correo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ClientColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _EstadoBadge(activo: activo),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DateInfo(
                  label: 'Inicio',
                  value: _formatearFecha(usuario.inicioMensualidad),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateInfo(
                  label: 'Fin',
                  value: _formatearFecha(usuario.finMensualidad),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                vencida ? Icons.warning_amber : Icons.check_circle_outline,
                color: vencida ? ClientColors.warning : ClientColors.success,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  usuario.estadoManual == null
                      ? 'Estado por mensualidad'
                      : 'Estado manual',
                  style: const TextStyle(
                    color: ClientColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.check_circle_outline),
                      label: Text('Activo'),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.block_outlined),
                      label: Text('Inactivo'),
                    ),
                  ],
                  selected: {activo},
                  onSelectionChanged: (value) => onEditarEstado(value.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return ClientColors.red;
                      }
                      return ClientColors.surfaceSoft;
                    }),
                    foregroundColor: const WidgetStatePropertyAll(Colors.white),
                    side: const WidgetStatePropertyAll(
                      BorderSide(color: ClientColors.border),
                    ),
                  ),
                ),
              ),
              if (usuario.estadoManual != null) ...[
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Restaurar estado',
                  style: IconButton.styleFrom(
                    backgroundColor: ClientColors.surfaceSoft,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onRestaurarAutomatico,
                  icon: const Icon(Icons.restart_alt),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) {
    final color = activo ? ClientColors.success : ClientColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DateInfo extends StatelessWidget {
  const _DateInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: ClientColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: ClientColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.title,
    required this.text,
    required this.icon,
  });

  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _AdminPanel(
      child: Row(
        children: [
          Icon(icon, color: ClientColors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: ClientColors.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: ClientColors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: ClientColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  required String label,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: ClientColors.textMuted),
    prefixIcon: Icon(icon, color: ClientColors.red),
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

ButtonStyle _filledButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: ClientColors.red,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 15),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}

ButtonStyle _outlinedButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 15),
    side: const BorderSide(color: ClientColors.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}

DateTime _calcularFinMensualidad(DateTime inicio) {
  return DateTime(
    inicio.year,
    inicio.month + 1,
    inicio.day,
  ).subtract(const Duration(days: 1));
}

String _formatearFecha(DateTime fecha) {
  final day = fecha.day.toString().padLeft(2, '0');
  final month = fecha.month.toString().padLeft(2, '0');
  return '$day/$month/${fecha.year}';
}

String _iniciales(String nombre) {
  final parts = nombre.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) {
    return 'US';
  }
  final first = parts.first.isEmpty ? '' : parts.first[0];
  final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
  return '$first$second'.toUpperCase();
}

class _AdminTab {
  const _AdminTab(this.label, this.icon);

  final String label;
  final IconData icon;
}
