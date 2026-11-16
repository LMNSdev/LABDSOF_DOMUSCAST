import 'package:flutter/material.dart';

/// Separador "Reuniões". Por agora só o estado vazio; o agendamento e a lista
/// chegam com a US-13 e a US-27.
class ReunioesScreen extends StatelessWidget {
  const ReunioesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: const Text('Reuniões')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_outlined, size: 56, color: muted),
              const SizedBox(height: 12),
              Text('As reuniões vão aparecer aqui.',
                  textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
