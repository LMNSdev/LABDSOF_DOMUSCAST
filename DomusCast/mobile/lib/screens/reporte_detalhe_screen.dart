import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/estado_badge.dart';
import 'mudar_estado_screen.dart';

class ReporteDetalheScreen extends StatefulWidget {
  final ApiService api;
  final String? credencial;
  final int reporteId;
  final VoidCallback? onAcessoRemovido;

  /// US-05: só o administrador vê «Mudar estado».
  final bool podeMudarEstado;

  const ReporteDetalheScreen({
    super.key,
    required this.api,
    required this.reporteId,
    this.credencial,
    this.onAcessoRemovido,
    this.podeMudarEstado = false,
  });

  @override
  State<ReporteDetalheScreen> createState() => _ReporteDetalheScreenState();
}

class _ReporteDetalheScreenState extends State<ReporteDetalheScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _reporte;
  Uint8List? _foto;
  String? _fotoCarregadaUrl;
  String? _fotoAltCarregado;
  String? _erro;
  bool _loading = true;
  bool _refreshing = false;
  Timer? _timer;

  /// Ecrã 3 do wireframe: confirmação depois de a API guardar a alteração.
  bool _alteracaoGuardada = false;

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
      final fotoUrl = reporte['foto_url'] as String?;
      Uint8List? novaFoto;
      if (fotoUrl != null && (_foto == null || _fotoCarregadaUrl != fotoUrl)) {
        try {
          novaFoto = await widget.api.getReporteFoto(
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
        if (fotoUrl == null) {
          _foto = null;
          _fotoCarregadaUrl = null;
          _fotoAltCarregado = null;
        } else if (novaFoto != null) {
          _foto = novaFoto;
          _fotoCarregadaUrl = fotoUrl;
          _fotoAltCarregado = reporte['foto_alt'] as String?;
        }
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

  /// US-05: abre «Atualizar reporte» e, se a API confirmou, mostra logo o novo
  /// estado e histórico. Sem confirmação, volta a carregar o detalhe.
  Future<void> _mudarEstado(Map<String, dynamic> reporte) async {
    _timer?.cancel();
    _timer = null;
    final atualizado = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => MudarEstadoScreen(
          api: widget.api,
          credencial: widget.credencial!,
          reporteId: widget.reporteId,
          estadoAtual: reporte['estado'] as String,
        ),
      ),
    );
    if (!mounted) return;
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
    if (atualizado == null) {
      await _load();
      return;
    }
    setState(() {
      _reporte = atualizado;
      _alteracaoGuardada = true;
    });
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
      appBar: AppBar(title: Text('Reporte #${widget.reporteId}')),
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Text(
                  r['descricao'] as String? ?? '',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: EstadoBadge(r['estado'] as String?, tamanho: 14),
                ),
                if (_foto != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    label: _fotoAltCarregado ?? 'Foto do reporte',
                    image: true,
                    child: Image.memory(_foto!, fit: BoxFit.contain),
                  ),
                ] else if (r['foto_url'] != null) ...[
                  const Text('Foto indisponível.'),
                ],
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _autor(r),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Criado: ${_data(r['criado_em'])}',
                          style: _secundario,
                        ),
                        Text(
                          'Atualizado: ${_data(r['atualizado_em'])}',
                          style: _secundario,
                        ),
                        if (r['duplicado_de_id'] != null)
                          Text('Duplicado do #${r['duplicado_de_id']}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  header: true,
                  child: Text(
                    'Histórico',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final item
                    in (r['historico'] as List<dynamic>? ?? []).reversed)
                  _EntradaHistorico(
                    estado: _estado((item as Map<String, dynamic>)['estado_novo']),
                    quando: item['estado_anterior'] == null &&
                            item['autor_tipo'] == 'sistema'
                        ? '${_data(item['criado_em'])}, estado inicial'
                        : _data(item['criado_em']),
                    nota: item['nota'] as String?,
                  ),
                if (_alteracaoGuardada)
                  Semantics(
                    liveRegion: true,
                    child: const Text(
                      'Alteração guardada. O histórico não pode ser editado.',
                      style: _secundario,
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: r != null &&
              _erro == null &&
              widget.podeMudarEstado &&
              widget.credencial != null &&
              proximoEstado(r['estado'] as String?) != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: FilledButton(
                  onPressed: () => _mudarEstado(r),
                  child: const Text('Mudar estado'),
                ),
              ),
            )
          : null,
    );
  }
}

const _secundario = TextStyle(fontSize: 13, color: Color(0xFF5F6B7A));

/// Uma entrada do histórico com a linha à esquerda do wireframe (ecrãs 1 e 3).
/// O TalkBack lê o estado, a data e a nota de uma só vez.
class _EntradaHistorico extends StatelessWidget {
  final String estado;
  final String quando;
  final String? nota;

  const _EntradaHistorico({
    required this.estado,
    required this.quando,
    this.nota,
  });

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFF9AA7BF), width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            estado,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(quando, style: _secundario),
          if (nota?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(nota!),
          ],
        ],
      ),
    ),
  );
}
