import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/sessao_admin.dart';

/// US-20: QR codes ativos da fração, com revogar um ou todos.
///
/// A lista não tem o token (o servidor só guarda o hash): cada QR code é
/// identificado pela data e hora de criação e pelo nº de residentes que
/// entraram com ele e ainda têm acesso. Revogar pede sempre confirmação.
class QrCodesAtivos extends StatefulWidget {
  final ApiService api;
  final SessaoAdmin sessao;
  final int fracaoId;
  final String designacao;

  /// Chamado depois de revogar: com o id do QR code, ou `null` quando foram
  /// revogados todos os da fração.
  final void Function(int? qrId)? onRevogado;

  const QrCodesAtivos({
    super.key,
    required this.api,
    required this.sessao,
    required this.fracaoId,
    required this.designacao,
    this.onRevogado,
  });

  @override
  State<QrCodesAtivos> createState() => _QrCodesAtivosState();
}

/// "16/11 às 14:32", na hora local.
String formatarCriacaoQr(String iso) {
  final d = DateTime.parse(iso).toLocal();
  String dois(int v) => v.toString().padLeft(2, '0');
  return '${dois(d.day)}/${dois(d.month)} às ${dois(d.hour)}:${dois(d.minute)}';
}

String _residentes(int n) => n == 1 ? '1 residente entrou' : '$n residentes entraram';

String _mantemAcesso(int n) => switch (n) {
      0 => '',
      1 => ' O residente que já entrou continua com acesso.',
      _ => ' Os $n residentes que já entraram continuam com acesso.',
    };

String _revogados(int n) => switch (n) {
      0 => 'Não havia QR codes ativos.',
      1 => '1 QR code revogado.',
      _ => '$n QR codes revogados.',
    };

class _QrCodesAtivosState extends State<QrCodesAtivos> {
  List<Map<String, dynamic>> _qrs = [];
  bool _aCarregar = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _aCarregar = true;
      _erro = null;
    });
    try {
      final qrs = await widget.api.getQrAtivos(widget.fracaoId, widget.sessao.credencial);
      if (!mounted) return;
      setState(() {
        _qrs = qrs;
        _aCarregar = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar os QR codes.';
        _aCarregar = false;
      });
    }
  }

  Future<bool> _confirmar(String titulo, String texto, String acao) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(acao),
          ),
        ],
      ),
    );
    return ok == true;
  }

  void _mensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _revogar(Map<String, dynamic> qr) async {
    final n = qr['n_residentes'] as int;
    final ok = await _confirmar(
      'Revogar este QR code?',
      'Deixa de permitir novos acessos.${_mantemAcesso(n)}',
      'Revogar',
    );
    if (!ok) return;
    final id = qr['id'] as int;
    await _executar(
      () => widget.api.revogarQr(id, widget.sessao.credencial),
      qrId: id,
      jaRevogado: 'Este QR code já tinha sido revogado.',
    );
  }

  Future<void> _revogarTodos() async {
    final ok = await _confirmar(
      'Revogar todos os QR codes da fração ${widget.designacao}?',
      'Ninguém consegue entrar com eles. Quem já entrou mantém o acesso; '
          'para remover alguém, use a lista de residentes.',
      'Revogar todos',
    );
    if (!ok) return;
    await _executar(() => widget.api.revogarTodosQr(widget.fracaoId, widget.sessao.credencial));
  }

  /// Revoga, avisa o resultado e recarrega a lista (também depois de um erro).
  Future<void> _executar(
    Future<int> Function() pedido, {
    int? qrId,
    String? jaRevogado,
  }) async {
    try {
      final n = await pedido();
      _mensagem(_revogados(n));
      if (n > 0) widget.onRevogado?.call(qrId);
    } on ApiException catch (e) {
      final jaEstavaRevogado = e.statusCode == 404 && jaRevogado != null;
      _mensagem(jaEstavaRevogado ? jaRevogado : 'Não foi possível revogar. Tente novamente.');
      // Revogado noutro telemóvel: também sai do ecrã, se for o QR code mostrado.
      if (jaEstavaRevogado) widget.onRevogado?.call(qrId);
    } catch (_) {
      _mensagem('Sem ligação. O QR code não foi revogado.');
    }
    if (mounted) await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titulo = Text(
      'QR codes ativos',
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: scheme.primary),
    );

    final Widget corpo;
    if (_aCarregar) {
      corpo = const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_erro != null) {
      corpo = Column(children: [
        Text(_erro!, textAlign: TextAlign.center),
        TextButton(onPressed: _carregar, child: const Text('Tentar de novo')),
      ]);
    } else if (_qrs.isEmpty) {
      corpo = Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Nenhum QR code ativo. Gere um novo para dar acesso a um residente.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    } else {
      corpo = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Column(children: [
              for (final qr in _qrs)
                ListTile(
                  title: Text(
                    formatarCriacaoQr(qr['criado_em'] as String),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(_residentes(qr['n_residentes'] as int)),
                  // A etiqueta vai no texto: um Semantics com excludeSemantics tirava
                  // ao botão a ação de toque e o TalkBack não o conseguia ativar.
                  trailing: TextButton(
                    onPressed: () => _revogar(qr),
                    style: TextButton.styleFrom(foregroundColor: scheme.error),
                    child: Text(
                      'Revogar',
                      semanticsLabel:
                          'Revogar o QR code de ${formatarCriacaoQr(qr['criado_em'] as String)}',
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _revogarTodos,
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Revogar todos'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [titulo, const SizedBox(height: 8), corpo],
    );
  }
}
