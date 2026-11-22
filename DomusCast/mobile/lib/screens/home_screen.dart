import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../local/queue_db.dart';
import '../services/api_service.dart';
import '../services/sessao_admin.dart';
import '../services/sessao_residente.dart';
import 'acesso_removido_screen.dart';
import 'condominio_screen.dart';
import 'reportes_list_screen.dart';
import 'reunioes_screen.dart';

enum Separador { reportes, reunioes, avisos, condominio }

/// Ecrã principal com uma barra de separadores; os separadores dependem do papel.
///
/// Administrador (com [sessao]): Reportes, Reuniões, Avisos, Condomínio.
/// Residente: Reportes, Reuniões, Avisos. Avisos (US-06) ainda não está disponível.
/// Cada separador tem a sua navegação, para o "voltar" fechar primeiro o ecrã
/// aberto dentro do separador e só depois sair da app.
class HomeScreen extends StatefulWidget {
  final ApiService api;
  final SessaoAdmin? sessao;
  final SessaoResidente? sessaoResidente;

  /// Onde está guardada a credencial do residente; apagada se a identidade
  /// for removida pelo administrador (US-23).
  final SessaoResidenteStore? storeResidente;
  final FilaReportes? fila;
  final Separador separadorInicial;

  const HomeScreen({
    super.key,
    required this.api,
    this.sessao,
    this.sessaoResidente,
    this.storeResidente,
    this.fila,
    this.separadorInicial = Separador.reportes,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final List<Separador> _separadores = [
    Separador.reportes,
    Separador.reunioes,
    Separador.avisos,
    if (widget.sessao != null) Separador.condominio,
  ];
  late final Map<Separador, GlobalKey<NavigatorState>> _navs = {
    for (final s in _separadores) s: GlobalKey<NavigatorState>(),
  };
  late int _atual = _separadores
      .indexOf(widget.separadorInicial)
      .clamp(0, _separadores.length - 1);
  late final ValueNotifier<bool> _reportesAtivos = ValueNotifier(
    _separadores[_atual] == Separador.reportes,
  );

  @override
  void dispose() {
    _reportesAtivos.dispose();
    super.dispose();
  }

  Widget _raiz(Separador s) => switch (s) {
    Separador.reportes => ReportesListScreen(
      api: widget.api,
      credencial:
          widget.sessao?.credencial ?? widget.sessaoResidente?.credencial,
      nomeResidente: widget.sessaoResidente?.nome,
      podeReportar: widget.sessao == null,
      fila: widget.fila,
      onAcessoRemovido: widget.sessao == null ? _acessoRemovido : null,
      ativo: _reportesAtivos,
    ),
    Separador.reunioes => ReunioesScreen(
      api: widget.api,
      credencial: widget.sessao?.credencial,
    ),
    Separador.avisos => const SizedBox.shrink(),
    Separador.condominio => CondominioScreen(
      api: widget.api,
      sessao: widget.sessao!,
    ),
  };

  NavigationDestination _destino(Separador s) => switch (s) {
    Separador.reportes => const NavigationDestination(
      icon: Icon(Icons.report_problem_outlined),
      selectedIcon: Icon(Icons.report_problem),
      label: 'Reportes',
    ),
    Separador.reunioes => const NavigationDestination(
      icon: Icon(Icons.event_outlined),
      selectedIcon: Icon(Icons.event),
      label: 'Reuniões',
    ),
    Separador.avisos => const NavigationDestination(
      icon: Icon(Icons.campaign_outlined),
      label: 'Avisos',
      enabled: false,
      tooltip: 'Em breve',
    ),
    Separador.condominio => const NavigationDestination(
      icon: Icon(Icons.apartment_outlined),
      selectedIcon: Icon(Icons.apartment),
      label: 'Condomínio',
    ),
  };

  /// US-23: a API deixou de aceitar a credencial do residente. Apaga-a e mostra
  /// o aviso em vez da app; a fila offline fica no telemóvel.
  Future<void> _acessoRemovido() async {
    final store = widget.storeResidente ?? SeguraSessaoResidenteStore();
    await store.apagar();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => AcessoRemovidoScreen(api: widget.api, store: store),
      ),
      (_) => false,
    );
  }

  void _escolher(int i) {
    if (i == _atual) {
      // Tocar no separador já aberto volta ao início desse separador.
      _navs[_separadores[i]]!.currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _atual = i);
    _reportesAtivos.value = _separadores[i] == Separador.reportes;
  }

  /// "Voltar" do Android: fecha o ecrã aberto no separador; no início de outro
  /// separador regressa aos Reportes; nos Reportes sai da app.
  void _voltar() {
    final nav = _navs[_separadores[_atual]]!.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
    } else if (_atual != 0) {
      setState(() => _atual = 0);
      _reportesAtivos.value = true;
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _voltar();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _atual,
          children: [
            for (final s in _separadores)
              Navigator(
                key: _navs[s],
                onGenerateRoute: (_) =>
                    MaterialPageRoute(builder: (_) => _raiz(s)),
              ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _atual,
          onDestinationSelected: _escolher,
          destinations: [for (final s in _separadores) _destino(s)],
        ),
      ),
    );
  }
}
