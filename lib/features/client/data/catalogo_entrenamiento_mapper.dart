import '../domain/entities/musculo_entrenamiento.dart';
import 'repositorio_ejercicios_cliente_supabase.dart';

List<TrainingMuscle> crearCatalogoEntrenamientoDesdeBase(
  CatalogoEjerciciosCliente catalogo,
) {
  final ejerciciosPorParte = <String, List<String>>{};
  for (final ejercicio in catalogo.ejercicios) {
    ejerciciosPorParte
        .putIfAbsent(ejercicio.parteMusculoId, () => <String>[])
        .add(ejercicio.nombre);
  }

  return [
    for (final musculo in catalogo.musculos)
      TrainingMuscle(
        name: musculo.nombre,
        parts: [
          for (final parte in catalogo.partes)
            if (parte.musculoId == musculo.id)
              TrainingMusclePart(
                name: parte.nombre,
                exercises: ejerciciosPorParte[parte.id] ?? const [],
              ),
        ],
      ),
  ].where((musculo) => musculo.parts.isNotEmpty).toList(growable: false);
}
