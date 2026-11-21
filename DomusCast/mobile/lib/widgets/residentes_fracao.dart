import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/sessao_admin.dart';

/// US-23: residentes ativos da fração, com remover quem saiu.
///
/// Remover apaga o nome, tira o acesso ao telemóvel dessa pessoa e deixa os
/// reportes como "Residente removido". Pede sempre confirmação.
class ResidentesFracao extends StatefulWidget {
  final ApiService api;
  final SessaoAdmin sessao;
  final int fracaoId;

  const ResidentesFracao({
    super.key,
    required this.api,
    required this.sessao,
    required this.fracaoId,
  });

  @override
  State<ResidentesFracao> createState() => _ResidentesFracaoState();
}

/// "16/11", na data local.
String _dia(String iso) {
  final d = DateTime.parse(iso).toLocal();
  String dois(int v) => v.toString().padLeft(2, '0');
  return '${dois(d.day)}/${dois(d.month)}';
}

class _ResidentesFracaoState extends State<ResidentesFracao> {
  List<Map<String, dynamic>> _residentes = [];
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
      final residentes =
          await widget.api.getIdentidadesFracao(widget.fracaoId, widget.sessao.credencial);
      if (!mounted) return;
      setState(() {
        _residentes = residentes;
        _aCarregar = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar os residentes.';
        _aCarregar = false;
      });
    }
  }

  void _mensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _remover(Map<String, dynamic> residente) async {
    final nome = residente['nome'] as String;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remover $nome?'),
        content: const Text(
          'O nome é apagado e o telemóvel desta pessoa deixa de ter acesso. '
          'Os reportes ficam como "Residente removido". Não se pode desfazer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await widget.api.removerIdentidade(residente['id'] as int, widget.sessao.credencial);
      _mensagem('$nome já não tem acesso.');
    } on ApiException catch (e) {
      _mensagem(e.statusCode == 404
          ? 'Esta pessoa já tinha sido removida.'
          : 'Não foi possível remover. Tente novamente.');
    } catch (_) {
      _mensagem('Sem ligação. Ninguém foi removido.');
    }
    if (mounted) await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titulo = Text(
      'Residentes',
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
    } else if (_residentes.isEmpty) {
      corpo = Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Ainda ninguém entrou nesta fração.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    } else {
      corpo = Card(
        margin: EdgeInsets.zero,
        child: Column(children: [
          for (final r in _residentes)
            ListTile(
              title: Text(
                r['nome'] as String,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('entrou a ${_dia(r['criado_em'] as String)}'),
              // A etiqueta vai no texto: um Semantics com excludeSemantics tirava
              // ao botão a ação de toque e o TalkBack não o conseguia ativar.
              trailing: TextButton(
                onPressed: () => _remover(r),
                style: TextButton.styleFrom(foregroundColor: scheme.error),
                child: Text('Remover', semanticsLabel: 'Remover ${r['nome']}'),
              ),
            ),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [titulo, const SizedBox(height: 8), corpo],
    );
  }
}
