import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../services/api_service.dart';
import '../services/sessao_admin.dart';
import '../widgets/qr_codes_ativos.dart';
import '../widgets/residentes_fracao.dart';

/// US-01: gera um QR code para a fração, para enviar ou mostrar a um residente.
/// US-20: por baixo, a lista dos QR codes ativos, para revogar um ou todos.
/// US-23: no fim do ecrã, os residentes da fração, para remover quem saiu.
///
/// O servidor só guarda o hash do token, por isso cada QR é gerado a pedido e
/// não pode ser mostrado de novo. Os QR gerados antes continuam válidos.
class FracaoQrScreen extends StatefulWidget {
  final ApiService api;
  final SessaoAdmin sessao;
  final int fracaoId;
  final String designacao;

  const FracaoQrScreen({
    super.key,
    required this.api,
    required this.sessao,
    required this.fracaoId,
    required this.designacao,
  });

  @override
  State<FracaoQrScreen> createState() => _FracaoQrScreenState();
}

class _FracaoQrScreenState extends State<FracaoQrScreen> {
  String? _link;
  bool _aGerar = false;
  String? _erro;

  /// Muda a cada QR gerado, para a lista dos ativos (US-20) recarregar.
  int _versaoQr = 0;

  /// Id do QR code mostrado no ecrã, para o tirar se for revogado (US-20).
  int? _qrId;

  Future<void> _gerar() async {
    setState(() {
      _aGerar = true;
      _erro = null;
    });
    try {
      final qr = await widget.api.gerarQr(widget.fracaoId, widget.sessao.credencial);
      if (!mounted) return;
      setState(() {
        _link = qr['link'] as String;
        _qrId = qr['id'] as int?;
        _versaoQr++;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível gerar o QR code. Verifique a ligação.');
    } finally {
      if (mounted) setState(() => _aGerar = false);
    }
  }

  Future<void> _partilhar() async {
    final link = _link!;
    final painter = QrPainter(
      data: link,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
      dataModuleStyle:
          const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
    );
    final png = await painter.toImageData(800, format: ui.ImageByteFormat.png);
    final texto = 'Acesso ao condomínio ${widget.sessao.nomeCondominio}, fração '
        '${widget.designacao}. Abra este link no telemóvel com a app DomusCast '
        'instalada: $link';
    await SharePlus.instance.share(ShareParams(
      text: texto,
      subject: 'DomusCast: fração ${widget.designacao}',
      files: [
        if (png != null)
          XFile.fromData(png.buffer.asUint8List(),
              mimeType: 'image/png', name: 'domuscast-fracao-${widget.designacao}.png'),
      ],
    ));
  }

  void _ecraInteiro() {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _QrEcraInteiro(link: _link!, designacao: widget.designacao),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: Text('Fração ${widget.designacao}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: _link == null
                  ? Container(
                      width: 240,
                      height: 240,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: muted.withValues(alpha: 0.5), width: 2),
                      ),
                      child: Text(
                        'Gera um QR code para enviar ou mostrar a um residente '
                        'da fração ${widget.designacao}.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted),
                      ),
                    )
                  : Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: QrImageView(
                        key: ValueKey('qr:$_link'),
                        data: _link!,
                        size: 240,
                        backgroundColor: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            if (_link != null)
              Text(
                'Serve para todos os residentes da fração ${widget.designacao}. '
                'Os QR codes gerados antes continuam válidos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted),
              ),
            if (_erro != null)
              Text(_erro!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 24),
            if (_link == null)
              FilledButton(
                onPressed: _aGerar ? null : _gerar,
                child: _aGerar
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Gerar QR code'),
              )
            else ...[
              FilledButton.icon(
                onPressed: _partilhar,
                icon: const Icon(Icons.share),
                label: const Text('Partilhar'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _ecraInteiro,
                icon: const Icon(Icons.fullscreen),
                label: const Text('Ecrã inteiro'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 32),
            QrCodesAtivos(
              key: ValueKey(_versaoQr),
              api: widget.api,
              sessao: widget.sessao,
              fracaoId: widget.fracaoId,
              designacao: widget.designacao,
              // Se o QR code mostrado foi revogado (sozinho ou com "Revogar
              // todos"), sai do ecrã e volta "Gerar QR code".
              onRevogado: (qrId) {
                if (qrId == null || qrId == _qrId) {
                  setState(() {
                    _link = null;
                    _qrId = null;
                  });
                }
              },
            ),
            const SizedBox(height: 32),
            ResidentesFracao(
              api: widget.api,
              sessao: widget.sessao,
              fracaoId: widget.fracaoId,
            ),
          ],
        ),
      ),
    );
  }
}

class _QrEcraInteiro extends StatelessWidget {
  final String link;
  final String designacao;

  const _QrEcraInteiro({required this.link, required this.designacao});

  @override
  Widget build(BuildContext context) {
    final lado = MediaQuery.of(context).size.shortestSide * 0.85;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        // O tema pinta os títulos a branco; aqui o fundo é branco.
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        title: Text('Fração $designacao'),
      ),
      body: Center(
        child: QrImageView(data: link, size: lado, backgroundColor: Colors.white),
      ),
    );
  }
}
