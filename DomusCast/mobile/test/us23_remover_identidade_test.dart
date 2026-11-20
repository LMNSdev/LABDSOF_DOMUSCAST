// US-23: o administrador remove a identidade de quem saiu da fração.
import 'dart:convert';

import 'package:domuscast/local/queue_db.dart';
import 'package:domuscast/screens/acesso_removido_screen.dart';
import 'package:domuscast/screens/fracao_qr_screen.dart';
import 'package:domuscast/screens/home_screen.dart';
import 'package:domuscast/screens/landing_screen.dart';
import 'package:domuscast/screens/ler_qr_screen.dart';
import 'package:domuscast/screens/reportes_list_screen.dart';
import 'package:domuscast/services/api_service.dart';
import 'package:domuscast/services/sessao_admin.dart';
import 'package:domuscast/services/sessao_residente.dart';
import 'package:domuscast/widgets/residentes_fracao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _sessao = SessaoAdmin(
  condominioId: 7,
  nomeCondominio: 'Rua das Flores, 12',
  credencial: 'cred-123',
);

http.Response _json(Object body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// "16/11" na data local da máquina que corre os testes.
String _dia(DateTime utc) {
  final d = utc.toLocal();
  String dois(int v) => v.toString().padLeft(2, '0');
  return '${dois(d.day)}/${dois(d.month)}';
}

/// API falsa da fração 1, com os residentes ativos em memória.
class _Servidor {
  List<Map<String, dynamic>> residentes;
  final pedidos = <String>[];
  int estadoRemover = 204;

  _Servidor(this.residentes);

  ApiService get api => ApiService(client: MockClient((req) async {
        pedidos.add('${req.method} ${req.url.path}');
        expect(req.headers['Authorization'], 'Bearer cred-123');
        final path = req.url.path;
        if (req.method == 'GET' && path == '/fracoes/1/identidades') {
          return _json(residentes, 200);
        }
        final um = RegExp(r'^/identidades/(\d+)$').firstMatch(path);
        if (req.method == 'DELETE' && um != null) {
          final id = int.parse(um.group(1)!);
          residentes = residentes.where((r) => r['id'] != id).toList();
          if (estadoRemover != 204) {
            return _json({'codigo': 'nao_encontrado', 'mensagem': 'x', 'request_id': 'r'},
                estadoRemover);
          }
          return http.Response('', 204);
        }
        if (req.method == 'GET' && path == '/fracoes/1/qr') return _json([], 200);
        return _json({}, 500);
      }));
}

List<Map<String, dynamic>> _doisResidentes() => [
      {'id': 11, 'nome': 'Marta Silva', 'criado_em': '2026-11-16T09:00:00Z'},
      {'id': 12, 'nome': 'João Silva', 'criado_em': '2026-11-17T18:30:00Z'},
    ];

Widget _secao(ApiService api) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ResidentesFracao(api: api, sessao: _sessao, fracaoId: 1),
        ),
      ),
    );

Finder _noDialogo(String texto) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(texto));

Map<String, dynamic> _reporte({
  required String descricao,
  String? autorNome,
  String? fracao,
  bool mostrarNome = false,
  bool autorRemovido = false,
}) =>
    {
      'id': descricao.hashCode,
      'descricao': descricao,
      'foto_url': null,
      'estado': 'em_curso',
      'criado_em': '2026-11-19T10:12:00Z',
      'atualizado_em': '2026-11-19T10:12:00Z',
      'mostrar_nome': mostrarNome,
      'autor_nome': autorNome,
      'fracao': fracao,
      'meu': false,
      'autor_removido': autorRemovido,
    };

