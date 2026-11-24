import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../local/reunioes_cache.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'nova_reuniao_screen.dart';

/// Separador "Reuniões".
///
/// Administrador (com [credencial]): lista das reuniões de hoje em diante, com o
/// estado da publicação no calendário (US-28), e "Agendar reunião" (US-13). Se a
/// API não responder, mostra a última lista guardada no telemóvel ([cache]).
/// Residente: por agora só o aviso; ver as reuniões é a US-27.
class ReunioesScreen extends StatelessWidget {
  final ApiService? api;
  final String? credencial;
  final CacheReunioes? cache;

  const ReunioesScreen({super.key, this.api, this.credencial, this.cache});

  @override
  Widget build(BuildContext context) {
    final api = this.api;
    final credencial = this.credencial;
    if (api != null && credencial != null) {
      return _ReunioesAdmin(api: api, credencial: credencial, cache: cache);
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
                  textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 16)),
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
      'sincronizada' => 'Sincronizada com o calendário',
      'alternativo' => 'Serviço externo indisponível. Disponível no feed iCal.',
      _ => 'Publicação pendente',
    };

/// Enquanto houver reuniões pendentes ou a API não responder, a lista volta a
/// ser pedida com este intervalo.
const intervaloAtualizacao = Duration(seconds: 30);

bool _publicacaoPendente(Map<String, dynamic> r) =>
    !const {'sincronizada', 'alternativo'}.contains(r['estado_sync']);

class _ReunioesAdmin extends StatefulWidget {
  final ApiService api;
  final String credencial;
  final CacheReunioes? cache;

  const _ReunioesAdmin({required this.api, required this.credencial, this.cache});

  @override
  State<_ReunioesAdmin> createState() => _ReunioesAdminState();
}

class _ReunioesAdminState extends State<_ReunioesAdmin> {
  late final CacheReunioes _cache = widget.cache ?? SqliteCacheReunioes();
  List<Map<String, dynamic>> _reunioes = [];
  bool _aCarregar = true;
  String? _erro;

  /// A API não respondeu e a lista vem do telemóvel (ecrã 4 do wireframe).
  bool _guardadas = false;
  Timer? _atualizacao;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _atualizacao?.cancel();
    super.dispose();
  }

  Future<void> _carregar({bool silencioso = false}) async {
    _atualizacao?.cancel();
    if (!silencioso) {
      setState(() {
        _aCarregar = true;
        _erro = null;
      });
    }
    try {
      final reunioes = await widget.api.getReunioes(widget.credencial);
      if (!mounted) return;
      setState(() {
        _reunioes = reunioes;
        _guardadas = false;
        _erro = null;
        _aCarregar = false;
      });
      await _cache.guardar(reunioes);
    } on http.ClientException {
      await _semApi();
    } on SocketException {
      await _semApi();
    } on ApiException catch (e) {
      if (e.statusCode >= 500) {
        await _semApi();
      } else {
        _mostrarErro();
      }
    }
    if (mounted && (_guardadas || _reunioes.any(_publicacaoPendente))) {
      _atualizacao = Timer(intervaloAtualizacao, () => _carregar(silencioso: true));
    }
  }

  Future<void> _semApi() async {
    final guardadas = await _cache.ler();
    if (!mounted) return;
    if (guardadas == null || guardadas.isEmpty) {
      _mostrarErro();
      return;
    }
    setState(() {
      _reunioes = guardadas;
      _guardadas = true;
      _erro = null;
      _aCarregar = false;
    });
  }

  void _mostrarErro() {
    if (!mounted) return;
    setState(() {
      _erro = 'Não foi possível carregar as reuniões.';
      _guardadas = false;
      _aCarregar = false;
    });
  }

  Future<void> _agendar() async {
    final criada = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => NovaReuniaoScreen(api: widget.api, credencial: widget.credencial),
    ));
    if (criada != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reunião agendada.')));
    await _carregar();
  }

  Widget _caixa(IconData icone, String texto, Color fundo, Color cor) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(icone, size: 18, color: cor),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: TextStyle(color: cor))),
        ]),
      );

  Widget _estado(String? estado) => switch (estado) {
        'sincronizada' =>
          _caixa(Icons.event_available, estadoPublicacao(estado), sucessoFundo, sucessoTexto),
        'alternativo' =>
          _caixa(Icons.warning_amber_rounded, estadoPublicacao(estado), avisoFundo, avisoTexto),
        _ => _caixa(Icons.schedule, estadoPublicacao(estado), avisoFundo, avisoTexto),
      };

  Widget _nota(ColorScheme scheme, String texto) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Text(texto, style: TextStyle(color: scheme.onSurfaceVariant)),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget corpo;
    if (_aCarregar) {
      corpo = const Center(child: CircularProgressIndicator());
    } else if (_erro != null) {
      corpo = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_erro!, textAlign: TextAlign.center),
          TextButton(onPressed: _carregar, child: const Text('Tentar novamente')),
        ]),
      );
    } else if (_reunioes.isEmpty) {
      corpo = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.event_outlined, size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Ainda não há reuniões agendadas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16)),
          ]),
        ),
      );
    } else {
      corpo = RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_guardadas)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _caixa(
                  Icons.cloud_off,
                  'Não foi possível atualizar. A mostrar dados guardados no dispositivo.',
                  avisoFundo,
                  avisoTexto,
                ),
              ),
            for (final r in _reunioes)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Assembleia de condóminos',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${formatarReuniao(r['data_hora'] as String)}\n${r['local']}',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                    // Com a lista guardada, o estado pode já não ser o atual.
                    if (!_guardadas) _estado(r['estado_sync'] as String?),
                  ]),
                ),
              ),
            if (_guardadas)
              _nota(scheme, 'A sincronização será tentada quando houver ligação.')
            else ...[
              if (_reunioes.any(_publicacaoPendente)) _nota(scheme, 'A sincronização é automática.'),
              if (_reunioes.any((r) => r['estado_sync'] == 'alternativo'))
                _nota(scheme, 'A API mantém os dados da reunião.'),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reuniões')),
      body: corpo,
      bottomNavigationBar: _aCarregar
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: FilledButton.icon(
                  onPressed: _agendar,
                  icon: const Icon(Icons.add),
                  label: const Text('Agendar reunião'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ),
    );
  }
}
