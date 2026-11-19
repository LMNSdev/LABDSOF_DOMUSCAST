import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/sessao_residente.dart';
import 'home_screen.dart';
import 'ler_qr_screen.dart';

/// US-15, ecrãs 3 a 5: pedir o nome, mostrar os erros e entrar na app.
///
/// O token só é validado pela API quando o nome é enviado, por isso um QR code
/// inválido ou revogado só é detetado aqui.
class NomeResidenteScreen extends StatefulWidget {
  final ApiService api;
  final SessaoResidenteStore store;
  final String token;

  const NomeResidenteScreen({
    super.key,
    required this.api,
    required this.store,
    required this.token,
  });

  @override
  State<NomeResidenteScreen> createState() => _NomeResidenteScreenState();
}

enum _Erro { fracaoCheia, qrInvalido, semInternet, demasiadasTentativas, falhou }

class _NomeResidenteScreenState extends State<NomeResidenteScreen> {
  final _nome = TextEditingController();
  String? _erroNome;
  _Erro? _erro;
  bool _aEnviar = false;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    final nome = _nome.text.trim();
    if (nome.isEmpty) {
      setState(() => _erroNome = 'Indique o seu nome.');
      return;
    }
    setState(() {
      _erroNome = null;
      _aEnviar = true;
    });
    try {
      final r = await widget.api.criarIdentidade(token: widget.token, nome: nome);
      final sessao = SessaoResidente(
        credencial: r['credencial'] as String,
        nome: r['nome'] as String,
        fracao: r['fracao'] as String,
      );
      await widget.store.guardar(sessao);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            api: widget.api,
            credencialResidente: sessao.credencial,
          ),
        ),
        (_) => false,
      );
      messenger.showSnackBar(
          SnackBar(content: Text('Olá, ${sessao.nome}. Entrou na fração ${sessao.fracao}.')));
    } on ApiException catch (e) {
      setState(() {
        _erro = null;
        switch ((e.statusCode, e.codigo)) {
          case (409, 'nome_duplicado'):
            _erroNome = 'Já existe alguém com este nome na sua fração. '
                'Acrescente, por exemplo, um apelido.';
          case (409, 'fracao_cheia'):
            _erro = _Erro.fracaoCheia;
          case (404, _):
            _erro = _Erro.qrInvalido;
          case (422, _):
            _erroNome = 'Indique o seu nome.';
          case (429, _):
            _erro = _Erro.demasiadasTentativas;
          default:
            _erro = _Erro.falhou;
        }
      });
    } on http.ClientException {
      setState(() => _erro = _Erro.semInternet);
    } on SocketException {
      setState(() => _erro = _Erro.semInternet);
    } finally {
      if (mounted) setState(() => _aEnviar = false);
    }
  }

  void _lerOutroQr() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => LerQrScreen(api: widget.api, store: widget.store),
    ));
  }

  Widget _aviso(_Erro erro) => switch (erro) {
        _Erro.fracaoCheia => AvisoEntrada(
            titulo: 'Fração completa',
            texto: 'Esta fração já tem 10 residentes. '
                'Peça ao administrador para remover quem já não vive lá.',
            botao: 'Voltar',
            onPressed: () => Navigator.of(context).pop(),
          ),
        _Erro.qrInvalido => AvisoEntrada(
            titulo: 'QR code inválido',
            texto: 'Este QR code não é válido ou foi revogado. Peça um novo ao administrador.',
            botao: 'Ler outro QR code',
            onPressed: _lerOutroQr,
          ),
        _Erro.semInternet => AvisoEntrada(
            titulo: 'Sem ligação à internet',
            texto: 'O primeiro acesso precisa de internet. O nome que escreveu não se perde.',
            botao: 'Tentar novamente',
            onPressed: _aEnviar ? null : _continuar,
          ),
        _Erro.demasiadasTentativas => AvisoEntrada(
            titulo: 'Demasiadas tentativas',
            texto: 'Houve demasiadas tentativas de entrada com este QR code. '
                'Espere um pouco e tente novamente.',
            botao: 'Tentar novamente',
            onPressed: _aEnviar ? null : _continuar,
          ),
        _Erro.falhou => AvisoEntrada(
            titulo: 'Não foi possível entrar',
            texto: 'Ocorreu um erro no servidor. Tente novamente daqui a pouco.',
            botao: 'Tentar novamente',
            onPressed: _aEnviar ? null : _continuar,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final erro = _erro;
    return Scaffold(
      appBar: AppBar(title: Text(erro == _Erro.qrInvalido ? 'Ler QR code' : 'O seu nome')),
      body: SafeArea(child: erro != null ? _aviso(erro) : _formulario(context)),
    );
  }

  Widget _formulario(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Para que serve?', style: texto.titleSmall),
                const Text('Para o administrador saber quem reportou cada problema.'),
                const SizedBox(height: 12),
                Text('Quem vê?', style: texto.titleSmall),
                const Text('Só o administrador. Num reporte, pode escolher mostrar o nome aos vizinhos.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nome,
          enabled: !_aEnviar,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _continuar(),
          decoration: InputDecoration(
            labelText: 'Nome (obrigatório)',
            border: const OutlineInputBorder(),
            errorText: _erroNome,
            errorMaxLines: 3,
          ),
        ),
        const SizedBox(height: 8),
        Text('Não pedimos telefone nem e-mail.', style: texto.bodySmall),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _aEnviar ? null : _continuar,
          child: _aEnviar
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'A entrar'),
                )
              : const Text('Continuar'),
        ),
      ],
    );
  }
}
