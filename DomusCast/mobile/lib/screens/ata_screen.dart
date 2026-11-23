import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import 'reunioes_screen.dart' show formatarReuniao;

/// Limite do texto da ata, igual ao da API (`MAX_TEXTO_ATA`, provisório na DoR da US-24).
const kMaxTextoAta = 20000;

/// US-24: o administrador revê, edita e aprova a ata de uma reunião.
///
/// Segue o wireframe `docs/sprintB/design/us-24.html`:
/// 1. Rever: rascunho "Gerado por IA. Pendente de revisão." e a transcrição.
/// 2. Editar: "Guardar rascunho" e "Aprovar ata" são ações distintas.
/// 3. Confirmação antes de publicar.
/// 4. Publicada: fica só o texto aprovado.
///
/// US-25 (`docs/sprintB/design/us-25.html`): sem ata, ou com a transcrição falhada,
/// o administrador escreve uma ata manual, que segue o mesmo fluxo de aprovação e
/// fica identificada como manual.
///
/// O envio do áudio e o acompanhamento da transcrição são da US-10; aqui só se
/// mostra o estado. Os residentes não chegam a este ecrã (a ata publicada chega-lhes
/// pela US-26) e a API nunca lhes devolve rascunhos.
class AtaScreen extends StatefulWidget {
  final ApiService api;
  final String credencial;

  /// A reunião, tal como vem de `GET /reunioes`: `{id, data_hora, local, ...}`.
  final Map<String, dynamic> reuniao;

  const AtaScreen({
    super.key,
    required this.api,
    required this.credencial,
    required this.reuniao,
  });

  @override
  State<AtaScreen> createState() => _AtaScreenState();
}

enum _Modo { aCarregar, erroAoCarregar, semAta, ver, editar }

class _AtaScreenState extends State<AtaScreen> {
  final _texto = TextEditingController();

  _Modo _modo = _Modo.aCarregar;
  Map<String, dynamic>? _ata;
  String _erroAoCarregar = '';

  /// O rascunho tal como está guardado no servidor, para saber se há alterações.
  String _guardado = '';
  bool _aEnviar = false;
  String? _erro;

  int get _reuniaoId => widget.reuniao['id'] as int;
  bool get _temAlteracoes => _texto.text.trim() != _guardado;

