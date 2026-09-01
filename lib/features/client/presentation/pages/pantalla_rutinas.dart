import 'package:flutter/material.dart';

import '../../../auth/domain/entities/usuario_autenticado.dart';
import '../../data/catalogo_entrenamiento_mapper.dart';
import '../../data/catalogo_entrenamiento_cliente.dart';
import '../../data/repositorio_ejercicios_cliente_supabase.dart';
import '../../data/repositorio_rutinas_cliente_supabase.dart';
import '../../domain/entities/musculo_entrenamiento.dart';
import '../theme/colores_cliente.dart';
import '../widgets/icono_musculo_cliente.dart';
import '../widgets/mensaje_flotante_cliente.dart';
import '../widgets/titulo_seccion_cliente.dart';

class ClientRoutinesPage extends StatefulWidget {
  const ClientRoutinesPage({
    super.key,
    required this.usuario,
    required this.onRutinaGuardada,
  });

  final UsuarioAutenticado usuario;
  final VoidCallback onRutinaGuardada;

  @override
  State<ClientRoutinesPage> createState() => _ClientRoutinesPageState();
}

class _ClientRoutinesPageState extends State<ClientRoutinesPage> {
  final _repositorioEjercicios = const RepositorioEjerciciosClienteSupabase();
  final _repositorioRutinas = const RepositorioRutinasClienteSupabase();
  int? _selectedMuscleIndex;
  int? _selectedDayIndex;
  final _selectedMusclesByDay = <String, Set<String>>{};
  var _muscles = ClientTrainingCatalog.muscles;
  var _loadingRoutine = true;
  var _savingRoutine = false;
  var _hasChanges = false;

  static const _weekDays = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
  static const _weekDayNames = [
    'Lunes',
    'Martes',
    'Miercoles',
    'Jueves',
    'Viernes',
    'Sabado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _loadExerciseCatalog();
    _loadSavedRoutine();
  }

  Future<void> _loadExerciseCatalog() async {
    try {
      final catalog = await _repositorioEjercicios.cargar(widget.usuario.id);
      final muscles = crearCatalogoEntrenamientoDesdeBase(catalog);
      if (!mounted || muscles.isEmpty) {
        return;
      }

      setState(() {
        _muscles = muscles;
        _selectedMuscleIndex = null;
      });
    } catch (_) {
      // El catalogo local queda como respaldo si Supabase aun no esta migrado.
    }
  }

  Future<void> _loadSavedRoutine() async {
    setState(() => _loadingRoutine = true);
    try {
      final rutina = await _repositorioRutinas.cargar(widget.usuario.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedMusclesByDay
          ..clear()
          ..addAll({
            for (final entry in rutina.musculosPorDia.entries)
              entry.key: {...entry.value},
          });
        _selectedDayIndex = null;
        _selectedMuscleIndex = null;
        _hasChanges = false;
        _loadingRoutine = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _loadingRoutine = false);
      _showMessage(_cleanError(error));
    }
  }

  TrainingMuscle? get _selectedMuscle {
    final index = _selectedMuscleIndex;
    if (index == null) {
      return null;
    }
    return _muscles[index];
  }

  String? get _selectedDay {
    final index = _selectedDayIndex;
    if (index == null) {
      return null;
    }
    return _weekDays[index];
  }

  Set<String> get _selectedDayMuscles {
    final day = _selectedDay;
    if (day == null) {
      return <String>{};
    }
    return _selectedMusclesByDay.putIfAbsent(day, () => <String>{});
  }

  void _selectDay(int index) {
    setState(() {
      _selectedDayIndex = index;
      final musclesForDay = _selectedDayMuscles;
      final selectedMuscle = _selectedMuscle;
      if (musclesForDay.isEmpty) {
        _selectedMuscleIndex = null;
      } else if (selectedMuscle == null ||
          !musclesForDay.contains(selectedMuscle.name)) {
        final nextIndex = _muscles.indexWhere(
          (muscle) => muscle.name == musclesForDay.first,
        );
        _selectedMuscleIndex = nextIndex == -1 ? null : nextIndex;
      }
    });
  }

