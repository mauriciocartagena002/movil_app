import 'package:flutter/material.dart';

import '../../../auth/domain/entities/usuario_autenticado.dart';
import '../../data/repositorio_ejercicios_cliente_supabase.dart';
import '../theme/colores_cliente.dart';
import '../widgets/mensaje_flotante_cliente.dart';
import '../widgets/titulo_seccion_cliente.dart';

class ClientExercisesPage extends StatefulWidget {
  const ClientExercisesPage({super.key, required this.usuario});

  final UsuarioAutenticado usuario;

  @override
  State<ClientExercisesPage> createState() => _ClientExercisesPageState();
}

class _ClientExercisesPageState extends State<ClientExercisesPage> {
  final _repositorio = const RepositorioEjerciciosClienteSupabase();
  var _loading = true;
  var _saving = false;
  var _catalog = const CatalogoEjerciciosCliente(
    musculos: [],
    partes: [],
    ejercicios: [],
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final catalog = await _repositorio.cargar(widget.usuario.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _catalog = catalog;
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

  Future<void> _addExercise() async {
    if (_catalog.musculos.isEmpty || _catalog.partes.isEmpty) {
      _showMessage('Carga el catalogo de ejercicios.');
      return;
    }

    final result = await showModalBottomSheet<_NewExerciseResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ClientColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _ExerciseFormSheet(
          musculos: _catalog.musculos,
          partes: _catalog.partes,
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() => _saving = true);
    try {
      await _repositorio.agregar(
        usuarioId: widget.usuario.id,
        musculoId: result.musculoId,
        parteMusculoId: result.parteMusculoId,
        nombre: result.nombre,
      );
      await _load();
      if (!mounted) {
        return;
      }
      _showMessage('Ejercicio agregado.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteExercise(EjercicioCliente exercise) async {
    setState(() => _saving = true);
    try {
      await _repositorio.eliminar(exercise.id);
      await _load();
      if (!mounted) {
        return;
      }
      _showMessage('Ejercicio eliminado.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _resetExercises() async {
    setState(() => _saving = true);
    try {
      await _repositorio.reiniciar();
      await _load();
      if (!mounted) {
        return;
      }
      _showMessage('Ejercicios reiniciados.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Map<String, List<EjercicioCliente>> _groupExercises() {
    final grouped = <String, List<EjercicioCliente>>{};
    for (final exercise in _catalog.ejercicios) {
      grouped.putIfAbsent(exercise.musculo, () => []).add(exercise);
    }
    return grouped;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(mensajeFlotanteCliente(message));
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupExercises();

    return Scaffold(
      backgroundColor: ClientColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ExercisesHeader(
                    isSaving: _saving,
                    onAdd: _addExercise,
                    onReset: _resetExercises,
                  ),
                  const SizedBox(height: 18),
                  if (_loading)
                    const Center(
                      child: CircularProgressIndicator(color: ClientColors.red),
                    )
                  else if (_catalog.ejercicios.isEmpty)
                    const _EmptyExercises()
                  else
                    for (final entry in grouped.entries) ...[
                      ClientSectionTitle(title: entry.key),
                      const SizedBox(height: 10),
                      for (final exercise in entry.value) ...[
                        _ExerciseTile(
                          exercise: exercise,
                          onDelete: _saving
                              ? null
                              : () => _deleteExercise(exercise),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 14),
                    ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExercisesHeader extends StatelessWidget {
  const _ExercisesHeader({
    required this.isSaving,
    required this.onAdd,
    required this.onReset,
  });

  final bool isSaving;
  final VoidCallback onAdd;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ejercicios',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: ClientColors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isSaving ? null : onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: ClientColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isSaving ? null : onReset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reiniciar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise, required this.onDelete});

  final EjercicioCliente exercise;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientColors.surface,
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
            child: const Icon(Icons.fitness_center, color: ClientColors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exercise.parte,
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
          IconButton(
            tooltip: 'Eliminar',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: ClientColors.red),
          ),
        ],
      ),
    );
  }
}

class _ExerciseFormSheet extends StatefulWidget {
  const _ExerciseFormSheet({required this.musculos, required this.partes});

  final List<OpcionMusculoCliente> musculos;
  final List<OpcionParteMusculoCliente> partes;

  @override
  State<_ExerciseFormSheet> createState() => _ExerciseFormSheetState();
}

class _ExerciseFormSheetState extends State<_ExerciseFormSheet> {
  final _nameController = TextEditingController();
  late String _musculoId = widget.musculos.first.id;

  List<OpcionParteMusculoCliente> get _parts {
    return widget.partes
        .where((part) => part.musculoId == _musculoId)
        .toList(growable: false);
  }

  late String _parteId = _parts.first.id;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final nombre = _nameController.text.trim();
    if (nombre.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _NewExerciseResult(
        musculoId: _musculoId,
        parteMusculoId: _parteId,
        nombre: nombre,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final parts = _parts;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Agregar ejercicio',
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
            DropdownButtonFormField<String>(
              initialValue: _musculoId,
              dropdownColor: ClientColors.surface,
              decoration: _exerciseInputDecoration(
                label: 'Musculo',
                icon: Icons.accessibility_new,
              ),
              items: [
                for (final muscle in widget.musculos)
                  DropdownMenuItem(
                    value: muscle.id,
                    child: Text(muscle.nombre),
                  ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _musculoId = value;
                  _parteId = _parts.first.id;
                });
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: ValueKey(_musculoId),
              initialValue: _parteId,
              dropdownColor: ClientColors.surface,
              decoration: _exerciseInputDecoration(
                label: 'Parte',
                icon: Icons.adjust,
              ),
              items: [
                for (final part in parts)
                  DropdownMenuItem(value: part.id, child: Text(part.nombre)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _parteId = value);
                }
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _exerciseInputDecoration(
                label: 'Nombre del ejercicio',
                icon: Icons.edit_outlined,
              ),
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
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewExerciseResult {
  const _NewExerciseResult({
    required this.musculoId,
    required this.parteMusculoId,
    required this.nombre,
  });

  final String musculoId;
  final String parteMusculoId;
  final String nombre;
}

class _EmptyExercises extends StatelessWidget {
  const _EmptyExercises();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ClientColors.border),
      ),
      child: const Text(
        'No hay ejercicios disponibles.',
        style: TextStyle(color: ClientColors.textMuted),
      ),
    );
  }
}

InputDecoration _exerciseInputDecoration({
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
