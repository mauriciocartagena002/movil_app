class TrainingMuscle {
  const TrainingMuscle({required this.name, required this.parts});

  final String name;
  final List<TrainingMusclePart> parts;

  int get exerciseCount {
    return parts.fold(0, (total, part) => total + part.exercises.length);
  }
}

class TrainingMusclePart {
  const TrainingMusclePart({required this.name, required this.exercises});

  final String name;
  final List<String> exercises;
}
