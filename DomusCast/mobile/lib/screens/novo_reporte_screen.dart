import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../local/queue_db.dart';

class NovoReporteScreen extends StatefulWidget {
  final String? credencial;

  /// Nome do residente, para explicar o que os vizinhos veem com a opção ligada (US-09).
  final String? nome;
  final ApiService? api;
  final FilaReportes? fila;

  const NovoReporteScreen({super.key, this.credencial, this.nome, this.api, this.fila});

  @override
  State<NovoReporteScreen> createState() => _NovoReporteScreenState();
}

class _NovoReporteScreenState extends State<NovoReporteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  late final ApiService _api = widget.api ?? ApiService();
  late final FilaReportes _fila = widget.fila ?? SqliteFilaReportes();
  bool _submitting = false;
  bool _mostrarNome = false;

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  String _generateIdempotencyKey() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _mensagemErro(int status) => switch (status) {
        401 => 'A sua identidade já não é válida. Leia de novo o QR code da fração.',
        403 => 'Só os residentes podem reportar avarias.',
        422 => 'Verifique a descrição do reporte.',
        _ => 'Não foi possível enviar o reporte. Tente de novo.',
      };

  String get _notaNome => _mostrarNome
      ? 'Ligado: os vizinhos veem "${widget.nome ?? 'o seu nome'}". A fração continua escondida.'
      : 'Desligado: os vizinhos veem "Residente". O administrador vê sempre o seu nome e fração.';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final descricao = _descricaoController.text.trim();
    final idempotencyKey = _generateIdempotencyKey();

    try {
      await _api.criarReporte(
        descricao: descricao,
        idempotencyKey: idempotencyKey,
        mostrarNome: _mostrarNome,
        credencial: widget.credencial,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte enviado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      // Servidor em baixo: como sem rede, guarda e reenvia mais tarde (ADR-006).
      if (e.statusCode >= 500) {
        await _guardarOffline(
          descricao,
          idempotencyKey,
          mensagem: 'Servidor indisponível - reporte guardado para envio posterior',
        );
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mensagemErro(e.statusCode))),
        );
      }
    } on Exception {
      // Sem rede ou falha de ligação (ClientException, SocketException, HandshakeException,
      // TimeoutException...): guarda e reenvia mais tarde, como antes da US-09.
      await _guardarOffline(descricao, idempotencyKey);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _guardarOffline(
    String descricao,
    String idempotencyKey, {
    String mensagem = 'Sem ligação - reporte guardado para envio posterior',
  }) async {
    await _fila.guardar(
      descricao: descricao,
      idempotencyKey: idempotencyKey,
      mostrarNome: _mostrarNome,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(mensagem)),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
      ),
    );
    Navigator.pop(context);
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
        title: const Text('Nova avaria', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                margin: EdgeInsets.zero,
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.report_problem_outlined, color: scheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Descrição do problema',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descricaoController,
                        decoration: const InputDecoration(
                          hintText: 'Ex: Torneira com fuga no 1.º andar, corredor direito...',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFFAFAFA),
                          counterText: '',
                        ),
                        maxLines: 5,
                        maxLength: 2000,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'A descrição é obrigatória' : null,
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_descricaoController.text.length}/2000',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // SwitchListTile já expõe o título e o estado ao leitor de ecrã.
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Mostrar o meu nome neste reporte'),
                        subtitle: Text(_notaNome),
                        value: _mostrarNome,
                        onChanged: (value) => setState(() => _mostrarNome = value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'O teu reporte é visível a todos os residentes. Não incluas dados pessoais de terceiros.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF795548)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_submitting ? 'A enviar...' : 'Submeter reporte'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
