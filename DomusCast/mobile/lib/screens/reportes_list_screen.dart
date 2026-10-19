import 'package:flutter/material.dart';
import '../local/queue_db.dart';
import '../services/api_service.dart';
import 'novo_reporte_screen.dart';

class ReportesListScreen extends StatefulWidget {
  const ReportesListScreen({super.key});

  @override
  State<ReportesListScreen> createState() => _ReportesListScreenState();
}

class _ReportesListScreenState extends State<ReportesListScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _reportes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Envia por ordem os reportes guardados offline; pára no primeiro falhanço.
  // A idempotency_key evita duplicados em reenvios.
  Future<void> _syncPending() async {
    try {
      final pending = await QueueDb.getPending();
      for (final p in pending) {
        await _api.criarReporte(
          descricao: p['descricao'] as String,
          fotoUrl: p['foto_url'] as String?,
          idempotencyKey: p['idempotency_key'] as String,
        );
        await QueueDb.remove(p['id'] as int);
      }
    } catch (_) {
      // Sem ligação ou fila indisponível: tenta de novo no próximo refresh.
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _syncPending();
    try {
      final reportes = await _api.getReportes();
      setState(() {
        _reportes = reportes;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Sem ligação ao servidor';
        _loading = false;
      });
    }
  }

  ({Color bg, Color fg, String label, IconData icon}) _estadoStyle(String estado) {
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _reportes.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        itemCount: _reportes.length,
                        itemBuilder: (context, i) => _buildCard(_reportes[i]),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NovoReporteScreen()),
          );
          _load();
        },
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Reportar avaria'),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> r) {
    final estado = r['estado'] as String? ?? 'aberto';
    final style = _estadoStyle(estado);
    final data = _formatDate(r['criado_em'] as String?);

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
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                const Spacer(),
                if (data.isNotEmpty)
                  Text(data, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
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
            Text(
              'Toca em "Reportar avaria" para submeter o primeiro.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
