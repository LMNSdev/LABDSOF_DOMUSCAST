import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/sessao_admin.dart';
import 'fracao_qr_screen.dart';

/// US-01: o administrador consulta as frações e abre o QR code de cada uma.
class FracoesScreen extends StatefulWidget {
  final ApiService api;
  final SessaoAdmin sessao;

  const FracoesScreen({super.key, required this.api, required this.sessao});

  @override
  State<FracoesScreen> createState() => _FracoesScreenState();
}

class _FracoesScreenState extends State<FracoesScreen> {
  List<Map<String, dynamic>> _fracoes = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final f = await widget.api.getFracoes(widget.sessao.condominioId, widget.sessao.credencial);
      if (!mounted) return;
      setState(() {
        _fracoes = f;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Sem ligação ao servidor';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.sessao.nomeCondominio)),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _erro != null
                ? ListView(children: [
                    const SizedBox(height: 120),
                    Center(child: Text(_erro!)),
                    Center(
                      child: TextButton(onPressed: _carregar, child: const Text('Tentar de novo')),
                    ),
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _fracoes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final f = _fracoes[i];
                      final designacao = f['designacao'] as String;
                      final n = f['n_residentes'] as int;
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: scheme.primaryContainer,
                            foregroundColor: scheme.primary,
                            child: Text(designacao,
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                          title: Text('Fração $designacao',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(n == 1 ? '1 residente' : '$n residentes'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => FracaoQrScreen(
                              api: widget.api,
                              sessao: widget.sessao,
                              fracaoId: f['id'] as int,
                              designacao: designacao,
                            ),
                          )),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
