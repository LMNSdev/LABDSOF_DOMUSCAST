import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../local/queue_db.dart';
import '../services/api_service.dart';
import '../widgets/aviso_popup.dart';
import 'novo_reporte_screen.dart';

class ReportesListScreen extends StatefulWidget {
  final ApiService? api;
  final String? credencial;

  /// Nome do residente, passado ao formulário (US-09). Nulo para o administrador.
  final String? nomeResidente;

  /// O administrador não cria reportes (10.2), por isso não vê "Reportar avaria"
  /// nem envia a fila offline (daria 403).
  final bool podeReportar;
  final FilaReportes? fila;

  /// US-23: chamado quando a credencial do residente deixou de ser aceite (401).
  final VoidCallback? onAcessoRemovido;

  const ReportesListScreen({
    super.key,
    this.api,
    this.credencial,
    this.nomeResidente,
    this.podeReportar = true,
    this.fila,
    this.onAcessoRemovido,
  });

  @override
  State<ReportesListScreen> createState() => _ReportesListScreenState();
}

class _ReportesListScreenState extends State<ReportesListScreen> {
  late final ApiService _api = widget.api ?? ApiService();
  late final FilaReportes _fila = widget.fila ?? SqliteFilaReportes();
  final _avisoPopup = AvisoPopupController();
  List<Map<String, dynamic>> _reportes = [];
  bool _loading = true;
  bool _avisoVisivel = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _avisoPopup.dispose();
    super.dispose();
  }

  // Envia por ordem os reportes guardados offline; pára no primeiro falhanço.
  // A idempotency_key evita duplicados em reenvios.
  Future<void> _syncPending() async {
    if (!widget.podeReportar) return;
    final credencial = widget.credencial;
    if (credencial == null || credencial.isEmpty) return;
    final pending = await _fila.pendentes();
    for (final p in pending) {
      try {
        await _api.criarReporte(
          credencial: credencial,
          descricao: p['descricao'] as String,
          idempotencyKey: p['idempotency_key'] as String,
          mostrarNome: p['mostrar_nome'] == 1,
        );
        await _fila.remover(p['id'] as int);
      } on ApiException catch (erro) {
        if (erro.statusCode == 401 || erro.statusCode >= 500) return;
        await _fila.remover(p['id'] as int);
      } on http.ClientException {
        return;
      } on SocketException {
        return;
      } on HandshakeException {
        return;
      } on TimeoutException {
        return;
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _syncPending();
    try {
      final reportes = await _api.getReportes(credencial: widget.credencial);
      setState(() {
        _reportes = reportes;
        _loading = false;
      });
    } on ApiException catch (e) {
      final aoRemover = widget.onAcessoRemovido;
      if (e.statusCode == 401 && widget.podeReportar && aoRemover != null) {
        aoRemover();
        return;
      }
      setState(() {
        _error = e.statusCode == 401
            ? 'A sua identidade já não é válida.'
            : 'Não foi possível carregar os reportes.';
        _loading = false;
      });
    } on Exception {
      // Sem rede ou falha de ligação (inclui HandshakeException e TimeoutException).
      _semLigacao();
    }
  }

  void _semLigacao() {
    if (!mounted) return;
    setState(() {
      _error = 'Sem ligação ao servidor';
      _loading = false;
    });
  }

  ({Color bg, Color fg, String label, IconData icon}) _estadoStyle(
      String estado) {
    return switch (estado) {
      'resolvido' => (
          bg: const Color(0xFFE8F5E9),
          fg: const Color(0xFF2E7D32),
          label: 'Resolvido',
          icon: Icons.check_circle_outline,
        ),
      'em_curso' => (
          bg: const Color(0xFFFFF3E0),
          fg: const Color(0xFFE65100),
          label: 'Em curso',
          icon: Icons.autorenew,
        ),
      _ => (
          bg: const Color(0xFFFFEBEE),
          fg: const Color(0xFFC62828),
          label: 'Aberto',
          icon: Icons.error_outline,
        ),
    };
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? _buildError()
            : _reportes.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      itemCount: _reportes.length,
                      itemBuilder: (context, i) => _buildCard(_reportes[i]),
                    ),
                  );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        title: const Text(
          'Reportes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(top: _avisoVisivel ? 64 : 0),
        child: body,
      ),
      floatingActionButton: widget.podeReportar
          ? FloatingActionButton.extended(
              onPressed: () async {
                final criado = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NovoReporteScreen(
                      api: _api,
                      credencial: widget.credencial,
                      nome: widget.nomeResidente,
                      fila: _fila,
                    ),
                  ),
                );
                if (criado == true) {
                  if (!context.mounted) return;
                  await _load();
                  if (!context.mounted) return;
                  setState(() => _avisoVisivel = true);
                  _avisoPopup.show(
                    context,
                    'Reporte enviado. Estado: Aberto.',
                    cor: const Color(0xFF1C6B2C),
                    onDismiss: () {
                      if (mounted) setState(() => _avisoVisivel = false);
                    },
                  );
                }
              },
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              icon: const Icon(Icons.add),
              label: const Text('Reportar avaria'),
            )
          : null,
    );
  }

  /// US-09: o texto do autor depende do papel de quem vê (a API já filtra os dados).
  String _autorTexto(Map<String, dynamic> r, String data) {
    final mostrarNome = r['mostrar_nome'] as bool? ?? false;
    if (r['meu'] == true) {
      return mostrarNome
          ? 'O meu reporte - nome visível aos vizinhos'
          : 'O meu reporte - nome oculto aos vizinhos';
    }
    final autorNome = r['autor_nome'] as String?;
    final fracao = r['fracao'] as String?;
    final autor = r['autor_removido'] == true
        // US-23: só o administrador recebe a fração de um autor removido.
        ? (fracao != null ? 'Residente removido, fração $fracao' : 'Residente removido')
        : autorNome != null && fracao != null
            ? '$autorNome, fração $fracao'
            : (autorNome ?? 'Residente');
    return data.isEmpty ? autor : '$autor - $data';
  }

  Widget _buildCard(Map<String, dynamic> r) {
    final estado = r['estado'] as String? ?? 'aberto';
    final style = _estadoStyle(estado);
    final data = _formatDate(r['criado_em'] as String?);
    final nomeVisivelAoAdmin =
        r['fracao'] != null && r['mostrar_nome'] == true && r['autor_removido'] != true;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r['descricao'] as String? ?? '',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _autorTexto(r, data),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (nomeVisivelAoAdmin) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'nome visível',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: style.bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(style.icon, size: 13, color: style.fg),
                      const SizedBox(width: 4),
                      Text(
                        style.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: style.fg,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nenhum reporte ainda',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.podeReportar)
              Text(
                'Toque em "Reportar avaria" para submeter o primeiro.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
