import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'reunioes_screen.dart';

typedef EscolherAudioAta = Future<AudioAta?> Function();

Future<AudioAta?> escolherAudioAta() async {
  final ficheiros = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['mp3', 'm4a', 'wav'],
  );
  if (ficheiros.isEmpty) return null;
  final ficheiro = ficheiros.first;
  final tamanho = await ficheiro.length();
  if (tamanho == null) throw StateError('Não foi possível ler o ficheiro.');
  return AudioAta(
    nome: ficheiro.name,
    tamanho: tamanho,
    abrirStream: ficheiro.readAsByteStream,
  );
}

/// Área privada do administrador: o resultado fica pendente até revisão humana.
class AtaScreen extends StatefulWidget {
  final ApiService api;
  final String credencial;
  final Map<String, dynamic> reuniao;
  final EscolherAudioAta escolherAudio;

  const AtaScreen({
    super.key,
    required this.api,
    required this.credencial,
    required this.reuniao,
    this.escolherAudio = escolherAudioAta,
  });

  @override
  State<AtaScreen> createState() => _AtaScreenState();
}

class _AtaScreenState extends State<AtaScreen> with WidgetsBindingObserver {
  Map<String, dynamic>? _ata;
  AudioAta? _audio;
  String? _erro;
  bool _aCarregar = true;
  bool _aEnviar = false;
  Timer? _polling;

  int get _reuniaoId => widget.reuniao['id'] as int;

  String _motivoFalha(String? codigo) => switch (codigo) {
        'duracao_audio_invalida' =>
          'O áudio excede o limite de 3 horas. Escolha uma gravação mais curta.',
        'audio_invalido' =>
          'O áudio não pôde ser lido. Escolha outro ficheiro.',
        'audio_em_falta' =>
          'O áudio original não está disponível. Selecione novamente a gravação.',
        'chave_ia_ausente' =>
          'A transcrição por IA não está configurada. Contacte o administrador do sistema.',
        'credito_ia_esgotado' =>
          'A transcrição por IA está sem créditos. Tente novamente depois de repor o saldo.',
        'ferramenta_audio_indisponivel' =>
          'O processamento de áudio está indisponível. Contacte o administrador do sistema.',
        _ => 'A transcrição falhou após várias tentativas.',
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _consultar();
  }

