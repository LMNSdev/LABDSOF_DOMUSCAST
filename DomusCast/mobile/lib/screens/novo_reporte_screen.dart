import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../widgets/aviso_popup.dart';

class NovoReporteScreen extends StatefulWidget {
  final ApiService api;
  final String? credencialResidente;
  final Future<XFile?> Function(ImageSource source)? escolherImagem;

  const NovoReporteScreen({
    super.key,
    required this.api,
    this.credencialResidente,
    this.escolherImagem,
  });

  @override
  State<NovoReporteScreen> createState() => _NovoReporteScreenState();
}

class _NovoReporteScreenState extends State<NovoReporteScreen> {
  static const _maxFotoBytes = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _fotoAltController = TextEditingController();
  final _avisoPopup = AvisoPopupController();
  Uint8List? _fotoBytes;
  String? _fotoNome;
  String? _idempotencyKey;
  String? _erroSubmissao;
  bool _mostrarNome = false;
  bool _submitting = false;
  bool _mostrarNome = false;

  @override
  void dispose() {
    _avisoPopup.dispose();
    _descricaoController.dispose();
    _fotoAltController.dispose();
    super.dispose();
  }

  String _generateIdempotencyKey() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  void _changed() {
    _idempotencyKey = null;
    _erroSubmissao = null;
    setState(() {});
  }

  void _mostrarMensagem(String texto, {Color? cor}) {
    _avisoPopup.show(
      context,
      texto,
      cor: cor ?? const Color(0xFFB26A00),
    );
  }

  Future<void> _selecionarFoto() async {
    try {
      final fonte = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Escolher da galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Tirar fotografia'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );
      if (fonte == null) return;

      final escolherImagem = widget.escolherImagem ??
          ((ImageSource source) => ImagePicker().pickImage(source: source));
      final foto = await escolherImagem(fonte);
      if (foto == null) return;

      final tamanho = await foto.length();
      if (tamanho > _maxFotoBytes) {
        _mostrarMensagem('A foto não pode exceder 5 MB.');
        return;
      }

      final extensao = foto.name.split('.').last.toLowerCase();
      final tipo = foto.mimeType?.toLowerCase();
      final extensaoValidada = switch (tipo) {
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        _ when extensao == 'jpg' || extensao == 'jpeg' => 'jpg',
        _ when extensao == 'png' => 'png',
        _ => null,
      };
      if (extensaoValidada == null) {
        _mostrarMensagem('Escolhe uma imagem JPEG ou PNG.');
        return;
      }

      final bytes = await foto.readAsBytes();
      setState(() {
        _fotoBytes = bytes;
        _fotoNome = 'foto.$extensaoValidada';
        _idempotencyKey = null;
        _erroSubmissao = null;
      });
    } on FileSystemException {
      _mostrarMensagem('Não foi possível ler a foto. Escolhe-a novamente.');
    } on PlatformException {
      _mostrarMensagem('Não foi possível abrir a câmara ou galeria.');
    }
  }

