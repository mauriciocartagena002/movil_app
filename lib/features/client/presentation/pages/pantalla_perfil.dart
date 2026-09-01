import 'package:flutter/material.dart';

import '../../../auth/domain/entities/usuario_autenticado.dart';
import '../../data/repositorio_perfil_cliente_supabase.dart';
import '../theme/colores_cliente.dart';
import '../widgets/mensaje_flotante_cliente.dart';
import '../widgets/tarjeta_estadistica_cliente.dart';

class ClientProfilePage extends StatefulWidget {
  const ClientProfilePage({
    super.key,
    required this.usuario,
    this.onCerrarSesion,
  });

  final UsuarioAutenticado usuario;
  final Future<void> Function()? onCerrarSesion;

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  final _repositorio = const RepositorioPerfilClienteSupabase();
  late var _name = _nombreInicial;
  late var _email = widget.usuario.correo;
  var _ci = '';
  var _weight = '';
  var _height = '';
  var _loading = true;

  String get _nombreInicial {
    final nombre = widget.usuario.nombreCompleto.trim();
    return nombre.isEmpty ? 'Usuario GymPro' : nombre;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final perfil = await _repositorio.cargarPerfil(widget.usuario);
      if (!mounted) {
        return;
      }

      setState(() {
        _name = perfil.nombreCompleto;
        _email = perfil.correo;
        _ci = perfil.ci;
        _weight = _formatNumber(perfil.pesoKg);
        _height = _formatNumber(perfil.alturaCm);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _loading = false);
      _showMessage(_cleanError(error));
    }
  }

  Future<void> _openEditProfile() async {
    final result = await showModalBottomSheet<_ProfileEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ClientColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _EditProfileSheet(name: _name, weight: _weight, height: _height);
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      _name = result.name;
      _weight = result.weight;
      _height = result.height;
    });

    try {
      await _repositorio.guardarPerfil(
        usuarioId: widget.usuario.id,
        nombreCompleto: result.name,
        pesoKg: _parseNumber(result.weight),
        alturaCm: _parseNumber(result.height),
      );
      if (!mounted) {
        return;
      }
      _showMessage('Perfil actualizado.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_cleanError(error));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(mensajeFlotanteCliente(message));
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  num? _parseNumber(String value) {
    final clean = value.trim().replaceAll(',', '.');
    if (clean.isEmpty) {
      return null;
    }
    return num.tryParse(clean);
  }

  String _formatNumber(num? value) {
    if (value == null) {
      return '';
    }
    return value % 1 == 0 ? value.toInt().toString() : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ProfileHeader(onEdit: _openEditProfile),
                  const SizedBox(height: 18),
                  if (_loading) ...[
                    const Center(
                      child: CircularProgressIndicator(color: ClientColors.red),
                    ),
                    const SizedBox(height: 18),
                  ],
                  _UserCard(name: _name, email: _email, ci: _ci),
                  const SizedBox(height: 18),
                  _ProfileStats(weight: _weight, height: _height),
                  const SizedBox(height: 24),
                  _ProfileOptionTile(
                    icon: Icons.logout,
                    title: 'Cerrar sesion',
                    trailingIcon: Icons.chevron_right,
                    onTap: () => widget.onCerrarSesion?.call(),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Perfil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton.filled(
          tooltip: 'Editar perfil',
          style: IconButton.styleFrom(
            backgroundColor: ClientColors.surface,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.name, required this.email, required this.ci});

  final String name;
  final String email;
  final String ci;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ClientColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ClientColors.red,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: ClientColors.red.withValues(alpha: 0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Text(
                  _iniciales(name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ClientColors.textMuted,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ci.isEmpty ? 'CI: -' : 'CI: $ci',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ClientColors.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _iniciales(String nombre) {
  final partes = nombre.trim().split(RegExp(r'\s+'));
  if (partes.isEmpty || partes.first.isEmpty) {
    return 'US';
  }

  final primera = partes.first[0];
  final segunda = partes.length > 1 && partes[1].isNotEmpty ? partes[1][0] : '';
  return '$primera$segunda'.toUpperCase();
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.weight, required this.height});

  final String weight;
  final String height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClientStatCard(
            value: weight.isEmpty ? '-' : weight,
            label: 'Peso',
            icon: Icons.monitor_weight_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClientStatCard(
            value: height.isEmpty ? '-' : height,
            label: 'Altura',
            icon: Icons.height,
            color: ClientColors.warning,
          ),
        ),
      ],
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  const _ProfileOptionTile({
    required this.icon,
    required this.title,
    required this.trailingIcon,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final IconData trailingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ClientColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ClientColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ClientColors.redSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: ClientColors.red, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(trailingIcon, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.name,
    required this.weight,
    required this.height,
  });

  final String name;
  final String weight;
  final String height;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _weightController = TextEditingController(text: widget.weight);
    _heightController = TextEditingController(text: widget.height);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final weight = _weightController.text.trim();
    final height = _heightController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          mensajeFlotanteCliente('Completa los datos principales.'),
        );
      return;
    }

    Navigator.of(context)
        .pop(_ProfileEditResult(name: name, weight: weight, height: height));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Editar perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _profileInputDecoration(
                label: 'Nombre',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _profileInputDecoration(
                      label: 'Peso',
                      icon: Icons.monitor_weight_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _profileInputDecoration(
                      label: 'Altura',
                      icon: Icons.height,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: ClientColors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileEditResult {
  const _ProfileEditResult({
    required this.name,
    required this.weight,
    required this.height,
  });

  final String name;
  final String weight;
  final String height;
}

InputDecoration _profileInputDecoration({
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
  );
}
