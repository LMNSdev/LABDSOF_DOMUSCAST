import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/sessao_residente.dart';
import 'ler_qr_screen.dart';

/// US-23: o administrador removeu a identidade deste telemóvel.
///
/// A app já apagou a credencial guardada. Os reportes por enviar ficam na fila
/// local; a recusa desses envios é da US-18.
class AcessoRemovidoScreen extends StatelessWidget {
  final ApiService api;
  final SessaoResidenteStore store;

  const AcessoRemovidoScreen({super.key, required this.api, required this.store});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('DomusCast'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: scheme.errorContainer,
                  foregroundColor: scheme.error,
                  child: const Icon(Icons.error_outline, size: 44),
                ),
                const SizedBox(height: 20),
                Text(
                  'O seu acesso foi removido',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'O administrador removeu o acesso deste telemóvel. '
                  'Se ainda vive no prédio, peça-lhe um novo QR code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.5, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => LerQrScreen(api: api, store: store),
                    )),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Ler QR code'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