  Future<void> _verFoto() async {
    final bytes = _fotoBytes;
    if (bytes == null) return;

    final descricao = _fotoAltController.text.trim();
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Pré-visualização da foto'),
            actions: [
              IconButton(
                tooltip: 'Fechar pré-visualização',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                semanticLabel:
                    descricao.isEmpty ? 'Foto do reporte' : descricao,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _removerFoto() {
    setState(() {
      _fotoBytes = null;
      _fotoNome = null;
      _fotoAltController.clear();
      _idempotencyKey = null;
      _erroSubmissao = null;
    });
  }

  String _mensagemApi(ApiException erro) {
    return switch (erro.statusCode) {
      401 =>
        'A tua identificação expirou ou não é válida. Volta a identificar-te.',
      403 => 'Só residentes podem submeter reportes.',
      422 => erro.mensagem ?? 'Verifica a descrição e os dados da foto.',
      >= 500 =>
        'O servidor está temporariamente indisponível. Tenta novamente.',
      _ => erro.mensagem ?? 'Não foi possível submeter o reporte.',
    };
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    final credencial = widget.credencialResidente?.trim();
    if (credencial == null || credencial.isEmpty) {
      _mostrarMensagem(
        'Identifica-te através do QR code da fração antes de submeter um reporte.',
      );
      return;
    }

    setState(() => _submitting = true);
    _idempotencyKey ??= _generateIdempotencyKey();

    try {
      await widget.api.criarReporte(
        credencial: credencial,
        descricao: _descricaoController.text.trim(),
        fotoBytes: _fotoBytes,
        fotoNome: _fotoNome,
        fotoAlt: _fotoBytes == null ? null : _fotoAltController.text.trim(),
        mostrarNome: _mostrarNome,
        idempotencyKey: _idempotencyKey!,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ApiException catch (erro) {
      if (mounted) _mostrarErroSubmissao(_mensagemApi(erro));
    } on http.ClientException {
      if (mounted) {
        _mostrarErroSubmissao(
          'Sem ligação ao servidor. Os dados ficam no formulário; tenta novamente.',
        );
      }
    } on SocketException {
      if (mounted) {
        _mostrarErroSubmissao(
          'Sem ligação ao servidor. Os dados ficam no formulário; tenta novamente.',
        );
      }
    } on FormatException {
      if (mounted) {
        _mostrarErroSubmissao(
          'O servidor devolveu uma resposta inválida. Os dados ficam no formulário; tenta novamente.',
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

  void _mostrarErroSubmissao(String texto) {
    setState(() => _erroSubmissao = texto);
    _mostrarMensagem(texto);
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
        title: const Text('Nova avaria',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.report_problem_outlined,
                              color: scheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Descrição do problema',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: scheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descricaoController,
                        decoration: const InputDecoration(
                          hintText:
                              'Ex: Torneira com fuga no 1.º andar, corredor direito...',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFFAFAFA),
                          counterText: '',
                        ),
                        maxLines: 5,
                        maxLength: 2000,
                        autofocus: true,
                        onChanged: (_) => _changed(),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'A descrição é obrigatória'
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_descricaoController.text.length}/2000',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
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
              OutlinedButton.icon(
                onPressed: _submitting ? null : _selecionarFoto,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(_fotoBytes == null
                    ? 'Adicionar foto (opcional)'
                    : 'Alterar foto'),
              ),
              if (_fotoBytes != null) ...[
                const SizedBox(height: 8),
                Semantics(
                  button: true,
                  label: 'Ampliar foto',
                  hint: 'Abre a foto em ecrã inteiro. Pode ampliar com gestos.',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('foto-preview'),
                      onTap: _verFoto,
                      borderRadius: BorderRadius.circular(10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: double.infinity,
                          height: 180,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              const ColoredBox(color: Color(0xFFE8EAF0)),
                              ExcludeSemantics(
                                child: Center(
                                  child: Image.memory(
                                    _fotoBytes!,
                                    width: double.infinity,
                                    height: 180,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Text(
                                        'Pré-visualização indisponível',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.zoom_out_map,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _submitting ? null : _removerFoto,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remover foto'),
                  ),
                ),
                TextFormField(
                  controller: _fotoAltController,
                  decoration: const InputDecoration(
                    labelText: 'Descreve a foto (para leitores de ecrã)',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 300,
                  onChanged: (_) => _changed(),
                  validator: (value) => _fotoBytes != null &&
                          (value == null || value.trim().isEmpty)
                      ? 'Descreve a foto ou remove-a.'
                      : null,
                ),
              ],
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                title: const Text('Mostrar o meu nome neste reporte'),
                value: _mostrarNome,
                onChanged: _submitting
                    ? null
                    : (valor) => setState(() {
                          _mostrarNome = valor;
                          _idempotencyKey = null;
                        }),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: const Text(
                  'O reporte é visível a todos os residentes. Não incluas dados pessoais de terceiros.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF795548)),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                          semanticsLabel: 'A enviar reporte',
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_submitting ? 'A enviar...' : 'Submeter reporte'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              if (_submitting) ...[
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: const Text('A enviar o reporte. Aguarda.'),
                ),
              ],
              if (_erroSubmissao != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_erroSubmissao!),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _submitting ? null : _submit,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
