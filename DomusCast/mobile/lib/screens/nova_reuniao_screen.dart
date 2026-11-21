import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';

/// Escolhe a data ou a hora; substituído nos testes, onde os seletores não se usam.
typedef EscolherData = Future<DateTime?> Function(BuildContext context, DateTime inicial);
typedef EscolherHora = Future<TimeOfDay?> Function(BuildContext context, TimeOfDay inicial);

String _dois(int v) => v.toString().padLeft(2, '0');

/// "25/11/2026".
String formatarData(DateTime d) => '${_dois(d.day)}/${_dois(d.month)}/${d.year}';

/// US-13: o administrador agenda uma assembleia com data, hora e local (ecrãs 1 e 4
/// do wireframe). A hora é a do telemóvel (Portugal) e vai para a API em UTC.
///
/// Sem ligação, a reunião não fica guardada: a fila local é da US-18, por isso o
/// ecrã não diz que ficou em fila. Devolve `true` ao fechar se a reunião foi criada.
class NovaReuniaoScreen extends StatefulWidget {
  final ApiService api;
  final String credencial;
  final EscolherData? escolherData;
  final EscolherHora? escolherHora;

  const NovaReuniaoScreen({
    super.key,
    required this.api,
    required this.credencial,
    this.escolherData,
    this.escolherHora,
  });

  @override
  State<NovaReuniaoScreen> createState() => _NovaReuniaoScreenState();
}

class _NovaReuniaoScreenState extends State<NovaReuniaoScreen> {
  final _form = GlobalKey<FormState>();
  final _dataCtrl = TextEditingController();
  final _horaCtrl = TextEditingController();
  final _localCtrl = TextEditingController();
  DateTime? _data;
  TimeOfDay? _hora;
  bool _aEnviar = false;
  String? _erro;
  bool _erroDeLigacao = false;

  @override
  void dispose() {
    _dataCtrl.dispose();
    _horaCtrl.dispose();
    _localCtrl.dispose();
    super.dispose();
  }

  DateTime? get _dataHora {
    final data = _data;
    final hora = _hora;
    if (data == null || hora == null) return null;
    return DateTime(data.year, data.month, data.day, hora.hour, hora.minute);
  }

  Future<void> _escolherData() async {
    final hoje = DateTime.now();
    final escolher = widget.escolherData ??
        (ctx, inicial) => showDatePicker(
              context: ctx,
              initialDate: inicial,
              firstDate: DateTime(hoje.year, hoje.month, hoje.day),
              lastDate: DateTime(hoje.year + 5),
              helpText: 'Data da reunião',
            );
    final data = await escolher(context, _data ?? hoje);
    if (data == null || !mounted) return;
    setState(() {
      _data = data;
      _dataCtrl.text = formatarData(data);
    });
  }

  Future<void> _escolherHora() async {
    final escolher = widget.escolherHora ??
        (ctx, inicial) => showTimePicker(
              context: ctx,
              initialTime: inicial,
              helpText: 'Hora da reunião',
            );
    final hora = await escolher(context, _hora ?? const TimeOfDay(hour: 19, minute: 0));
    if (hora == null || !mounted) return;
    setState(() {
      _hora = hora;
      _horaCtrl.text = '${_dois(hora.hour)}:${_dois(hora.minute)}';
    });
  }

  String? _validarHora(String? _) {
    if (_hora == null) return 'Escolha a hora';
    final dataHora = _dataHora;
    if (dataHora != null && !dataHora.isAfter(DateTime.now())) {
      return 'A reunião tem de ser no futuro';
    }
    return null;
  }

  Future<void> _agendar() async {
    if (_aEnviar || !_form.currentState!.validate()) return;
    setState(() {
      _aEnviar = true;
      _erro = null;
      _erroDeLigacao = false;
    });
    try {
      await widget.api.agendarReuniao(
        credencial: widget.credencial,
        dataHora: _dataHora!,
        local: _localCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    } on ApiException catch (e) {
      _mostrarErro(switch (e.statusCode) {
        422 => 'Verifique a data e o local. A reunião tem de ser no futuro.',
        401 || 403 => 'Só o administrador pode agendar reuniões.',
        _ => 'O serviço está indisponível. Tente novamente daqui a pouco.',
      });
    } on http.ClientException {
      _mostrarErro(null);
    } on SocketException {
      _mostrarErro(null);
    } on TimeoutException {
      _mostrarErro(null);
    }
  }

  /// Sem [mensagem], é o erro de rede do ecrã 4 do wireframe.
  void _mostrarErro(String? mensagem) {
    if (!mounted) return;
    setState(() {
      _aEnviar = false;
      _erroDeLigacao = mensagem == null;
      _erro = mensagem ?? 'Não foi possível guardar a reunião. Verifique a ligação.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Nova reunião')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_erro != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: scheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(_erro!, style: TextStyle(color: scheme.onErrorContainer)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _CampoSeletor(
                onTap: _escolherData,
                child: TextFormField(
                  controller: _dataCtrl,
                  readOnly: true,
                  onTap: _escolherData,
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  validator: (_) => _data == null ? 'Escolha a data' : null,
                ),
              ),
              const SizedBox(height: 16),
              _CampoSeletor(
                onTap: _escolherHora,
                child: TextFormField(
                  controller: _horaCtrl,
                  readOnly: true,
                  onTap: _escolherHora,
                  decoration: const InputDecoration(
                    labelText: 'Hora (Portugal continental)',
                    suffixIcon: Icon(Icons.schedule_outlined),
                  ),
                  validator: _validarHora,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _localCtrl,
                maxLength: 200,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Local'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Indique o local' : null,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _aEnviar ? null : _agendar,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _aEnviar
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'A agendar a reunião',
                        ),
                      )
                    : Text(_erroDeLigacao ? 'Tentar novamente' : 'Agendar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo só de leitura que abre um seletor. O Flutter não expõe o toque de um
/// `TextField` com `readOnly` ao leitor de ecrã; aqui fica no mesmo nó que o rótulo.
class _CampoSeletor extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _CampoSeletor({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) =>
      MergeSemantics(child: Semantics(button: true, onTap: onTap, child: child));
}