void main() {
  group('Residentes da fração', () {
    testWidgets('1. lista residentes com nome e data de entrada', (tester) async {
      await tester.pumpWidget(_secao(_Servidor(_doisResidentes()).api));
      await tester.pumpAndSettle();

      expect(find.text('Residentes'), findsOneWidget);
      expect(find.text('Marta Silva'), findsOneWidget);
      expect(find.text('João Silva'), findsOneWidget);
      expect(find.text('entrou a ${_dia(DateTime.utc(2026, 11, 16, 9))}'), findsOneWidget);
      expect(find.text('entrou a ${_dia(DateTime.utc(2026, 11, 17, 18, 30))}'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Remover'), findsNWidgets(2));
    });

    testWidgets('2. remover pede confirmação e Cancelar não chama a API', (tester) async {
      final servidor = _Servidor(_doisResidentes());
      await tester.pumpWidget(_secao(servidor.api));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Remover').first);
      await tester.pumpAndSettle();
      expect(find.text('Remover Marta Silva?'), findsOneWidget);
      expect(
        find.text('O nome é apagado e o telemóvel desta pessoa deixa de ter acesso. '
            'Os reportes ficam como "Residente removido". Não se pode desfazer.'),
        findsOneWidget,
      );

      await tester.tap(_noDialogo('Cancelar'));
      await tester.pumpAndSettle();
      expect(servidor.pedidos.where((p) => p.startsWith('DELETE')), isEmpty);
      expect(find.text('Marta Silva'), findsOneWidget);
    });

    testWidgets('3. confirmar envia DELETE, mostra a mensagem e a lista atualiza',
        (tester) async {
      final servidor = _Servidor(_doisResidentes());
      await tester.pumpWidget(_secao(servidor.api));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Remover').first);
      await tester.pumpAndSettle();
      await tester.tap(_noDialogo('Remover'));
      await tester.pumpAndSettle();

      expect(servidor.pedidos, contains('DELETE /identidades/11'));
      expect(find.text('Marta Silva já não tem acesso.'), findsOneWidget);
      expect(find.text('Marta Silva'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Remover'), findsOneWidget);
    });

    testWidgets('sem residentes mostra a mensagem própria', (tester) async {
      await tester.pumpWidget(_secao(_Servidor([]).api));
      await tester.pumpAndSettle();
      expect(find.text('Ainda ninguém entrou nesta fração.'), findsOneWidget);
    });

    testWidgets('remover já removida (404) recarrega com a mensagem', (tester) async {
      final servidor = _Servidor(_doisResidentes())..estadoRemover = 404;
      await tester.pumpWidget(_secao(servidor.api));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Remover').first);
      await tester.pumpAndSettle();
      await tester.tap(_noDialogo('Remover'));
      await tester.pumpAndSettle();

      expect(find.text('Esta pessoa já tinha sido removida.'), findsOneWidget);
      expect(find.text('Marta Silva', skipOffstage: false), findsNothing);
    });

    testWidgets('sem ligação ao remover avisa que ninguém foi removido', (tester) async {
      final api = ApiService(client: MockClient((req) async {
        if (req.method == 'GET') return _json(_doisResidentes(), 200);
        throw http.ClientException('sem rede');
      }));
      await tester.pumpWidget(_secao(api));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Remover').first);
      await tester.pumpAndSettle();
      await tester.tap(_noDialogo('Remover'));
      await tester.pumpAndSettle();

      expect(find.text('Sem ligação. Ninguém foi removido.'), findsOneWidget);
      expect(find.text('Marta Silva'), findsOneWidget);
    });

    testWidgets('erro ao carregar mostra mensagem e Tentar de novo', (tester) async {
      await tester.pumpWidget(_secao(ApiService(client: MockClient((_) async => _json({}, 500)))));
      await tester.pumpAndSettle();
      expect(find.text('Não foi possível carregar os residentes.'), findsOneWidget);
      expect(find.text('Tentar de novo'), findsOneWidget);
    });

    testWidgets('aparece no ecrã da fração', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: FracaoQrScreen(
          api: _Servidor(_doisResidentes()).api,
          sessao: _sessao,
          fracaoId: 1,
          designacao: 'A',
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Residentes'), findsOneWidget);
      expect(find.text('Marta Silva'), findsOneWidget);
    });
  });

  group('Reportes do administrador', () {
    Future<void> abrir(WidgetTester tester, List<Map<String, dynamic>> reportes) async {
      final api = ApiService(client: MockClient((_) async => _json(reportes, 200)));
      await tester.pumpWidget(MaterialApp(
        home: ReportesListScreen(
          api: api,
          credencial: 'cred-123',
          podeReportar: false,
          fila: MemoriaFilaReportes(),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('4. o administrador vê Residente removido, fração A', (tester) async {
      await abrir(tester, [
        _reporte(descricao: 'Luz da escada fundida', fracao: 'A', autorRemovido: true),
        _reporte(descricao: 'Porta da entrada avariada', autorNome: 'João Silva', fracao: 'A'),
      ]);
      expect(find.textContaining('Residente removido, fração A - '), findsOneWidget);
      expect(find.textContaining('João Silva, fração A - '), findsOneWidget);
    });

    testWidgets('reporte de alguém removido não mostra a etiqueta nome visível', (tester) async {
      await abrir(tester, [
        _reporte(
          descricao: 'Luz da escada fundida',
          fracao: 'A',
          mostrarNome: true,
          autorRemovido: true,
        ),
      ]);
      expect(find.textContaining('Residente removido, fração A'), findsOneWidget);
      expect(find.text('nome visível'), findsNothing);
    });
  });

  group('Telemóvel removido', () {
    const sessaoMarta = SessaoResidente(credencial: 'cred-marta', nome: 'Marta Silva', fracao: 'A');

    /// API que responde 401 a tudo, como depois de a identidade ser removida.
    ApiService removida() => ApiService(client: MockClient((_) async => _json(
          {'codigo': 'nao_autenticado', 'mensagem': 'Credencial inválida.', 'request_id': 'r'},
          401,
        )));

    testWidgets('5. 401 nos reportes apaga a credencial e mostra O seu acesso foi removido',
        (tester) async {
      final store = MemoriaSessaoResidenteStore(sessaoMarta);
      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
          api: removida(),
          sessaoResidente: sessaoMarta,
          storeResidente: store,
          fila: MemoriaFilaReportes(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('O seu acesso foi removido'), findsOneWidget);
      expect(
        find.text('O administrador removeu o acesso deste telemóvel. '
            'Se ainda vive no prédio, peça-lhe um novo QR code.'),
        findsOneWidget,
      );
      expect(find.byType(NavigationBar), findsNothing);
      expect(await store.ler(), isNull);
    });

    testWidgets('401 ao submeter um reporte também apaga a credencial e mostra o aviso',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final store = MemoriaSessaoResidenteStore(sessaoMarta);
      final fila = MemoriaFilaReportes();
      // A lista carregou antes da remoção; só o envio do reporte recebe 401.
      final api = ApiService(client: MockClient((req) async {
        if (req.method == 'GET') return _json([], 200);
        return _json(
          {'codigo': 'nao_autenticado', 'mensagem': 'Credencial inválida.', 'request_id': 'r'},
          401,
        );
      }));
      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
          api: api,
          sessaoResidente: sessaoMarta,
          storeResidente: store,
          fila: fila,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reportar avaria'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Fuga na garagem');
      await tester.tap(find.text('Submeter reporte'));
      await tester.pumpAndSettle();

      expect(find.text('O seu acesso foi removido'), findsOneWidget);
      expect(await store.ler(), isNull);
      expect(await fila.pendentes(), isEmpty);
    });

    testWidgets('ao abrir a app com a identidade removida, a credencial guardada é apagada',
        (tester) async {
      final store = MemoriaSessaoResidenteStore(sessaoMarta);
      await tester.pumpWidget(MaterialApp(
        home: LandingScreen(
          store: MemoriaSessaoAdminStore(),
          storeResidente: store,
          api: removida(),
          fila: MemoriaFilaReportes(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('O seu acesso foi removido'), findsOneWidget);
      expect(await store.ler(), isNull);
    });

    testWidgets('Ler QR code abre o leitor', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AcessoRemovidoScreen(api: removida(), store: MemoriaSessaoResidenteStore()),
      ));
      await tester.tap(find.text('Ler QR code'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LerQrScreen), findsOneWidget);
    });

    testWidgets('a fila offline mantém os reportes por enviar', (tester) async {
      final fila = MemoriaFilaReportes();
      await fila.guardar(descricao: 'Fuga na garagem', idempotencyKey: 'chave-1');
      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
          api: removida(),
          sessaoResidente: sessaoMarta,
          storeResidente: MemoriaSessaoResidenteStore(sessaoMarta),
          fila: fila,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('O seu acesso foi removido'), findsOneWidget);
      expect(await fila.pendentes(), hasLength(1));
    });

    testWidgets('o administrador com 401 não vê o ecrã de residente removido', (tester) async {
      await tester.pumpWidget(MaterialApp(home: HomeScreen(api: removida(), sessao: _sessao)));
      await tester.pumpAndSettle();
      expect(find.text('O seu acesso foi removido'), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });
}
