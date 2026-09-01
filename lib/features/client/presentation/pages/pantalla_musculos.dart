import 'package:flutter/material.dart';

import '../../data/catalogo_entrenamiento_cliente.dart';
import '../../domain/entities/musculo_entrenamiento.dart';
import '../theme/colores_cliente.dart';
import '../widgets/icono_musculo_cliente.dart';
import '../widgets/titulo_seccion_cliente.dart';

class ClientMusclesPage extends StatefulWidget {
  const ClientMusclesPage({super.key});

  @override
  State<ClientMusclesPage> createState() => _ClientMusclesPageState();
}

class _ClientMusclesPageState extends State<ClientMusclesPage> {
  var _selectedMuscleIndex = 0;

  @override
  Widget build(BuildContext context) {
    const muscles = ClientTrainingCatalog.muscles;
    final selectedMuscle = muscles[_selectedMuscleIndex];

    return Scaffold(
      backgroundColor: ClientColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _MusclesHeader(),
                  const SizedBox(height: 18),
                  _MusclesGrid(
                    muscles: muscles,
                    selectedIndex: _selectedMuscleIndex,
                    onSelect: (index) {
                      setState(() => _selectedMuscleIndex = index);
                    },
                  ),
                  const SizedBox(height: 24),
                  _MusclePartsSection(muscle: selectedMuscle),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MusclePartsSection extends StatelessWidget {
  const _MusclePartsSection({required this.muscle});

  final TrainingMuscle muscle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClientSectionTitle(title: 'Partes de ${muscle.name}'),
        const SizedBox(height: 12),
        for (final part in muscle.parts) ...[
          _MusclePartTile(part: part),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MusclePartTile extends StatelessWidget {
  const _MusclePartTile({required this.part});

  final TrainingMusclePart part;

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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ClientColors.redSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.adjust, color: ClientColors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              part.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MusclesHeader extends StatelessWidget {
  const _MusclesHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Musculos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Explora cada grupo muscular y sus zonas de trabajo.',
          style: TextStyle(color: ClientColors.textMuted, height: 1.35),
        ),
      ],
    );
  }
}

class _MusclesGrid extends StatelessWidget {
  const _MusclesGrid({
    required this.muscles,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<TrainingMuscle> muscles;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: muscles.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final muscle = muscles[index];
        return _MuscleGridCard(
          muscle: muscle,
          isSelected: selectedIndex == index,
          onTap: () => onSelect(index),
        );
      },
    );
  }
}

class _MuscleGridCard extends StatelessWidget {
  const _MuscleGridCard({
    required this.muscle,
    required this.isSelected,
    required this.onTap,
  });

  final TrainingMuscle muscle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? ClientColors.red : ClientColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
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
              const SizedBox(height: 3),
              Text(
                '${muscle.parts.length} partes',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.82)
                      : ClientColors.textMuted,
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
