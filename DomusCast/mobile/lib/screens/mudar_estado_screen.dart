import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../widgets/estado_badge.dart';

/// Estado seguinte permitido pela US-05 (Aberto -> Em curso -> Resolvido), ou
/// `null` se o reporte já está resolvido.
String? proximoEstado(String? estado) => switch (estado) {
  'aberto' => 'em_curso',
  'em_curso' => 'resolvido',
  _ => null,
};

/// US-05: o administrador avança o estado de um reporte e regista uma nota
/// (ecrãs 2 e 4 do wireframe).
///
/// Ao guardar, fecha e devolve o detalhe atualizado. Se a API não confirmou a
/// alteração, mostra a falha e só oferece voltar ao detalhe: um reenvio às cegas
/// podia repetir uma alteração que já ficou guardada. Não há fila offline.
class MudarEstadoScreen extends StatefulWidget {
  final ApiService api;
  final String credencial;
  final int reporteId;
  final String estadoAtual;

  const MudarEstadoScreen({
    super.key,
    required this.api,
    required this.credencial,
    required this.reporteId,
    required this.estadoAtual,
  });

  @override
  State<MudarEstadoScreen> createState() => _MudarEstadoScreenState();
}

class _MudarEstadoScreenState extends State<MudarEstadoScreen> {
  static const maxNota = 500;

  final _form = GlobalKey<FormState>();
  final _notaCtrl = TextEditingController();
  bool _aEnviar = false;
  bool _validarAoEscrever = false;

  /// Erro corrigível no formulário (422).
  String? _erroFormulario;

  /// Falha sem confirmação da API (ecrã 4): o formulário deixa de estar disponível.
  String? _falha;

  @override
  void dispose() {
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final novo = proximoEstado(widget.estadoAtual);
    if (_aEnviar || novo == null) return;
    if (!_form.currentState!.validate()) {
      // A partir daqui o formulário volta a validar a cada tecla: o aviso
      // «Escreva uma nota» desaparece (e deixa de ser lido) quando se escreve.
      setState(() => _validarAoEscrever = true);
      return;
    }
    setState(() {
      _aEnviar = true;
      _erroFormulario = null;
    });
    try {
      final detalhe = await widget.api.mudarEstado(
        credencial: widget.credencial,
        reporteId: widget.reporteId,
        estado: novo,
        nota: _notaCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(detalhe);
      return;
    } on ApiException catch (e) {
      if (e.statusCode == 422) {
        _mostrar(formulario: 'Verifique a nota: tem de ter entre 1 e $maxNota caracteres.');
        return;
      }
      _mostrar(falha: switch (e.statusCode) {
        409 => 'O reporte pode ter sido atualizado noutro dispositivo. '
            'Volte a carregar o detalhe antes de tentar novamente.',
        // 401: a credencial deixou de ser aceite (ex.: administrador removido).
        401 => 'A sua sessão já não é válida.',
        403 => 'Só o administrador pode mudar o estado de um reporte.',
        404 => 'O reporte já não existe.',
        _ => 'O serviço está indisponível. Volte ao detalhe e tente daqui a pouco.',
      });
    } on http.ClientException {
      _mostrar(falha: _semLigacao);
    } on SocketException {
      _mostrar(falha: _semLigacao);
    } on TimeoutException {
      _mostrar(falha: _semLigacao);
    } catch (_) {
      // Qualquer outra falha sem confirmação da API (ex.: HandshakeException num
      // Wi-Fi com portal, ou um proxy que devolve HTML e o jsonDecode falha):
      // a alteração pode ou não ter ficado guardada, e o botão não pode ficar
      // preso no indicador de carregamento.
      _mostrar(falha: _semLigacao);
    }
  }

  static const _semLigacao = 'Sem ligação. A alteração pode não ter sido guardada; '
      'volte ao detalhe para confirmar o estado antes de tentar novamente.';

  void _mostrar({String? formulario, String? falha}) {
    if (!mounted) return;
    setState(() {
      _aEnviar = false;
      _erroFormulario = formulario;
      _falha = falha;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Atualizar reporte')),
      body: SafeArea(child: _falha != null ? _ecraFalha(scheme) : _formulario(scheme)),
    );
  }

  static const _borda = Color(0xFFC6CFDF);
  static const _secundario = TextStyle(fontSize: 13, color: Color(0xFF5F6B7A));

  /// Caixa branca com borda dos ecrãs 2 e 4 do wireframe. Com [erro], fica a vermelho.
  Widget _caixa(ColorScheme scheme, String texto, {bool erro = false}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: erro ? scheme.errorContainer : Colors.white,
      border: Border.all(color: erro ? scheme.error : _borda),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      texto,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: erro ? scheme.onErrorContainer : null,
      ),
    ),
  );

  /// Junta tudo num só nó com região ativa, para o TalkBack ler a mensagem
  /// inteira, sozinho, quando aparece.
  Widget _anunciar(Widget child) =>
      MergeSemantics(child: Semantics(liveRegion: true, child: child));

  Widget _rotulo(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(texto, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
  );

  OutlineInputBorder _contorno(Color cor, [double largura = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: cor, width: largura),
  );

  Widget _ecraFalha(ColorScheme scheme) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      // A causa entra no mesmo anúncio: sem ela, o TalkBack só lia o título.
      _anunciar(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _caixa(scheme, 'Não foi possível guardar a alteração.'),
          const SizedBox(height: 12),
          Text(_falha!, style: _secundario),
        ],
      )),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Voltar ao detalhe'),
      ),
    ],
  );

  Widget _formulario(ColorScheme scheme) {
    final novo = proximoEstado(widget.estadoAtual);
    return Form(
      key: _form,
      autovalidateMode: _validarAoEscrever ? AutovalidateMode.always : AutovalidateMode.disabled,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_erroFormulario != null) ...[
            _anunciar(_caixa(scheme, _erroFormulario!, erro: true)),
            const SizedBox(height: 16),
          ],
          // Só há um estado seguinte possível; mostra-o sem permitir escolher outro.
          // O TalkBack lê o rótulo e o valor juntos.
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rotulo('Novo estado'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _borda),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.centerLeft,
                  child: novo == null
                      ? const Text('O reporte já está resolvido')
                      : EstadoBadge(novo, tamanho: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // O rótulo fica por cima da caixa, como no wireframe, e não dentro dela.
          // Juntá-lo ao campo faz o TalkBack anunciar «Nota obrigatória» no campo.
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rotulo('Nota obrigatória'),
                TextFormField(
                  controller: _notaCtrl,
                  maxLength: maxNota,
                  minLines: 3,
                  maxLines: 6,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Ex.: técnico contactado',
                    helperText: 'A nota fica visível no histórico.',
                    contentPadding: const EdgeInsets.all(14),
                    border: _contorno(_borda),
                    enabledBorder: _contorno(_borda),
                    focusedBorder: _contorno(scheme.primary, 2),
                    errorBorder: _contorno(scheme.error),
                    focusedErrorBorder: _contorno(scheme.error, 2),
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Escreva uma nota' : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _aEnviar || novo == null ? null : _guardar,
            child: _aEnviar
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      semanticsLabel: 'A guardar a alteração',
                    ),
                  )
                : const Text('Guardar alteração'),
          ),
        ],
      ),
    );
  }
}
