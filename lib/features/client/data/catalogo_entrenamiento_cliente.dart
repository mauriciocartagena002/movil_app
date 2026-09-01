import '../domain/entities/musculo_entrenamiento.dart';

class ClientTrainingCatalog {
  const ClientTrainingCatalog._();

  static const muscles = [
    TrainingMuscle(
      name: 'Pecho',
      parts: [
        TrainingMusclePart(
          name: 'Superior',
          exercises: ['Press inclinado', 'Aperturas inclinadas', 'Cruce alto'],
        ),
        TrainingMusclePart(
          name: 'Medio',
          exercises: ['Press banca', 'Aperturas planas', 'Flexiones'],
        ),
        TrainingMusclePart(
          name: 'Inferior',
          exercises: ['Fondos', 'Press declinado', 'Cruce bajo'],
        ),
      ],
    ),
    TrainingMuscle(
      name: 'Hombro',
      parts: [
        TrainingMusclePart(
          name: 'Deltoide anterior',
          exercises: ['Press militar', 'Elevacion frontal', 'Press Arnold'],
        ),
        TrainingMusclePart(
          name: 'Deltoide posterior',
          exercises: ['Face pull', 'Pajaros', 'Remo alto posterior'],
        ),
        TrainingMusclePart(
          name: 'Deltoide medial',
          exercises: [
            'Elevaciones laterales',
            'Remo al menton',
            'Press maquina',
          ],
        ),
      ],
    ),
    TrainingMuscle(
      name: 'Triceps',
      parts: [
        TrainingMusclePart(
          name: 'Cabeza larga',
          exercises: [
            'Extension sobre cabeza',
            'Press frances',
            'Copa mancuerna',
          ],
        ),
        TrainingMusclePart(
          name: 'Cabeza lateral',
          exercises: [
            'Extension en polea',
            'Fondos en paralelas',
            'Press cerrado',
          ],
        ),
        TrainingMusclePart(
          name: 'Cabeza medial',
          exercises: ['Jalon inverso', 'Patada triceps', 'Extension cuerda'],
        ),
      ],
    ),
    TrainingMuscle(
      name: 'Espalda',
      parts: [
        TrainingMusclePart(
          name: 'Espalda alta',
          exercises: ['Dominadas', 'Jalon al pecho', 'Remo sentado'],
        ),
        TrainingMusclePart(
          name: 'Deltoides',
          exercises: ['Face pull', 'Pajaros', 'Remo alto posterior'],
        ),
        TrainingMusclePart(
          name: 'Espalda baja',
          exercises: ['Peso muerto', 'Hiperextensiones', 'Buenos dias'],
        ),
      ],
    ),
    TrainingMuscle(
      name: 'Biceps',
      parts: [
        TrainingMusclePart(
          name: 'Cabeza larga',
          exercises: ['Curl inclinado', 'Curl barra recta', 'Curl concentrado'],
        ),
        TrainingMusclePart(
          name: 'Cabeza corta',
          exercises: ['Curl predicador', 'Curl spider', 'Curl polea baja'],
        ),
        TrainingMusclePart(
          name: 'Braquiales',
          exercises: ['Curl martillo', 'Curl reverso', 'Curl cuerda'],
        ),
      ],
    ),
    TrainingMuscle(
      name: 'Antebrazo',
      parts: [
        TrainingMusclePart(
          name: 'Flexores',
          exercises: ['Curl muneca', 'Agarre estatico', 'Farmer hold'],
        ),
        TrainingMusclePart(
          name: 'Extensores',
          exercises: [
            'Curl reverso muneca',
            'Extension dedos',
            'Rodillo antebrazo',
          ],
        ),
        TrainingMusclePart(
          name: 'Braquiorradial',
          exercises: ['Curl martillo', 'Curl reverso', 'Curl Zottman'],
        ),
      ],
    ),
    TrainingMuscle(
      name: 'Gluteos',
      parts: [
        TrainingMusclePart(
          name: 'Gluteo mayor',
          exercises: [
            'Hip thrust',
            'Peso muerto rumano',
            'Sentadilla profunda',
          ],
        ),
        TrainingMusclePart(
          name: 'Gluteo medio',
          exercises: [
            'Abduccion cadera',
            'Caminata lateral',
            'Step up lateral',
          ],
        ),
        TrainingMusclePart(
          name: 'Gluteo menor',
          exercises: ['Clamshell', 'Patada lateral', 'Puente unilateral'],
        ),
      ],
    ),
    TrainingMuscle(
      name: 'Pierna',
      parts: [
        TrainingMusclePart(
          name: 'Cuadriceps',
          exercises: ['Sentadilla', 'Prensa', 'Extension de cuadriceps'],
        ),
        TrainingMusclePart(
          name: 'Femorales',
          exercises: ['Curl femoral', 'Peso muerto rumano', 'Buenos dias'],
        ),
        TrainingMusclePart(
          name: 'Pantorrillas',
          exercises: [
            'Elevacion de talones',
            'Gemelo sentado',
            'Gemelo prensa',
          ],
        ),
        TrainingMusclePart(
          name: 'Aductores',
          exercises: ['Aductor maquina', 'Zancada lateral', 'Sentadilla sumo'],
        ),
      ],
    ),
    TrainingMuscle(
      name: 'Abdominales',
      parts: [
        TrainingMusclePart(
          name: 'Recto abdominal',
          exercises: ['Crunch', 'Elevacion de piernas', 'Ab wheel'],
        ),
        TrainingMusclePart(
          name: 'Oblicuos',
          exercises: ['Plancha lateral', 'Giro ruso', 'Woodchopper'],
        ),
        TrainingMusclePart(
          name: 'Transverso',
          exercises: ['Plancha', 'Dead bug', 'Vacuum abdominal'],
        ),
      ],
    ),
  ];
}
