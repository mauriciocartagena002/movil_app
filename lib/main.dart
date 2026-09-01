import 'package:flutter/material.dart';

import 'features/auth/presentation/pages/puerta_autenticacion.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GymProApp());
}

class GymProApp extends StatelessWidget {
  const GymProApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymPro',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const _GymProScrollBehavior(),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF09090B),
      ),
      home: home ?? const PuertaAutenticacion(),
    );
  }
}

class _GymProScrollBehavior extends MaterialScrollBehavior {
  const _GymProScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
