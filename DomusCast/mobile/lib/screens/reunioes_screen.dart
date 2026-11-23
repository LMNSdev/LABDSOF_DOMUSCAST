import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'ata_screen.dart';
import 'nova_reuniao_screen.dart';

/// Separador "Reuniões".
///
/// Administrador (com [credencial]): lista das reuniões de hoje em diante, com o
/// estado da publicação no calendário, e "Agendar reunião" (US-13).
/// Residente: por agora só o aviso; ver as reuniões é a US-27.
class ReunioesScreen extends StatelessWidget {
  final ApiService? api;
  final String? credencial;

  const ReunioesScreen({super.key, this.api, this.credencial});

  @override
  Widget build(BuildContext context) {
    final api = this.api;
    final credencial = this.credencial;
    if (api != null && credencial != null) {
      return _ReunioesAdmin(api: api, credencial: credencial);
    }
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
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

/// "25/11/2026 às 19:00", na hora local.
String formatarReuniao(String iso) {
  final d = DateTime.parse(iso).toLocal();
  String dois(int v) => v.toString().padLeft(2, '0');
  return '${formatarData(d)} às ${dois(d.hour)}:${dois(d.minute)}';
}

/// Estado da publicação no calendário externo (US-28), visível ao administrador.
String estadoPublicacao(String? estado) => switch (estado) {
      'sincronizada' => 'Publicada no calendário',
      'alternativo' => 'Calendário externo indisponível: só no feed iCal',
      _ => 'Publicação no calendário pendente',
    };

class _ReunioesAdmin extends StatefulWidget {
  final ApiService api;
  final String credencial;

  const _ReunioesAdmin({required this.api, required this.credencial});

  @override
  State<_ReunioesAdmin> createState() => _ReunioesAdminState();
}

class _ReunioesAdminState extends State<_ReunioesAdmin> {
  List<Map<String, dynamic>> _reunioes = [];
  bool _aCarregar = true;
  String? _erro;
  bool _incluirPassadas = false;

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
      final reunioes = await widget.api.getReunioes(
        widget.credencial,
        incluirPassadas: _incluirPassadas,
      );
      if (!mounted) return;
      setState(() {
        _reunioes = reunioes;
        _aCarregar = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar as reuniões.';
        _aCarregar = false;
      });
    }
  }

  Future<void> _agendar() async {
    final criada = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) =>
          NovaReuniaoScreen(api: widget.api, credencial: widget.credencial),
    ));
    if (criada != true || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Reunião agendada.')));
    await _carregar();
  }

  Future<void> _abrirAta(Map<String, dynamic> reuniao) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => AtaScreen(
        api: widget.api,
        credencial: widget.credencial,
        reuniao: reuniao,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget lista;
    if (_aCarregar) {
      lista = const Center(child: CircularProgressIndicator());
    } else if (_erro != null) {
      lista = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_erro!, textAlign: TextAlign.center),
          TextButton(
              onPressed: _carregar, child: const Text('Tentar novamente')),
        ]),
      );
    } else if (_reunioes.isEmpty) {
      lista = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.event_outlined,
                size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
                _incluirPassadas
                    ? 'Ainda não há reuniões.'
                    : 'Ainda não há reuniões agendadas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16)),
          ]),
        ),
      );
    } else {
      lista = RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final r in _reunioes)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: const Text('Assembleia de condóminos',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${formatarReuniao(r['data_hora'] as String)}\n'
                    '${r['local']}\n'
                    '${estadoPublicacao(r['estado_sync'] as String?)}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _abrirAta(r),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reuniões')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mostrar reuniões passadas'),
            value: _incluirPassadas,
            onChanged: (valor) {
              setState(() => _incluirPassadas = valor);
              _carregar();
            },
          ),
        ),
        Expanded(child: lista),
      ]),
      bottomNavigationBar: _aCarregar
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: FilledButton.icon(
                  onPressed: _agendar,
                  icon: const Icon(Icons.add),
                  label: const Text('Agendar reunião'),
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ),
    );
  }
}