  /// A ata é (ou vai ser) manual: já é manual, ainda não existe, ou a transcrição
  /// falhou. Nos dois últimos casos, guardar cria ou converte a ata em manual (US-25).
  bool get _manual =>
      _ata == null || _ata!['origem'] == 'manual' || _ata!['estado'] == 'falhou_transcricao';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _modo = _Modo.aCarregar;
      _erro = null;
    });
    try {
      final ata = await widget.api.getAta(_reuniaoId, widget.credencial);
      if (!mounted) return;
      setState(() {
        _ata = ata;
        _modo = _Modo.ver;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.statusCode == 404 && e.codigo == 'ata_inexistente') {
          _modo = _Modo.semAta;
        } else {
          _modo = _Modo.erroAoCarregar;
          _erroAoCarregar = e.statusCode == 404
              ? 'Esta reunião já não existe.'
              : 'Não foi possível carregar a ata.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _modo = _Modo.erroAoCarregar;
        _erroAoCarregar = 'Não foi possível carregar a ata. Verifique a ligação.';
      });
    }
  }

  /// Edita o rascunho guardado; numa reunião sem ata ou com a transcrição falhada,
  /// começa uma ata manual com o editor vazio (US-25).
  void _editar() {
    _guardado = (_ata?['rascunho'] as String?) ?? '';
    _texto.text = _guardado;
    setState(() {
      _modo = _Modo.editar;
      _erro = null;
    });
  }

  /// "Voltar" no editor: regressa à revisão; com alterações por guardar, pergunta antes.
  Future<void> _sairDoEditor() async {
    if (_aEnviar) return;
    if (_temAlteracoes) {
      final descartar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Descartar alterações?'),
          content: const Text('As alterações ao rascunho ainda não foram guardadas.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Continuar a editar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
      if (descartar != true || !mounted) return;
    }
    setState(() {
      // Sem ata guardada (a ata manual ainda não foi criada), volta ao "sem ata".
      _modo = _ata == null ? _Modo.semAta : _Modo.ver;
      _erro = null;
    });
  }

  /// Validação local, antes de chamar a API. A API valida o mesmo (422).
  bool _textoValido() {
    if (_texto.text.trim().isEmpty) {
      setState(() => _erro = 'Escreva o texto da ata antes de guardar.');
      return false;
    }
    return true;
  }

  Future<void> _guardar() async {
    if (_aEnviar || !_textoValido()) return;
    setState(() {
      _aEnviar = true;
      _erro = null;
    });
    try {
      final ata = await widget.api.guardarRascunhoAta(_reuniaoId, widget.credencial, _texto.text);
      if (!mounted) return;
      _aposGuardar(ata);
      setState(() => _aEnviar = false);
      _avisar('Rascunho guardado. Ainda não foi publicado.');
    } catch (e) {
      await _tratarErro(e);
    }
  }

  void _aposGuardar(Map<String, dynamic> ata) {
    _ata = ata;
    _guardado = (ata['rascunho'] as String?) ?? '';
  }

  Future<void> _aprovar() async {
    if (_aEnviar || !_textoValido()) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publicar ata?'),
        content: const Text(
          'A ata ficará visível aos residentes. Confirme que reviu as decisões e os dados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Voltar a rever'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Aprovar e publicar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    setState(() {
      _aEnviar = true;
      _erro = null;
    });
    try {
      // A API publica o rascunho guardado: as alterações por guardar vão primeiro.
      if (_temAlteracoes) {
        _aposGuardar(
          await widget.api.guardarRascunhoAta(_reuniaoId, widget.credencial, _texto.text),
        );
      }
      final ata = await widget.api.aprovarAta(_reuniaoId, widget.credencial);
      if (!mounted) return;
      setState(() {
        _ata = ata;
        _aEnviar = false;
        _modo = _Modo.ver;
      });
      _avisar('Ata aprovada e publicada aos residentes.');
    } catch (e) {
      await _tratarErro(e);
    }
  }

  /// Erros ao guardar ou aprovar. O texto fica sempre no editor, exceto se a ata
  /// já tiver sido aprovada (por outro administrador): aí mostra-se a publicada.
  Future<void> _tratarErro(Object e) async {
    if (!mounted) return;
    if (e is ApiException && e.statusCode == 409 && e.codigo == 'ata_ja_aprovada') {
      setState(() => _aEnviar = false);
      await _carregar();
      _avisar('Esta ata já tinha sido aprovada. As alterações não foram publicadas.');
      return;
    }
    final mensagem = switch (e) {
      ApiException(statusCode: 409, codigo: 'ata_em_processamento') =>
        'A transcrição ainda está em curso. Tente mais tarde.',
      ApiException(statusCode: 409) => 'Esta ata já não pode ser editada.',
      ApiException(statusCode: 422) =>
        'O texto da ata tem de ter entre 1 e $kMaxTextoAta caracteres.',
      ApiException(statusCode: 401 || 403) => 'Só o administrador pode rever e aprovar a ata.',
      ApiException(statusCode: 404, codigo: 'reuniao_nao_encontrada') =>
        'Esta reunião já não existe.',
      ApiException(statusCode: 404) => 'Esta ata já não existe.',
      http.ClientException() || SocketException() || TimeoutException() =>
        'Não foi possível guardar. O texto continua no editor. '
            'Verifique a ligação e tente novamente.',
      _ => 'O serviço está indisponível. O texto continua no editor. '
          'Tente novamente daqui a pouco.',
    };
    setState(() {
      _aEnviar = false;
      _erro = mensagem;
    });
  }

  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  String get _titulo => switch (_modo) {
        _Modo.editar when _manual => 'Ata manual',
        _Modo.editar => 'Editar ata',
        _Modo.ver when _ata?['estado'] == 'pendente_revisao' && _manual => 'Rever ata manual',
        _Modo.ver when _ata?['estado'] == 'pendente_revisao' => 'Rever ata',
        _Modo.ver when _ata?['estado'] == 'aprovada' => 'Ata aprovada',
        _ => 'Ata da assembleia',
      };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _modo != _Modo.editar,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _sairDoEditor();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_titulo)),
        body: SafeArea(child: _corpo()),
        bottomNavigationBar: _botoes(),
      ),
    );
  }

  Widget _corpo() {
    switch (_modo) {
      case _Modo.aCarregar:
        return const Center(
          child: CircularProgressIndicator(semanticsLabel: 'A carregar a ata'),
        );
      case _Modo.erroAoCarregar:
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_erroAoCarregar, textAlign: TextAlign.center),
            TextButton(onPressed: _carregar, child: const Text('Tentar novamente')),
          ]),
        );
      case _Modo.semAta:
        return _lista([
          const _Estado(
            texto: 'Esta reunião ainda não tem ata.',
            detalhe: 'Pode escrever a ata manualmente, sem depender do serviço de IA.',
          ),
        ]);
      case _Modo.editar:
        return _editor();
      case _Modo.ver:
        return _ver(_ata!);
    }
  }

  Widget _lista(List<Widget> filhos) => ListView(
        padding: const EdgeInsets.all(16),
        children: [_Cabecalho(reuniao: widget.reuniao), const SizedBox(height: 12), ...filhos],
      );

  Widget _ver(Map<String, dynamic> ata) {
    final transcricao = ata['transcricao'] as String?;
    switch (ata['estado']) {
      case 'pendente_revisao' when ata['origem'] == 'manual':
        return _lista([
          const _Estado(
            texto: 'Ata manual. Ainda não publicada.',
            detalhe: 'Só os administradores a veem até ser aprovada.',
          ),
          const SizedBox(height: 12),
          _Texto(titulo: 'Texto da ata', texto: (ata['rascunho'] as String?) ?? ''),
        ]);
      case 'pendente_revisao':
        return _lista([
          const _Estado(
            texto: 'Gerado por IA. Pendente de revisão.',
            detalhe: 'Confirme o rascunho com a transcrição antes de aprovar. '
                'Só os administradores o veem.',
          ),
          const SizedBox(height: 12),
          if (transcricao != null) ...[_Transcricao(texto: transcricao), const SizedBox(height: 12)],
          _Texto(titulo: 'Rascunho', texto: (ata['rascunho'] as String?) ?? ''),
        ]);
      case 'aprovada':
        final aprovadaEm = ata['aprovada_em'] as String?;
        return _lista([
          _Estado(
            texto: ata['origem'] == 'manual'
                ? 'Ata manual aprovada e publicada aos residentes.'
                : 'Ata aprovada e publicada aos residentes.',
            detalhe: [
              if (aprovadaEm != null) 'Aprovada pelo administrador em ${formatarReuniao(aprovadaEm)}.',
              'O áudio, a transcrição e o rascunho foram eliminados.',
            ].join(' '),
            aprovada: true,
          ),
          const SizedBox(height: 12),
          _Texto(titulo: 'Texto aprovado', texto: (ata['texto_aprovado'] as String?) ?? ''),
        ]);
      case 'a_transcrever':
        return _lista([
          const _Estado(
            texto: 'A transcrever.',
            detalhe: 'O processamento pode demorar. Pode sair desta página.',
          ),
        ]);
      case 'falhou_transcricao':
        return _lista([
          const _Estado(
            texto: 'A transcrição falhou.',
            detalhe: 'O áudio continua guardado. Pode escrever a ata manualmente.',
          ),
        ]);
      default:
        return _lista([const _Estado(texto: 'Não foi possível mostrar esta ata.')]);
    }
  }

  Widget _editor() {
    final transcricao = _ata?['transcricao'] as String?;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_erro != null) ...[
          Card(
            margin: EdgeInsets.zero,
            color: scheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              // Dentro do Card: o Card cria o seu próprio nó de acessibilidade, e o
              // TalkBack só anuncia a live region se for o nó que tem o texto.
              child: Semantics(
                liveRegion: true,
                child: Text(_erro!, style: TextStyle(color: scheme.onErrorContainer)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_manual) ...[
          const _Estado(texto: 'Sem rascunho de IA. A ata será identificada como manual.'),
          const SizedBox(height: 12),
        ],
        if (transcricao != null) ...[_Transcricao(texto: transcricao), const SizedBox(height: 12)],
        TextField(
          controller: _texto,
          enabled: !_aEnviar,
          minLines: 8,
          maxLines: null,
          maxLength: kMaxTextoAta,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            labelText: 'Texto da ata',
            hintText: _manual ? 'Escreva as decisões confirmadas na assembleia.' : null,
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (_) {
            if (_erro != null) setState(() => _erro = null);
          },
        ),
        const SizedBox(height: 4),
        Text(
          'A alteração fica como rascunho até aprovar.',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget? _botoes() {
    final Widget conteudo;
    if (_modo == _Modo.editar) {
      conteudo = Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _aEnviar ? null : _guardar,
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Guardar rascunho'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _aEnviar ? null : _aprovar,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _aEnviar
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'A enviar'),
                  )
                : const Text('Aprovar ata'),
          ),
        ),
      ]);
    } else if (_modo == _Modo.ver && _ata?['estado'] == 'pendente_revisao') {
      conteudo = FilledButton.icon(
        onPressed: _editar,
        icon: const Icon(Icons.edit_outlined),
        label: Text(_manual ? 'Editar ata' : 'Editar rascunho'),
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
      );
    } else if (_modo == _Modo.semAta ||
        (_modo == _Modo.ver && _ata?['estado'] == 'falhou_transcricao')) {
      conteudo = FilledButton.icon(
        onPressed: _editar,
        icon: const Icon(Icons.edit_note_outlined),
        label: const Text('Escrever ata manual'),
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
      );
    } else if (_modo == _Modo.ver && _ata?['estado'] == 'a_transcrever') {
      conteudo = OutlinedButton(
        onPressed: _carregar,
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        child: const Text('Atualizar estado'),
      );
    } else {
      return null;
    }
    return SafeArea(
      child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: conteudo),
    );
  }
}

