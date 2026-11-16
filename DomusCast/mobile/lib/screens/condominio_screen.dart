import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/sessao_admin.dart';
import 'fracoes_screen.dart';

/// Separador "Condomínio" do administrador: o que se configura de vez em quando.
class CondominioScreen extends StatelessWidget {
  final ApiService api;
  final SessaoAdmin sessao;

  const CondominioScreen({super.key, required this.api, required this.sessao});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(sessao.nomeCondominio)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Opcao(
            icon: Icons.qr_code_2,
            titulo: 'Frações e QR codes',
            subtitulo: 'Ver as frações e gerar o QR code de cada uma',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => FracoesScreen(api: api, sessao: sessao),
            )),
          ),
          const SizedBox(height: 8),
          const _Opcao(
            icon: Icons.admin_panel_settings_outlined,
            titulo: 'Administradores',
            subtitulo: 'Em breve: convidar e remover administradores',
          ),
          const SizedBox(height: 8),
          const _Opcao(
            icon: Icons.calendar_month_outlined,
            titulo: 'Calendário do condomínio',
            subtitulo: 'Em breve: link para subscrever as reuniões',
          ),
        ],
      ),
    );
  }
}

class _Opcao extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final VoidCallback? onTap;

  const _Opcao({required this.icon, required this.titulo, required this.subtitulo, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ativo = onTap != null;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        enabled: ativo,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.primary,
          child: Icon(icon),
        ),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitulo),
        trailing: ativo ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}