  void _selectWorkoutMuscle(int index) {
    if (_selectedDayIndex == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(mensajeFlotanteCliente('Selecciona un dia.'));
      return;
    }

    setState(() {
      _selectedMuscleIndex = index;
      _selectedDayMuscles.add(_muscles[index].name);
      _hasChanges = true;
    });
  }

  void _activateMusclePreview(int index) {
    setState(() => _selectedMuscleIndex = index);
  }

  void _removeWorkoutMuscle(String muscleName) {
    setState(() {
      _selectedDayMuscles.remove(muscleName);
      _hasChanges = true;
      if (_selectedDayMuscles.isNotEmpty &&
          (_selectedMuscle == null ||
              !_selectedDayMuscles.contains(_selectedMuscle!.name))) {
        final nextIndex = _muscles.indexWhere(
          (muscle) => muscle.name == _selectedDayMuscles.first,
        );
        _selectedMuscleIndex = nextIndex == -1 ? null : nextIndex;
      } else if (_selectedDayMuscles.isEmpty) {
        _selectedMuscleIndex = null;
      }
    });
  }

  Future<void> _saveRoutine() async {
    setState(() => _savingRoutine = true);
    try {
      await _repositorioRutinas.guardar(
        usuarioId: widget.usuario.id,
        musculosPorDia: _selectedMusclesByDay,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _hasChanges = false;
        _savingRoutine = false;
      });
      widget.onRutinaGuardada();
      _showMessage('Rutina guardada.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _savingRoutine = false);
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
                  const _RoutinesHeader(),
                  const SizedBox(height: 18),
                  _WeeklyPlannerSection(
                    isLoading: _loadingRoutine,
                    isSaving: _savingRoutine,
                    hasChanges: _hasChanges,
                    days: _weekDays,
                    dayNames: _weekDayNames,
                    muscles: _muscles,
                    muscleCountByDay: {
                      for (final day in _weekDays)
                        day: _selectedMusclesByDay[day]?.length ?? 0,
                    },
                    selectedDayIndex: _selectedDayIndex,
                    selectedMuscleIndex: _selectedMuscleIndex,
                    selectedMuscles: _selectedDayMuscles,
                    onSave: _saveRoutine,
                    onSelectDay: _selectDay,
                    onActivateMuscle: _activateMusclePreview,
                    onSelectMuscle: _selectWorkoutMuscle,
                    onRemoveMuscle: _removeWorkoutMuscle,
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

class _RoutinesHeader extends StatelessWidget {
  const _RoutinesHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rutinas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Organiza tus entrenamientos por dia y grupo muscular.',
          style: TextStyle(color: ClientColors.textMuted, height: 1.35),
        ),
      ],
    );
  }
}

class _WeeklyPlannerSection extends StatelessWidget {
  const _WeeklyPlannerSection({
    required this.days,
    required this.dayNames,
    required this.isLoading,
    required this.isSaving,
    required this.hasChanges,
    required this.muscles,
    required this.muscleCountByDay,
    required this.selectedDayIndex,
    required this.selectedMuscleIndex,
    required this.selectedMuscles,
    required this.onSave,
    required this.onSelectDay,
    required this.onActivateMuscle,
    required this.onSelectMuscle,
    required this.onRemoveMuscle,
  });

  final List<String> days;
  final List<String> dayNames;
  final bool isLoading;
  final bool isSaving;
  final bool hasChanges;
  final List<TrainingMuscle> muscles;
  final Map<String, int> muscleCountByDay;
  final int? selectedDayIndex;
  final int? selectedMuscleIndex;
  final Set<String> selectedMuscles;
  final VoidCallback onSave;
  final ValueChanged<int> onSelectDay;
  final ValueChanged<int> onActivateMuscle;
  final ValueChanged<int> onSelectMuscle;
  final ValueChanged<String> onRemoveMuscle;

