import 'package:flutter/material.dart';

import '../../../auth/domain/entities/usuario_autenticado.dart';
import '../../data/repositorio_rutinas_cliente_supabase.dart';
import '../theme/colores_cliente.dart';
import '../widgets/titulo_seccion_cliente.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({
    super.key,
    required this.usuario,
    required this.nombreUsuario,
    required this.reloadSignal,
    required this.onOpenMuscles,
    required this.onOpenRoutines,
    required this.onOpenTracking,
    required this.onOpenStopwatch,
  });

  final UsuarioAutenticado usuario;
  final String nombreUsuario;
  final int reloadSignal;
  final VoidCallback onOpenMuscles;
  final VoidCallback onOpenRoutines;
  final VoidCallback onOpenTracking;
  final VoidCallback onOpenStopwatch;

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  final _repositorioRutinas = const RepositorioRutinasClienteSupabase();
  final _diasEntrenamiento = <String>{};
  var _loadingRoutine = true;

  static const _weekDays = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];

  @override
  void initState() {
    super.initState();
    _loadRoutineDays();
  }

  @override
  void didUpdateWidget(covariant ClientHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadSignal != widget.reloadSignal) {
      _loadRoutineDays();
    }
  }

  Future<void> _loadRoutineDays() async {
    try {
      final rutina = await _repositorioRutinas.cargar(widget.usuario.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _diasEntrenamiento
          ..clear()
          ..addAll(
            rutina.musculosPorDia.entries
                .where((entry) => entry.value.isNotEmpty)
                .map((entry) => entry.key),
          );
        _loadingRoutine = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _loadingRoutine = false);
    }
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
                  _Header(
                    nombreUsuario: widget.nombreUsuario,
                    onOpenTracking: widget.onOpenTracking,
                  ),
                  const SizedBox(height: 24),
                  ClientSectionTitle(
                    title: 'Accesos rapidos',
                    actionLabel: 'Rutinas',
                    onActionTap: widget.onOpenRoutines,
                  ),
                  const SizedBox(height: 12),
                  _ActionGrid(
                    onOpenMuscles: widget.onOpenMuscles,
                    onOpenRoutines: widget.onOpenRoutines,
                    onOpenTracking: widget.onOpenTracking,
                    onOpenStopwatch: widget.onOpenStopwatch,
                  ),
                  const SizedBox(height: 24),
                  _WeeklyRoutinePreview(
                    isLoading: _loadingRoutine,
                    days: [
                      for (final day in _weekDays)
                        (day, _diasEntrenamiento.contains(day)),
                    ],
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

class _Header extends StatelessWidget {
  const _Header({required this.nombreUsuario, required this.onOpenTracking});

  final String nombreUsuario;
  final VoidCallback onOpenTracking;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ClientColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Text(
            'GP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${_primerNombre(nombreUsuario)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Listo para entrenar hoy',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: ClientColors.textMuted),
              ),
            ],
          ),
        ),
        IconButton.filled(
          tooltip: 'Abrir seguimiento',
          style: IconButton.styleFrom(
            backgroundColor: ClientColors.surface,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onOpenTracking,
          icon: const Icon(Icons.monitor_heart_outlined),
        ),
      ],
    );
  }
}

String _primerNombre(String nombre) {
  final limpio = nombre.trim();
  if (limpio.isEmpty) {
    return 'Usuario';
  }

  return limpio.split(RegExp(r'\s+')).first;
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.onOpenMuscles,
    required this.onOpenRoutines,
    required this.onOpenTracking,
    required this.onOpenStopwatch,
  });

  final VoidCallback onOpenMuscles;
  final VoidCallback onOpenRoutines;
  final VoidCallback onOpenTracking;
  final VoidCallback onOpenStopwatch;

  @override
  Widget build(BuildContext context) {
    final options = [
      _ActionOption(
        title: 'Musculos',
        subtitle: 'Ejercicios por grupo',
        icon: Icons.accessibility_new,
        onTap: onOpenMuscles,
      ),
      _ActionOption(
        title: 'Cronometro',
        subtitle: 'Series y descansos',
        icon: Icons.timer_outlined,
        onTap: onOpenStopwatch,
      ),
      _ActionOption(
        title: 'Semana',
        subtitle: 'Plan por dias',
        icon: Icons.view_week_outlined,
        onTap: onOpenRoutines,
      ),
      _ActionOption(
        title: 'Seguimiento',
        subtitle: 'Progreso muscular',
        icon: Icons.monitor_heart_outlined,
        onTap: onOpenTracking,
      ),
    ];

    return GridView.builder(
      itemCount: options.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        return _ActionTile(option: options[index]);
      },
    );
  }
}

class _ActionOption {
  const _ActionOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.option});

  final _ActionOption option;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ClientColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: option.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(option.icon, color: ClientColors.red),
              const Spacer(),
              Text(
                option.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                option.subtitle,
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

class _WeeklyRoutinePreview extends StatelessWidget {
  const _WeeklyRoutinePreview({required this.isLoading, required this.days});

  final bool isLoading;
  final List<(String, bool)> days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Semana de entrenamiento',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (isLoading) ...[
            const LinearProgressIndicator(
              minHeight: 2,
              color: ClientColors.red,
              backgroundColor: ClientColors.surface,
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              for (final day in days) ...[
                Expanded(
                  child: _DayPill(label: day.$1, isDone: day.$2),
                ),
                if (day != days.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({required this.label, required this.isDone});

  final String label;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDone ? ClientColors.red : ClientColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isDone ? Colors.white : ClientColors.textMuted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
