import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/api_service.dart';
import '../services/sessao_residente.dart';
import 'nome_residente_screen.dart';

/// Token de um link `domuscast://entrar?t=<token>` (o conteúdo do QR code da US-01).
String? tokenDoLink(String texto) {
  final uri = Uri.tryParse(texto.trim());
  if (uri == null || uri.scheme != 'domuscast' || uri.host != 'entrar') return null;
  final token = uri.queryParameters['t'];
  return (token == null || token.isEmpty) ? null : token;
}

/// US-15, ecrã 2: ler o QR code da fração com a câmara, ou colar o link recebido.
class LerQrScreen extends StatefulWidget {
  final ApiService api;
  final SessaoResidenteStore store;

  /// Substitui a câmara nos testes, onde não existe.
  final Widget? camara;

  const LerQrScreen({super.key, required this.api, required this.store, this.camara});

  @override
  State<LerQrScreen> createState() => _LerQrScreenState();
}

class _LerQrScreenState extends State<LerQrScreen> {
  bool _lido = false;
  bool _invalido = false;

  void _abrirNome(String token) {
    _lido = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => NomeResidenteScreen(api: widget.api, store: widget.store, token: token),
    ));
  }

  void _detetado(BarcodeCapture captura) {
    if (_lido || _invalido) return;
    final texto = captura.barcodes.firstOrNull?.rawValue;
    if (texto == null) return;
    final token = tokenDoLink(texto);
    if (token == null) {
      setState(() => _invalido = true);
    } else {
      _abrirNome(token);
    }
  }

  Future<void> _recebiLink() async {
    final token = await showDialog<String>(context: context, builder: (_) => const _DialogoLink());
    if (token != null && mounted) _abrirNome(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ler QR code')),
      body: SafeArea(
        child: _invalido
            ? AvisoEntrada(
                titulo: 'QR code inválido',
                texto: 'Este QR code não é válido ou foi revogado. Peça um novo ao administrador.',
                botao: 'Ler outro QR code',
                onPressed: () => setState(() => _invalido = false),
              )
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Aponte a câmara para o QR code da sua fração, enviado ou mostrado pelo administrador.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'Câmara a ler o QR code',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 320,
                        child: widget.camara ??
                            MobileScanner(
                              onDetect: _detetado,
                              errorBuilder: (context, erro) => const _SemCamara(),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _recebiLink,
                    icon: const Icon(Icons.link),
                    label: const Text('Recebi um link'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SemCamara extends StatelessWidget {
  const _SemCamara();

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Container(
      color: cores.inverseSurface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Text(
        'Sem acesso à câmara. Permita o acesso nas definições do telemóvel ou use o link que recebeu.',
        textAlign: TextAlign.center,
        style: TextStyle(color: cores.onInverseSurface),
      ),
    );
  }
}

class _DialogoLink extends StatefulWidget {
  const _DialogoLink();

  @override
  State<_DialogoLink> createState() => _DialogoLinkState();
}

class _DialogoLinkState extends State<_DialogoLink> {
  final _ctrl = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _continuar() {
    final token = tokenDoLink(_ctrl.text);
    if (token == null) {
      setState(() => _erro = 'Cole o link domuscast://entrar enviado pelo administrador.');
      return;
    }
    Navigator.of(context).pop(token);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Recebi um link'),
        content: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: InputDecoration(labelText: 'Link', errorText: _erro, errorMaxLines: 3),
          onSubmitted: (_) => _continuar(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(onPressed: _continuar, child: const Text('Continuar')),
        ],
      );
}

/// Ecrã de erro dos wireframes 4b, 4c e 4d: título, explicação e uma ação.
class AvisoEntrada extends StatelessWidget {
  final String titulo;
  final String texto;
  final String botao;
  final VoidCallback? onPressed;

  const AvisoEntrada({
    super.key,
    required this.titulo,
    required this.texto,
    required this.botao,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        Icon(Icons.error_outline, size: 56, color: cores.error),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(titulo,
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 8),
        Text(texto, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 32),
        FilledButton(onPressed: onPressed, child: Text(botao)),
      ],
    );
  }
}
