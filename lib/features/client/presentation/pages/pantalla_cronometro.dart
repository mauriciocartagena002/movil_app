import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/colores_cliente.dart';

class ClientStopwatchPage extends StatefulWidget {
  const ClientStopwatchPage({super.key});

  @override
  State<ClientStopwatchPage> createState() => _ClientStopwatchPageState();
}

class _ClientStopwatchPageState extends State<ClientStopwatchPage> {
  final _stopwatch = Stopwatch();
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_stopwatch.isRunning) {
      return;
    }
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        _elapsed = _stopwatch.elapsed;
      });
    });
  }

  void _pause() {
    _stopwatch.stop();
    _timer?.cancel();
    setState(() {
      _elapsed = _stopwatch.elapsed;
    });
  }

  void _reset() {
    _timer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _elapsed = Duration.zero;
    });
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final tenths = (duration.inMilliseconds.remainder(1000) ~/ 100).toString();
    return '$minutes:$seconds.$tenths';
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _stopwatch.isRunning;

    return Scaffold(
      backgroundColor: ClientColors.background,
      appBar: AppBar(
        backgroundColor: ClientColors.background,
        foregroundColor: Colors.white,
        title: const Text('Cronometro'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: ClientColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ClientColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: ClientColors.red,
                      size: 42,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _formatTime(_elapsed),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tiempo de serie o descanso',
                      style: TextStyle(color: ClientColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: isRunning
                            ? ClientColors.surfaceSoft
                            : ClientColors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: isRunning ? _pause : _start,
                      icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                      label: Text(isRunning ? 'Pausar' : 'Iniciar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    tooltip: 'Reiniciar',
                    style: IconButton.styleFrom(
                      backgroundColor: ClientColors.surface,
                      foregroundColor: Colors.white,
                      fixedSize: const Size(54, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _reset,
                    icon: const Icon(Icons.restart_alt),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _StopwatchHint(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopwatchHint extends StatelessWidget {
  const _StopwatchHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ClientColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ClientColors.border),
      ),
      child: const Text(
        'Usalo para controlar el tiempo entre series o medir la duracion de un ejercicio.',
        textAlign: TextAlign.center,
        style: TextStyle(color: ClientColors.textMuted, height: 1.35),
      ),
    );
  }
}
