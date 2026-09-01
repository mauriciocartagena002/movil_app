import 'package:flutter/material.dart';

import '../../../auth/domain/entities/usuario_autenticado.dart';
import '../../data/catalogo_entrenamiento_mapper.dart';
import '../../data/catalogo_entrenamiento_cliente.dart';
import '../../data/repositorio_ejercicios_cliente_supabase.dart';
import '../../data/repositorio_seguimiento_cliente_supabase.dart';
import '../../domain/entities/musculo_entrenamiento.dart';
import '../theme/colores_cliente.dart';
import '../widgets/icono_musculo_cliente.dart';
import '../widgets/mensaje_flotante_cliente.dart';
import '../widgets/titulo_seccion_cliente.dart';

class ClientMuscleTrackingPage extends StatefulWidget {
  const ClientMuscleTrackingPage({super.key, required this.usuario});

  final UsuarioAutenticado usuario;

  @override
  State<ClientMuscleTrackingPage> createState() =>
      _ClientMuscleTrackingPageState();
}

class _ClientMuscleTrackingPageState extends State<ClientMuscleTrackingPage> {
  final _repositorio = const RepositorioSeguimientoClienteSupabase();
  final _repositorioEjercicios = const RepositorioEjerciciosClienteSupabase();
  final _entriesByDay = <int, List<TrackingEntry>>{};
  var _muscles = ClientTrainingCatalog.muscles;

  late DateTime _visibleMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  late int _selectedDay = DateTime.now().day.clamp(1, _daysInMonth);
  int? _selectedEntryIndex;
  var _loading = true;

  int get _daysInMonth {
    return DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
  }

  List<TrackingEntry> get _selectedEntries {
    return _entriesByDay[_selectedDay] ?? const [];
  }

  TrackingEntry? get _selectedEntry {
    final index = _selectedEntryIndex;
    if (index == null || index >= _selectedEntries.length) {
      return null;
    }
    return _selectedEntries[index];
  }

  @override
  void initState() {
    super.initState();
    _loadExerciseCatalog();
    _loadMonth();
  }

  Future<void> _loadExerciseCatalog() async {
    try {
      final catalog = await _repositorioEjercicios.cargar(widget.usuario.id);
      final muscles = crearCatalogoEntrenamientoDesdeBase(catalog);
      if (!mounted || muscles.isEmpty) {
        return;
      }

      setState(() => _muscles = muscles);
    } catch (_) {
      // El catalogo local queda como respaldo si Supabase aun no esta migrado.
    }
  }

  Future<void> _loadMonth() async {
    setState(() => _loading = true);
    try {
      final registros = await _repositorio.listarMes(
        usuarioId: widget.usuario.id,
        mes: _visibleMonth,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _entriesByDay
          ..clear()
          ..addAll(_groupByDay(registros));
        _selectedDay = _selectedDay.clamp(1, _daysInMonth);
        _selectedEntryIndex = null;
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

  Map<int, List<TrackingEntry>> _groupByDay(
    List<RegistroSeguimientoCliente> registros,
  ) {
    final grouped = <int, List<TrackingEntry>>{};
    for (final registro in registros) {
      grouped
          .putIfAbsent(registro.fecha.day, () => [])
          .add(
            TrackingEntry(
              id: registro.id,
              trackingId: registro.seguimientoId,
              muscle: registro.musculo,
              part: registro.parte,
              exercise: registro.ejercicio,
              sets: registro.series,
              reps: registro.repeticiones,
            ),
          );
    }
    return grouped;
  }

  void _selectDay(int day) {
    setState(() {
      _selectedDay = day;
      _selectedEntryIndex = null;
    });
  }

  Future<void> _changeMonth(int delta) async {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      _selectedDay = 1;
      _selectedEntryIndex = null;
    });
    await _loadMonth();
  }

  Future<void> _openEntryForm({TrackingEntry? entry, int? entryIndex}) async {
    final savedEntry = await showModalBottomSheet<TrackingEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ClientColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _TrackingEntrySheet(
          day: _selectedDay,
          initialEntry: entry,
          muscles: _muscles,
        );
      },
    );

    if (savedEntry == null) {
      return;
    }