/// "Assembleia de condóminos" com a data, como na lista de reuniões.
class _Cabecalho extends StatelessWidget {
  final Map<String, dynamic> reuniao;

  const _Cabecalho({required this.reuniao});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      header: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Assembleia de condóminos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        Text(formatarReuniao(reuniao['data_hora'] as String), style: TextStyle(color: muted)),
      ]),
    );
  }
}

/// Faixa de estado da ata. `liveRegion` faz o TalkBack anunciar a mudança de estado
/// (por exemplo, de "Pendente de revisão" para "Ata aprovada").
class _Estado extends StatelessWidget {
  final String texto;
  final String? detalhe;
  final bool aprovada;

  const _Estado({required this.texto, this.detalhe, this.aprovada = false});

  @override
  Widget build(BuildContext context) {
    // As cores do wireframe: amarelo para "pendente", verde para "aprovada".
    final fundo = aprovada ? const Color(0xFFDDF3E4) : const Color(0xFFFFF2D6);
    const cor = Color(0xFF1B1B1B);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(texto, style: const TextStyle(color: cor, fontWeight: FontWeight.w600)),
          if (detalhe != null) ...[
            const SizedBox(height: 4),
            Text(detalhe!, style: const TextStyle(color: cor)),
          ],
        ]),
      ),
    );
  }
}

/// A transcrição fechada por omissão (pode ser longa); abre-se para conferir o rascunho.
class _Transcricao extends StatelessWidget {
  final String texto;

  const _Transcricao({required this.texto});

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          title: const Text('Transcrição', style: TextStyle(fontWeight: FontWeight.w600)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(texto)],
        ),
      );
}

class _Texto extends StatelessWidget {
  final String titulo;
  final String texto;

  const _Texto({required this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(texto),
          ]),
        ),
      );
}