  @override
  void dispose() {
    _polling?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _consultar();
    } else {
      _polling?.cancel();
    }
  }

  void _agendarConsulta() {
    _polling?.cancel();
    if (_ata?['estado'] == 'a_transcrever' && mounted) {
      _polling = Timer(const Duration(seconds: 15), _consultar);
    }
  }

  Future<void> _consultar() async {
    if (!mounted) return;
    try {
      final ata = await widget.api.getAta(_reuniaoId, widget.credencial);
      if (!mounted) return;
      setState(() {
        _ata = ata;
        _erro = null;
        _aCarregar = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.statusCode == 404) {
          _ata = null;
          _erro = null;
        } else {
          _erro = _mensagemErro(e);
        }
        _aCarregar = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Sem ligação. Verifique a rede e tente novamente.';
        _aCarregar = false;
      });
    }
    _agendarConsulta();
  }

  Future<void> _selecionar() async {
    try {
      final audio = await widget.escolherAudio();
      if (!mounted || audio == null) return;
      setState(() {
        _audio = audio;
        _erro = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() =>
          _erro = 'Não foi possível ler o ficheiro. Escolha outro áudio.');
    }
  }

  Future<void> _enviar() async {
    final audio = _audio;
    if (audio == null || _aEnviar) return;
    setState(() {
      _aEnviar = true;
      _erro = null;
    });
    try {
      final ata = await widget.api.carregarAudioAta(
        reuniaoId: _reuniaoId,
        credencial: widget.credencial,
        audio: audio,
      );
      if (!mounted) return;
      setState(() {
        _ata = ata;
        _audio = null;
        _aEnviar = false;
      });
      _agendarConsulta();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = _mensagemErro(e);
        _aEnviar = false;
      });
    } on ArgumentError catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.message.toString();
        _aEnviar = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro =
            'Não foi possível enviar o áudio. Verifique a rede e tente novamente.';
        _aEnviar = false;
      });
    }
  }

  Future<void> _repetir() async {
    if (_aEnviar) return;
    setState(() {
      _aEnviar = true;
      _erro = null;
    });
    try {
      final ata =
          await widget.api.repetirTranscricaoAta(_reuniaoId, widget.credencial);
      if (!mounted) return;
      setState(() {
        _ata = ata;
        _aEnviar = false;
      });
      _agendarConsulta();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = _mensagemErro(e);
        _aEnviar = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro =
            'Não foi possível repetir a transcrição. Verifique a rede e tente novamente.';
        _aEnviar = false;
      });
    }
  }

  String _mensagemErro(ApiException erro) => switch (erro.statusCode) {
        401 => 'A sessão expirou. Entre novamente na app.',
        403 => 'Só um administrador pode consultar esta ata.',
        404 => 'A reunião não foi encontrada.',
        409 => erro.codigo == 'ata_ja_aprovada'
            ? 'A ata já foi aprovada.'
            : erro.codigo == 'audio_em_falta'
                ? 'O áudio original não está disponível. Contacte o administrador do sistema.'
                : erro.codigo == 'ata_nao_falhou'
                    ? 'A ata já não está em falha. Atualize o estado.'
                    : 'Esta reunião já tem outro áudio. Consulte a ata existente.',
        413 => 'O áudio excede o limite de 200 MB.',
        415 => 'Formato não aceite. Use MP3, M4A ou WAV.',
        422 => 'O áudio é inválido. Escolha outro ficheiro.',
        503 => 'Serviço temporariamente indisponível. Tente novamente.',
        _ => 'Não foi possível concluir o pedido. Tente novamente.',
      };

  @override
  Widget build(BuildContext context) {
    final estado = _ata?['estado'] as String?;
    final motivo = _ata?['erro_transcricao'] as String?;
    final podeSubstituir = estado == 'falhou_transcricao' &&
        {'duracao_audio_invalida', 'audio_invalido', 'audio_em_falta'}
            .contains(motivo);
    final podeEnviar = estado == null || podeSubstituir;
    return Scaffold(
      appBar: AppBar(title: const Text('Ata da reunião')),
      body: RefreshIndicator(
        onRefresh: _consultar,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Assembleia de condóminos',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
                '${formatarReuniao(widget.reuniao['data_hora'] as String)} · ${widget.reuniao['local']}'),
            const SizedBox(height: 20),
            if (_aCarregar) const Center(child: CircularProgressIndicator()),
            if (_erro != null) ...[
              Semantics(
                  liveRegion: true,
                  child: Text(_erro!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error))),
              TextButton(
                  onPressed: _consultar, child: const Text('Atualizar estado')),
            ],
            if (estado == 'a_transcrever') ...[
              Semantics(
                  liveRegion: true,
                  child: const Text(
                      'A transcrever. Pode sair deste ecrã; o processamento continua em segundo plano.')),
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            if (estado == 'falhou_transcricao')
              Semantics(
                  liveRegion: true,
                  child: Text(
                      '${_motivoFalha(motivo)} ${motivo == 'audio_em_falta' ? '' : 'O áudio continua guardado. '}${podeSubstituir ? 'Selecione um ficheiro para o substituir.' : 'Pode tentar novamente sem selecionar o ficheiro.'}')),
            if (estado == 'falhou_transcricao' && !podeSubstituir) ...[
              const SizedBox(height: 16),
              const Text(
                  'Uma nova tentativa enviará o áudio e a transcrição à OpenAI.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _aEnviar ? null : _repetir,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar transcrição novamente'),
              ),
              if (_aEnviar) const Center(child: CircularProgressIndicator()),
            ],
            if (estado == 'pendente_revisao') ...[
              Semantics(
                  liveRegion: true,
                  child: const Text(
                      'Rascunho gerado por IA. Pendente de revisão humana. Ainda não está publicado.')),
              const SizedBox(height: 16),
              Text('Rascunho', style: Theme.of(context).textTheme.titleMedium),
              SelectableText((_ata?['rascunho'] as String?) ?? ''),
              const SizedBox(height: 16),
              Text('Transcrição',
                  style: Theme.of(context).textTheme.titleMedium),
              SelectableText((_ata?['transcricao'] as String?) ?? ''),
            ],
            if (estado == 'aprovada') const Text('Ata aprovada.'),
            if (podeEnviar && !_aCarregar) ...[
              const SizedBox(height: 20),
              const Text(
                  'Antes de enviar: o áudio e a transcrição serão enviados à OpenAI para gerar um rascunho. Avise os presentes antes de gravar. Apenas administradores podem aceder ao áudio e ao rascunho. A ata só é publicada após revisão e aprovação.'),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _aEnviar ? null : _selecionar,
                icon: const Icon(Icons.audio_file_outlined),
                label: const Text('Escolher áudio MP3, M4A ou WAV'),
              ),
              if (_audio != null)
                Text(
                    '${_audio!.nome} · ${(_audio!.tamanho / 1000000).toStringAsFixed(1)} MB'),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _audio == null || _aEnviar ? null : _enviar,
                icon: const Icon(Icons.upload_file),
                label:
                    Text(podeSubstituir ? 'Substituir áudio' : 'Enviar áudio'),
              ),
              if (_aEnviar) const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
