import 'package:flutter/material.dart';

IconData clientMuscleIcon(String muscleName) {
  return switch (muscleName) {
    'Pecho' => Icons.monitor_heart_outlined,
    'Hombro' => Icons.sports_martial_arts,
    'Triceps' => Icons.fitness_center,
    'Espalda' => Icons.accessibility_new,
    'Biceps' => Icons.sports_gymnastics,
    'Antebrazo' => Icons.back_hand_outlined,
    'Gluteos' => Icons.directions_run,
    'Pierna' => Icons.directions_walk,
    'Abdominales' => Icons.self_improvement,
    _ => Icons.fitness_center,
  };
}