  @override
  Widget build(BuildContext context) {
    final activeMuscle = selectedMuscleIndex == null
        ? null
        : muscles[selectedMuscleIndex!];
    final showActiveMuscle = activeMuscle != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: ClientSectionTitle(title: 'Plan semanal')),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: ClientColors.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: ClientColors.surfaceSoft,
                disabledForegroundColor: ClientColors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isLoading || isSaving || !hasChanges ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(isSaving ? 'Guardando' : 'Guardar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading) ...[
          const LinearProgressIndicator(
            minHeight: 2,
            color: ClientColors.red,
            backgroundColor: ClientColors.surfaceSoft,
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            for (var index = 0; index < days.length; index++) ...[
              Expanded(
                child: _DayBox(
                  label: days[index],
                  count: muscleCountByDay[days[index]] ?? 0,
                  isSelected: selectedDayIndex == index,
                  onTap: () => onSelectDay(index),
                ),
              ),
              if (index != days.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 22),
        ClientSectionTitle(
          title: selectedDayIndex == null
              ? 'Selecciona un dia'
              : 'Musculos para ${dayNames[selectedDayIndex!]}',
        ),
        const SizedBox(height: 12),
        GridView.builder(
          itemCount: muscles.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final muscle = muscles[index];
            return _RoutineMuscleCard(
              muscle: muscle,
              isSelected: selectedMuscles.contains(muscle.name),
              isActive: selectedMuscleIndex == index,
              onTap: () => onActivateMuscle(index),
              onDoubleTap: selectedMuscles.contains(muscle.name)
                  ? () => onRemoveMuscle(muscle.name)
                  : () => onSelectMuscle(index),
            );
          },
        ),
        const SizedBox(height: 22),
        if (showActiveMuscle)
          _MusclePartsPreview(muscle: activeMuscle)
        else
          const _NoMuscleSelectedCard(),
      ],
    );
  }
}

class _DayBox extends StatelessWidget {
  const _DayBox({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasMuscles = count > 0;
    final backgroundColor = isSelected
        ? ClientColors.red
        : hasMuscles
        ? ClientColors.redSoft
        : ClientColors.surface;
    final borderColor = isSelected
        ? ClientColors.red
        : hasMuscles
        ? ClientColors.redDark
        : ClientColors.border;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$count',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.82)
                      : hasMuscles
                      ? Colors.white.withValues(alpha: 0.72)
                      : ClientColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineMuscleCard extends StatelessWidget {
  const _RoutineMuscleCard({
    required this.muscle,
    required this.isSelected,
    required this.isActive,
    required this.onTap,
    this.onDoubleTap,
  });

  final TrainingMuscle muscle;
  final bool isSelected;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive
          ? ClientColors.red
          : isSelected
          ? ClientColors.redSoft
          : ClientColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? ClientColors.red : ClientColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(clientMuscleIcon(muscle.name), color: Colors.white),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: isActive ? Colors.white : ClientColors.red,
                      size: 18,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                muscle.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${muscle.parts.length} partes',
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
      ),
    );
  }
}

class _MusclePartsPreview extends StatelessWidget {
  const _MusclePartsPreview({required this.muscle});

  final TrainingMuscle muscle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClientSectionTitle(title: 'Partes de ${muscle.name}'),
        const SizedBox(height: 12),
        for (final part in muscle.parts) ...[
          _PartCard(part: part),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _PartCard extends StatelessWidget {
  const _PartCard({required this.part});

  final TrainingMusclePart part;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ClientColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            part.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final exercise in part.exercises)
                _ExerciseChip(label: exercise),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExerciseChip extends StatelessWidget {
  const _ExerciseChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: ClientColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NoMuscleSelectedCard extends StatelessWidget {
  const _NoMuscleSelectedCard();

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
        'Selecciona un musculo para ver sus partes y ejercicios.',
        style: TextStyle(color: ClientColors.textMuted, height: 1.35),
      ),
    );
  }
}
