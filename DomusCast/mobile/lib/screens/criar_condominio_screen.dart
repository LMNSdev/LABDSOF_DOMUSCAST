import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/sessao_admin.dart';
import 'fracoes_screen.dart';

const maxFracoes = 200;

/// US-01: o administrador cria o condomínio com nome e nº de frações.
class CriarCondominioScreen extends StatefulWidget {
  final ApiService api;
  final SessaoAdminStore store;

  const CriarCondominioScreen({super.key, required this.api, required this.store});

  @override
  State<CriarCondominioScreen> createState() => _CriarCondominioScreenState();
}

class _CriarCondominioScreenState extends State<CriarCondominioScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _nomeAdmin = TextEditingController();
  final _nFracoes = TextEditingController();
  bool _aEnviar = false;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _nomeAdmin.dispose();
    _nFracoes.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _aEnviar = true;
      _erro = null;
    });
    try {
      final r = await widget.api.criarCondominio(
        nome: _nome.text.trim(),
        nomeAdmin: _nomeAdmin.text.trim(),
        nFracoes: int.parse(_nFracoes.text.trim()),
      );
      final sessao = SessaoAdmin(
        condominioId: r['id'] as int,
        nomeCondominio: r['nome'] as String,
        credencial: r['credencial_admin'] as String,
      );
      await widget.store.guardar(sessao);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => FracoesScreen(api: widget.api, sessao: sessao)),
        (_) => false,
      );
    } on ApiException catch (e) {
      setState(() => _erro = e.statusCode == 429
          ? 'Demasiadas tentativas. Tente daqui a uma hora.'
          : 'Não foi possível criar o condomínio (erro ${e.statusCode}).');
    } catch (_) {
      setState(() => _erro = 'Sem ligação ao servidor. Tente novamente.');
    } finally {
      if (mounted) setState(() => _aEnviar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar condomínio')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                key: const Key('nome'),
                controller: _nome,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Nome do condomínio',
                  hintText: 'Ex.: Edifício Rua das Flores, 12',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Indique o nome do condomínio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('nomeAdmin'),
                controller: _nomeAdmin,
                textCapitalization: TextCapitalization.words,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'O seu nome (administrador)',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Indique o seu nome' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('nFracoes'),
                controller: _nFracoes,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nº de frações (1 a $maxFracoes)',
                  helperText: 'As frações ficam com as letras A, B, C…',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  return (n == null || n < 1 || n > maxFracoes)
                      ? 'Entre 1 e $maxFracoes frações'
                      : null;
                },
              ),
              if (_erro != null) ...[
                const SizedBox(height: 16),
                Text(_erro!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _aEnviar ? null : _criar,
                child: _aEnviar
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Criar condomínio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
