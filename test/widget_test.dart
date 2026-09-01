import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:aplicacion_movil/features/auth/domain/entities/usuario_autenticado.dart';
import 'package:aplicacion_movil/features/client/presentation/pages/pantalla_cliente.dart';
import 'package:aplicacion_movil/main.dart';

void main() {
  Future<void> ensureMenuOpen(WidgetTester tester) async {
    final openMenuButton = find.byIcon(Icons.menu);
    if (tester.any(openMenuButton)) {
      await tester.tap(openMenuButton);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('shows client home screen', (WidgetTester tester) async {
    const usuario = UsuarioAutenticado(
      id: 'usuario-test',
      correo: 'cliente@gympro.local',
      nombreCompleto: 'Cliente Nuevo',
      rol: 'usuario',
      idPublico: '1234567',
    );

    await tester.pumpWidget(
      const GymProApp(home: ClientShellPage(usuario: usuario)),
    );

    expect(find.text('Hola, Cliente'), findsOneWidget);
    expect(find.text('Rutina activa'), findsNothing);
    expect(find.text('Proximo entrenamiento'), findsNothing);
    expect(find.text('Accesos rapidos'), findsOneWidget);

    await ensureMenuOpen(tester);
    await tester.tap(find.text('Musculos').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Explora cada grupo muscular y sus zonas de trabajo.'),
      findsOneWidget,
    );
    expect(find.text('Pecho'), findsOneWidget);

    await ensureMenuOpen(tester);
    await tester.tap(find.text('Rutinas').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Organiza tus entrenamientos por dia y grupo muscular.'),
      findsOneWidget,
    );
    expect(find.text('Plan semanal'), findsOneWidget);
    expect(find.text('Selecciona un dia'), findsOneWidget);

    await ensureMenuOpen(tester);
    await tester.tap(find.text('Seguimiento').last);
    await tester.pumpAndSettle();

    expect(find.text('Seguimiento muscular'), findsOneWidget);
    expect(find.text('Calendario de entrenamiento'), findsOneWidget);

    await ensureMenuOpen(tester);
    await tester.tap(find.text('Tiempo').last);
    await tester.pumpAndSettle();

    expect(find.text('Cronometro'), findsOneWidget);
    expect(find.text('Iniciar'), findsOneWidget);
    expect(find.text('Vueltas'), findsNothing);

    await ensureMenuOpen(tester);
    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle();

    expect(find.text('Perfil'), findsWidgets);
    expect(find.text('Cliente Nuevo'), findsOneWidget);
    expect(find.text('1234567'), findsNothing);
    expect(find.text('Codigo personal'), findsNothing);
    expect(find.text('Objetivo actual'), findsNothing);
    expect(find.text('Progreso'), findsNothing);
    expect(find.text('Cuenta'), findsNothing);
  });
}
