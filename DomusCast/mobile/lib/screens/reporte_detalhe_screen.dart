import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ReporteDetalheScreen extends StatefulWidget {
  final ApiService api;
  final String? credencial;
  final int reporteId;
  final VoidCallback? onAcessoRemovido;

  const ReporteDetalheScreen({
    super.key,
    required this.api,
    required this.reporteId,
    this.credencial,
    this.onAcessoRemovido,
  });

  @override
  State<ReporteDetalheScreen> createState() => _ReporteDetalheScreenState();
}

class _ReporteDetalheScreenState extends State<ReporteDetalheScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _reporte;
  Uint8List? _foto;
  String? _erro;
  bool _loading = true;
  bool _refreshing = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _timer?.cancel();
    _timer = null;
    if (state == AppLifecycleState.resumed) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
      _load();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    if (_refreshing) return;
    _refreshing = true;
    setState(() {
      _loading = _reporte == null;
      _erro = null;
    });
    try {
      final reporte = await widget.api.getReporte(
        widget.reporteId,
        credencial: widget.credencial,
      );
      Uint8List? foto;
      if (reporte['foto_url'] != null) {
        try {
          foto = await widget.api.getReporteFoto(
            widget.reporteId,
            credencial: widget.credencial,
          );
        } on Exception {
          // O reporte continua legível se a foto estiver temporariamente indisponível.
        }
      }
      if (!mounted) return;
      setState(() {
        _reporte = reporte;
        _foto = foto;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401 && widget.onAcessoRemovido != null) {
        widget.onAcessoRemovido!();
        return;
      }
      if (_reporte != null && e.statusCode != 401) {
        _avisarFalha();
        return;
      }
      setState(() {
        _erro = e.statusCode == 401
            ? 'A sua sessão já não é válida.'
            : e.statusCode == 404
            ? 'Reporte não encontrado.'
            : 'Não foi possível carregar o reporte. Verifique a ligação.';
        _loading = false;
      });
    } on Exception {
      if (!mounted) return;
      if (_reporte != null) {
        _avisarFalha();
        return;
      }
      setState(() {
        _erro = 'Não foi possível carregar o reporte. Verifique a ligação.';
        _loading = false;
      });
    } finally {
      _refreshing = false;
    }
  }

  void _avisarFalha() {
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sem ligação. A mostrar o último reporte.')),
    );
  }

  String _data(dynamic value) {
    if (value is! String) return '';
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} às ${two(date.hour)}:${two(date.minute)}';
  }

  String _estado(dynamic value) => switch (value) {
    'em_curso' => 'Em curso',
    'resolvido' => 'Resolvido',
    _ => 'Aberto',
  };

  String _autor(Map<String, dynamic> r) {
    if (r['meu'] == true) return 'O meu reporte';
    if (r['autor_removido'] == true) {
      return r['fracao'] == null
          ? 'Residente removido'
          : 'Residente removido, fração ${r['fracao']}';
    }
    final nome = r['autor_nome'] as String? ?? 'Residente';
    final fracao = r['fracao'] as String?;
    return fracao == null ? nome : '$nome, fração $fracao';
  }

  @override
  Widget build(BuildContext context) {
    final r = _reporte;
    return Scaffold(
      appBar: AppBar(title: const Text('Reporte')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_erro!),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _load,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : r == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  r['descricao'] as String? ?? '',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Chip(label: Text(_estado(r['estado']))),
                if (_foto != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    label: r['foto_alt'] as String? ?? 'Foto do reporte',
                    image: true,
                    child: Image.memory(_foto!, fit: BoxFit.contain),
                  ),
                ] else if (r['foto_url'] != null) ...[
                  const Text('Foto indisponível.'),
                ],
                const SizedBox(height: 12),
                Text(_autor(r)),
                Text('Criado: ${_data(r['criado_em'])}'),
                Text('Atualizado: ${_data(r['atualizado_em'])}'),
                if (r['duplicado_de_id'] != null)
                  Text('Duplicado do #${r['duplicado_de_id']}'),
                const SizedBox(height: 24),
                Text(
                  'Histórico',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final item
                    in (r['historico'] as List<dynamic>? ?? []).reversed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history),
                    title: Text(
                      _estado((item as Map<String, dynamic>)['estado_novo']),
                    ),
                    subtitle: Text(
                      [
                        _data(item['criado_em']),
                        if ((item['nota'] as String?)?.isNotEmpty == true)
                          item['nota'] as String,
                      ].join('\n'),
                    ),
                  ),
              ],
            ),
    );
  }
}