    try {
      final saved = await _repositorio.guardar(
        usuarioId: widget.usuario.id,
        registro: RegistroSeguimientoCliente(
          id: entry?.id,
          seguimientoId: entry?.trackingId,
          fecha: DateTime(
            _visibleMonth.year,
            _visibleMonth.month,
            _selectedDay,
          ),
          musculo: savedEntry.muscle,
          parte: savedEntry.part,
          ejercicio: savedEntry.exercise,
          series: savedEntry.sets,
          repeticiones: savedEntry.reps,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        final entries = _entriesByDay.putIfAbsent(_selectedDay, () => []);
        final storedEntry = TrackingEntry(
          id: saved.id,
          trackingId: saved.seguimientoId,
          muscle: saved.musculo,
          part: saved.parte,
          exercise: saved.ejercicio,
          sets: saved.series,
          reps: saved.repeticiones,
        );
        if (entryIndex == null) {
          entries.add(storedEntry);
          _selectedEntryIndex = entries.length - 1;
        } else {
          entries[entryIndex] = storedEntry;
          _selectedEntryIndex = entryIndex;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_cleanError(error));
    }
  }

  Future<void> _deleteSelectedEntry() async {
    final index = _selectedEntryIndex;
    if (index == null) {
      return;
    }

    final entry = _selectedEntry;
    if (entry == null) {
      return;
    }

    try {
      await _repositorio.eliminar(
        RegistroSeguimientoCliente(
          id: entry.id,
          seguimientoId: entry.trackingId,
          fecha: DateTime(
            _visibleMonth.year,
            _visibleMonth.month,
            _selectedDay,
          ),
          musculo: entry.muscle,
          parte: entry.part,
          ejercicio: entry.exercise,
          series: entry.sets,
          repeticiones: entry.reps,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        final entries = _entriesByDay[_selectedDay];
        if (entries == null || index >= entries.length) {
          _selectedEntryIndex = null;
          return;
        }
        entries.removeAt(index);
        if (entries.isEmpty) {
          _entriesByDay.remove(_selectedDay);
          _selectedEntryIndex = null;
        } else {
          _selectedEntryIndex = index.clamp(0, entries.length - 1);
        }
      });
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
                  _TrackingHeader(month: _monthTitle(_visibleMonth)),
                  const SizedBox(height: 18),
                  _CalendarCard(
                    visibleMonth: _visibleMonth,
                    daysInMonth: _daysInMonth,
                    selectedDay: _selectedDay,
                    entriesByDay: _entriesByDay,
                    onSelectDay: _selectDay,
                    onPreviousMonth: () => _changeMonth(-1),
                    onNextMonth: () => _changeMonth(1),
                  ),
                  const SizedBox(height: 24),
                  if (_loading) ...[
                    const Center(
                      child: CircularProgressIndicator(color: ClientColors.red),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _SelectedDayHeader(
                    day: _selectedDay,
                    selectedEntry: _selectedEntry,
                    onAdd: () => _openEntryForm(),
                    onEdit: _selectedEntryIndex == null
                        ? null
                        : () => _openEntryForm(
                            entry: _selectedEntry,
                            entryIndex: _selectedEntryIndex,
                          ),
                    onDelete: _selectedEntryIndex == null
                        ? null
                        : _deleteSelectedEntry,
                  ),
                  const SizedBox(height: 12),
                  if (_selectedEntries.isEmpty)
                    const _EmptyTrackingState()
                  else
                    for (
                      var index = 0;
                      index < _selectedEntries.length;
                      index++
                    ) ...[
                      _TrackingEntryTile(
                        entry: _selectedEntries[index],
                        isSelected: _selectedEntryIndex == index,
                        onTap: () {
                          setState(() {
                            _selectedEntryIndex = _selectedEntryIndex == index
                                ? null
                                : index;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
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

class TrackingEntry {
  const TrackingEntry({
    this.id,
    this.trackingId,
    required this.muscle,
    required this.part,
    required this.exercise,
    required this.sets,
    required this.reps,
  });

  final String? id;
  final String? trackingId;
  final String muscle;
  final String part;
  final String exercise;
  final int sets;
  final int reps;
}

class _TrackingHeader extends StatelessWidget {
  const _TrackingHeader({required this.month});

  final String month;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seguimiento muscular',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Registra musculo, zona, ejercicio, series y repeticiones en $month.',
          style: const TextStyle(color: ClientColors.textMuted, height: 1.35),
        ),
      ],
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.visibleMonth,
    required this.daysInMonth,
    required this.selectedDay,
    required this.entriesByDay,
    required this.onSelectDay,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime visibleMonth;
  final int daysInMonth;
  final int selectedDay;
  final Map<int, List<TrackingEntry>> entriesByDay;
  final ValueChanged<int> onSelectDay;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              const Icon(
                Icons.calendar_month_outlined,
                color: ClientColors.red,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Calendario de entrenamiento',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Mes anterior',
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left, color: Colors.white),
              ),
              IconButton(
                tooltip: 'Mes siguiente',
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              _WeekdayLabel('L'),
              _WeekdayLabel('M'),
              _WeekdayLabel('X'),
              _WeekdayLabel('J'),
              _WeekdayLabel('V'),
              _WeekdayLabel('S'),
              _WeekdayLabel('D'),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            itemCount: _leadingEmptyDays(visibleMonth) + daysInMonth,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) {
              final leading = _leadingEmptyDays(visibleMonth);
              if (index < leading) {
                return const SizedBox.shrink();
              }

              final day = index - leading + 1;
              return _CalendarDayCell(
                day: day,
                entryCount: entriesByDay[day]?.length ?? 0,
                isSelected: selectedDay == day,
                onTap: () => onSelectDay(day),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ClientColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

int _leadingEmptyDays(DateTime month) {
  return DateTime(month.year, month.month).weekday - 1;
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.entryCount,
    required this.isSelected,
    required this.onTap,
  });

  final int day;
  final int entryCount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? ClientColors.red : ClientColors.surfaceSoft,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? ClientColors.red : ClientColors.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: entryCount > 0
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedDayHeader extends StatelessWidget {
  const _SelectedDayHeader({
    required this.day,
    required this.selectedEntry,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final int day;
  final TrackingEntry? selectedEntry;
  final VoidCallback onAdd;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClientSectionTitle(title: 'Dia $day'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: ClientColors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                disabledForegroundColor: ClientColors.textMuted,
                side: BorderSide(
                  color: onEdit == null ? ClientColors.border : Colors.white,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editar'),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: ClientColors.red,
                disabledForegroundColor: ClientColors.textMuted,
                side: BorderSide(
                  color: onDelete == null
                      ? ClientColors.border
                      : ClientColors.red,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Eliminar'),
            ),
          ],
        ),
        if (selectedEntry != null) ...[
          const SizedBox(height: 8),
          Text(
            'Seleccionado: ${selectedEntry!.exercise}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ClientColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _TrackingEntrySheet extends StatefulWidget {
  const _TrackingEntrySheet({
    required this.day,
    required this.muscles,
    this.initialEntry,
  });

  final int day;
  final List<TrainingMuscle> muscles;
  final TrackingEntry? initialEntry;

  @override
  State<_TrackingEntrySheet> createState() => _TrackingEntrySheetState();
}

class _TrackingEntrySheetState extends State<_TrackingEntrySheet> {
  final _manualExerciseController = TextEditingController();
  var _selectedMuscleIndex = 0;
  var _selectedPartIndex = 0;
  var _selectedExercise = '';
  var _useManualExercise = false;
  var _sets = 4;
  var _reps = 10;

  TrainingMuscle get _selectedMuscle {
    return widget.muscles[_selectedMuscleIndex];
  }

  TrainingMusclePart get _selectedPart {
    return _selectedMuscle.parts[_selectedPartIndex];
  }

  List<String> get _exerciseOptions => _selectedPart.exercises;

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    if (entry != null) {
      final muscleIndex = widget.muscles.indexWhere(
        (muscle) => muscle.name == entry.muscle,
      );
      if (muscleIndex != -1) {
        _selectedMuscleIndex = muscleIndex;
      }

      final partIndex = _selectedMuscle.parts.indexWhere(
        (part) => part.name == entry.part,
      );
      if (partIndex != -1) {
        _selectedPartIndex = partIndex;
      }

      _sets = entry.sets;
      _reps = entry.reps;
      if (_exerciseOptions.contains(entry.exercise)) {
        _selectedExercise = entry.exercise;
      } else {
        _selectedExercise = _exerciseOptions.first;
        _useManualExercise = true;
        _manualExerciseController.text = entry.exercise;
      }
      return;
    }

    _selectedExercise = _exerciseOptions.first;
  }

  @override
  void dispose() {
    _manualExerciseController.dispose();
    super.dispose();
  }

  void _save() {
    final exercise = _useManualExercise
        ? _manualExerciseController.text.trim()
        : _selectedExercise;

    if (exercise.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          mensajeFlotanteCliente('Agrega o selecciona un ejercicio.'),
        );
      return;
    }

    Navigator.of(context).pop(
      TrackingEntry(
        muscle: _selectedMuscle.name,
        part: _selectedPart.name,
        exercise: exercise,
        sets: _sets,
        reps: _reps,
      ),
    );
  }

  void _selectMuscle(int index) {
    setState(() {
      _selectedMuscleIndex = index;
      _selectedPartIndex = 0;
      _selectedExercise = _exerciseOptions.first;
    });
  }

  void _selectPart(int index) {
    setState(() {
      _selectedPartIndex = index;
      _selectedExercise = _exerciseOptions.first;
    });
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
                Expanded(
                  child: Text(
                    widget.initialEntry == null
                        ? 'Registrar dia ${widget.day}'
                        : 'Editar dia ${widget.day}',
                    style: const TextStyle(
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
            const Text(
              'Musculo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.muscles.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final muscle = widget.muscles[index];
                  return _SheetMuscleCard(
                    muscle: muscle,
                    isSelected: _selectedMuscleIndex == index,
                    onTap: () => _selectMuscle(index),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: ValueKey(_selectedMuscle.name),
              initialValue: _selectedPartIndex,
              dropdownColor: ClientColors.surface,
              decoration: _sheetInputDecoration(
                label: 'Parte del musculo',
                icon: Icons.adjust,
              ),
              items: [
                for (
                  var index = 0;
                  index < _selectedMuscle.parts.length;
                  index++
                )
                  DropdownMenuItem(
                    value: index,
                    child: Text(_selectedMuscle.parts[index].name),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  _selectPart(value);
                }
              },
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              value: _useManualExercise,
              contentPadding: EdgeInsets.zero,
              activeThumbColor: ClientColors.red,
              title: const Text(
                'Escribir ejercicio',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Elegir ejercicio',
                style: TextStyle(color: ClientColors.textMuted),
              ),
              onChanged: (value) {
                setState(() => _useManualExercise = value);
              },
            ),
            const SizedBox(height: 8),
            if (_useManualExercise)
              TextField(
                controller: _manualExerciseController,
                style: const TextStyle(color: Colors.white),
                decoration: _sheetInputDecoration(
                  label: 'Nombre del ejercicio',
                  icon: Icons.edit_outlined,
                ),
              )
            else
              DropdownButtonFormField<String>(
                key: ValueKey('${_selectedMuscle.name}-${_selectedPart.name}'),
                initialValue: _selectedExercise,
                dropdownColor: ClientColors.surface,
                decoration: _sheetInputDecoration(
                  label: 'Ejercicio',
                  icon: Icons.fitness_center,
                ),
                items: [
                  for (final exercise in _exerciseOptions)
                    DropdownMenuItem(value: exercise, child: Text(exercise)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedExercise = value);
                  }
                },
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StepperField(
                    label: 'Series',
                    value: _sets,
                    maxValue: 20,
                    onChanged: (value) => setState(() => _sets = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StepperField(
                    label: 'Reps',
                    value: _reps,
                    maxValue: 100,
                    onChanged: (value) => setState(() => _reps = value),
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
                label: Text(
                  widget.initialEntry == null
                      ? 'Guardar seguimiento'
                      : 'Actualizar seguimiento',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetMuscleCard extends StatelessWidget {
  const _SheetMuscleCard({
    required this.muscle,
    required this.isSelected,
    required this.onTap,
  });

  final TrainingMuscle muscle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: Material(
        color: isSelected ? ClientColors.red : ClientColors.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(clientMuscleIcon(muscle.name), color: Colors.white),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepperField extends StatelessWidget {
  const _StepperField({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int maxValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ClientColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: ClientColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StepperButton(
                icon: Icons.remove,
                onTap: value > 1 ? () => onChanged(value - 1) : null,
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StepperButton(
                icon: Icons.add,
                onTap: value < maxValue ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      style: IconButton.styleFrom(
        backgroundColor: ClientColors.surface,
        foregroundColor: Colors.white,
        disabledBackgroundColor: ClientColors.surface,
        disabledForegroundColor: ClientColors.textMuted,
        fixedSize: const Size(38, 38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
    );
  }
}

class _TrackingEntryTile extends StatelessWidget {
  const _TrackingEntryTile({
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  final TrackingEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? ClientColors.surfaceSoft : ClientColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? ClientColors.red : ClientColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ClientColors.redSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  clientMuscleIcon(entry.muscle),
                  color: ClientColors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.exercise,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.muscle} - ${entry.part}',
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
              const SizedBox(width: 10),
              Text(
                '${entry.sets}x${entry.reps}',
                style: const TextStyle(
                  color: ClientColors.red,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? ClientColors.red : ClientColors.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTrackingState extends StatelessWidget {
  const _EmptyTrackingState();

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
        'No hay registros en este dia. Usa Agregar para guardar tu entrenamiento.',
        style: TextStyle(color: ClientColors.textMuted, height: 1.35),
      ),
    );
  }
}

InputDecoration _sheetInputDecoration({
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

String _monthTitle(DateTime date) {
  const months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  return '${months[date.month - 1]} ${date.year}';
}
