import 'package:flutter/material.dart';

import '../../../auth/domain/entities/usuario_autenticado.dart';
import '../theme/colores_cliente.dart';
import 'pantalla_cronometro.dart';
import 'pantalla_ejercicios.dart';
import 'pantalla_inicio_cliente.dart';
import 'pantalla_musculos.dart';
import 'pantalla_perfil.dart';
import 'pantalla_rutinas.dart';
import 'pantalla_seguimiento_muscular.dart';

class ClientShellPage extends StatefulWidget {
  const ClientShellPage({
    super.key,
    required this.usuario,
    this.onCerrarSesion,
  });

  final UsuarioAutenticado usuario;
  final Future<void> Function()? onCerrarSesion;

  @override
  State<ClientShellPage> createState() => _ClientShellPageState();
}

class _ClientShellPageState extends State<ClientShellPage> {
  var _selectedIndex = 0;
  var _isMenuOpen = false;
  var _routineReloadSignal = 0;

  static const _navigationItems = [
    _ClientNavItem(
      label: 'Inicio',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _ClientNavItem(
      label: 'Musculos',
      icon: Icons.accessibility_new_outlined,
      selectedIcon: Icons.accessibility_new,
    ),
    _ClientNavItem(
      label: 'Rutinas',
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center,
    ),
    _ClientNavItem(
      label: 'Ejercicios',
      icon: Icons.sports_gymnastics_outlined,
      selectedIcon: Icons.sports_gymnastics,
    ),
    _ClientNavItem(
      label: 'Seguimiento',
      icon: Icons.monitor_heart_outlined,
      selectedIcon: Icons.monitor_heart,
    ),
    _ClientNavItem(
      label: 'Tiempo',
      icon: Icons.timer_outlined,
      selectedIcon: Icons.timer,
    ),
    _ClientNavItem(
      label: 'Perfil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
      _isMenuOpen = false;
    });
  }

  void _refreshRoutinePreview() {
    setState(() => _routineReloadSignal++);
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _closeMenu() {
    setState(() {
      _isMenuOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ClientHomePage(
        usuario: widget.usuario,
        nombreUsuario: widget.usuario.nombreCompleto,
        reloadSignal: _routineReloadSignal,
        onOpenMuscles: () => _selectPage(1),
        onOpenRoutines: () => _selectPage(2),
        onOpenTracking: () => _selectPage(4),
        onOpenStopwatch: () => _selectPage(5),
      ),
      const ClientMusclesPage(),
      ClientRoutinesPage(
        usuario: widget.usuario,
        onRutinaGuardada: _refreshRoutinePreview,
      ),
      ClientExercisesPage(usuario: widget.usuario),
      ClientMuscleTrackingPage(usuario: widget.usuario),
      const ClientStopwatchPage(),
      ClientProfilePage(
        usuario: widget.usuario,
        onCerrarSesion: widget.onCerrarSesion,
      ),
    ];

    return Scaffold(
      backgroundColor: ClientColors.background,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 52),
            child: IndexedStack(index: _selectedIndex, children: pages),
          ),
          _ClientTopNavigation(
            items: _navigationItems,
            selectedIndex: _selectedIndex,
            isOpen: _isMenuOpen,
            onToggle: _toggleMenu,
            onClose: _closeMenu,
            onSelect: _selectPage,
          ),
        ],
      ),
    );
  }
}

class _ClientNavItem {
  const _ClientNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _ClientTopNavigation extends StatelessWidget {
  const _ClientTopNavigation({
    required this.items,
    required this.selectedIndex,
    required this.isOpen,
    required this.onToggle,
    required this.onClose,
    required this.onSelect,
  });

  final List<_ClientNavItem> items;
  final int selectedIndex;
  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onClose;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final currentItem = items[selectedIndex];
    final menuWidth = (MediaQuery.sizeOf(context).width - 32)
        .clamp(240.0, 328.0)
        .toDouble();

    return Stack(
      children: [
        IgnorePointer(
          ignoring: !isOpen,
          child: AnimatedOpacity(
            opacity: isOpen ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: GestureDetector(
              onTap: onClose,
              child: Container(color: Colors.black.withValues(alpha: 0.36)),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MenuToggleButton(isOpen: isOpen, onTap: onToggle),
                    const SizedBox(width: 12),
                    AnimatedOpacity(
                      opacity: isOpen ? 0 : 1,
                      duration: const Duration(milliseconds: 140),
                      child: IgnorePointer(
                        ignoring: isOpen,
                        child: _CurrentPagePill(item: currentItem),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AnimatedSlide(
                  offset: isOpen ? Offset.zero : const Offset(-0.08, 0),
                  duration: const Duration(milliseconds: 210),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: isOpen ? 1 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: IgnorePointer(
                      ignoring: !isOpen,
                      child: SizedBox(
                        width: menuWidth,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: ClientColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ClientColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.42),
                                blurRadius: 28,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: ClientColors.red,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'GP',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'GymPro',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Menu de usuario',
                                            style: TextStyle(
                                              color: ClientColors.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Cerrar menu',
                                      onPressed: onClose,
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                for (
                                  var index = 0;
                                  index < items.length;
                                  index++
                                )
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: index == items.length - 1 ? 0 : 8,
                                    ),
                                    child: _ClientNavigationButton(
                                      item: items[index],
                                      isSelected: selectedIndex == index,
                                      onTap: () => onSelect(index),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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

class _MenuToggleButton extends StatelessWidget {
  const _MenuToggleButton({required this.isOpen, required this.onTap});

  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isOpen ? ClientColors.red : ClientColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isOpen ? ClientColors.red : ClientColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.26),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(isOpen ? Icons.close : Icons.menu, color: Colors.white),
        ),
      ),
    );
  }
}

class _CurrentPagePill extends StatelessWidget {
  const _CurrentPagePill({required this.item});

  final _ClientNavItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ClientColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ClientColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.selectedIcon, color: ClientColors.red, size: 18),
          const SizedBox(width: 8),
          Text(
            item.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientNavigationButton extends StatelessWidget {
  const _ClientNavigationButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _ClientNavItem item;
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
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.chevron_right,
                color: Colors.white.withValues(alpha: isSelected ? 1 : 0.72),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
