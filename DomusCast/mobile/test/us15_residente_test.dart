// US-15: o residente indica o nome no primeiro acesso pelo QR code da fração.
import 'dart:async';
import 'dart:convert';

import 'package:domuscast/screens/home_screen.dart';
import 'package:domuscast/screens/landing_screen.dart';
import 'package:domuscast/screens/ler_qr_screen.dart';
import 'package:domuscast/screens/nome_residente_screen.dart';
import 'package:domuscast/services/api_service.dart';
import 'package:domuscast/services/sessao_admin.dart';
import 'package:domuscast/services/sessao_residente.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _residente = SessaoResidente(credencial: 'cred-1', nome: 'Marta Silva', fracao: 'A');
const _criada = {'id': 1, 'nome': 'Marta Silva', 'fracao': 'A', 'credencial': 'cred-1'};

http.Response _json(Object body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

http.Response _erro(int status, String codigo) =>
    _json({'codigo': codigo, 'mensagem': '-', 'request_id': 'r1'}, status);

/// API em que `POST /identidades` responde com [identidades]; a lista de reportes vem vazia.
ApiService _api(FutureOr<http.Response> Function(http.Request) identidades) =>
    ApiService(client: MockClient((req) async {
      if (req.url.path == '/identidades') return identidades(req);
      return _json([], 200);
    }));

Future<void> _abrirNome(WidgetTester tester, ApiService api, [SessaoResidenteStore? store]) =>
    tester.pumpWidget(MaterialApp(
      home: NomeResidenteScreen(api: api, store: store ?? MemoriaSessaoResidenteStore(), token: 'tok'),
    ));

Future<void> _enviar(WidgetTester tester, String nome) async {
  await tester.enterText(find.byType(TextField), nome);
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
}

Widget _landing({SessaoResidente? residente, Stream<Uri>? links}) => MaterialApp(
      home: LandingScreen(
        store: MemoriaSessaoAdminStore(),
        storeResidente: MemoriaSessaoResidenteStore(residente),
        api: _api((_) => _json(_criada, 201)),
        links: links,
      ),
    );

void main() {
  test('o token vem só de links domuscast://entrar', () {
    expect(tokenDoLink('domuscast://entrar?t=abc'), 'abc');
    expect(tokenDoLink(' domuscast://entrar?t=abc '), 'abc');
    expect(tokenDoLink('https://exemplo.pt/entrar?t=abc'), isNull);
    expect(tokenDoLink('domuscast://entrar'), isNull);
    expect(tokenDoLink('olá'), isNull);
  });

  group('Entrada', () {
    testWidgets('com identidade guardada abre os Reportes sem pedir o nome', (tester) async {
      final links = StreamController<Uri>();
      await tester.pumpWidget(_landing(residente: _residente, links: links.stream));
      await tester.pumpAndSettle();
      links.add(Uri.parse('domuscast://entrar?t=tok'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(NomeResidenteScreen), findsNothing);
      expect(find.text('Condomínio'), findsNothing);
    });

    testWidgets('sessão residente guardada autentica a criação de um reporte',
        (tester) async {
      String? authorization;
      final api = ApiService(client: MockClient((req) async {
        if (req.url.path == '/reportes' && req.method == 'GET') {
          return _json([], 200);
        }
        if (req.url.path == '/reportes' && req.method == 'POST') {
          authorization = req.headers['authorization'];
          return _json({'id': 42}, 201);
        }
        return _json({'detail': 'not found'}, 404);
      }));

      await tester.pumpWidget(MaterialApp(
        home: LandingScreen(
          store: MemoriaSessaoAdminStore(),
          storeResidente: MemoriaSessaoResidenteStore(_residente),
          api: api,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reportar avaria'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Fuga na garagem');
      await tester.ensureVisible(find.text('Submeter reporte'));
      await tester.tap(find.text('Submeter reporte'));
      await tester.pumpAndSettle();

      expect(authorization, 'Bearer cred-1');
    });

    testWidgets('o link domuscast://entrar abre o ecrã do nome', (tester) async {
      final links = StreamController<Uri>();
      await tester.pumpWidget(_landing(links: links.stream));
      await tester.pumpAndSettle();
      links.add(Uri.parse('domuscast://entrar?t=tok'));
      await tester.pumpAndSettle();

      expect(find.byType(NomeResidenteScreen), findsOneWidget);
    });
  });

  group('Ler QR code', () {
    testWidgets('"Recebi um link" aceita o link do administrador e recusa outro texto',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: LerQrScreen(
          api: _api((_) => _json(_criada, 201)),
          store: MemoriaSessaoResidenteStore(),
          camara: const SizedBox(),
        ),
      ));
      await tester.tap(find.text('Recebi um link'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'olá');
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(find.text('Cole o link domuscast://entrar enviado pelo administrador.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'domuscast://entrar?t=tok');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.byType(NomeResidenteScreen), findsOneWidget);
    });
  });

  group('Pedir o nome', () {
    testWidgets('explica para que serve o nome e quem o vê', (tester) async {
      await _abrirNome(tester, _api((_) => _json(_criada, 201)));
      expect(find.text('Para o administrador saber quem reportou cada problema.'), findsOneWidget);
      expect(find.text('Só o administrador. Num reporte, pode escolher mostrar o nome aos vizinhos.'),
          findsOneWidget);
      expect(find.text('Não pedimos telefone nem e-mail.'), findsOneWidget);
    });

    testWidgets('nome vazio é recusado sem chamar a API', (tester) async {
      var chamadas = 0;
      await _abrirNome(tester, _api((_) {
        chamadas++;
        return _json(_criada, 201);
      }));
      await _enviar(tester, '   ');
      expect(find.text('Indique o seu nome.'), findsOneWidget);
      expect(chamadas, 0);
    });

    testWidgets('entra, guarda a identidade e autentica a criação de reporte',
        (tester) async {
      Map<String, dynamic>? enviado;
      String? authorization;
      final store = MemoriaSessaoResidenteStore();
      final api = ApiService(client: MockClient((req) async {
        if (req.url.path == '/identidades') {
          enviado = jsonDecode(req.body) as Map<String, dynamic>;
          return _json(_criada, 201);
        }
        if (req.method == 'GET') return _json([], 200);
        authorization = req.headers['authorization'];
        return _json({'id': 42}, 201);
      }));
      await _abrirNome(tester, api, store);
      await _enviar(tester, 'Marta Silva');

      expect(enviado, {'token': 'tok', 'nome': 'Marta Silva'});
      final guardada = await store.ler();
      expect(guardada?.credencial, 'cred-1');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Olá, Marta Silva. Entrou na fração A.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Reportar avaria'));
      await tester.tap(find.text('Reportar avaria'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Fuga na garagem');
      await tester.ensureVisible(find.text('Submeter reporte'));
      await tester.tap(find.text('Submeter reporte'));
      await tester.pumpAndSettle();
      expect(authorization, 'Bearer cred-1');
    });

    testWidgets('nome repetido na fração mostra a mensagem no campo', (tester) async {
      await _abrirNome(tester, _api((_) => _erro(409, 'nome_duplicado')));
      await _enviar(tester, 'marta silva');
      expect(
        find.text('Já existe alguém com este nome na sua fração. Acrescente, por exemplo, um apelido.'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('fração com 10 residentes mostra "Fração completa" sem pedir outro nome',
        (tester) async {
      await _abrirNome(tester, _api((_) => _erro(409, 'fracao_cheia')));
      await _enviar(tester, 'Marta Silva');
      expect(find.text('Fração completa'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Voltar'), findsOneWidget);
    });

    testWidgets('QR code inválido ou revogado pede para ler outro', (tester) async {
      await _abrirNome(tester, _api((_) => _erro(404, 'qr_invalido')));
      await _enviar(tester, 'Marta Silva');
      expect(find.text('QR code inválido'), findsOneWidget);
      expect(find.text('Este QR code não é válido ou foi revogado. Peça um novo ao administrador.'),
          findsOneWidget);
      expect(find.text('Ler outro QR code'), findsOneWidget);
    });

    testWidgets('sem internet avisa e "Tentar novamente" envia o mesmo nome', (tester) async {
      final nomes = <String>[];
      await _abrirNome(tester, _api((req) {
        nomes.add((jsonDecode(req.body) as Map<String, dynamic>)['nome'] as String);
        if (nomes.length == 1) throw http.ClientException('sem rede');
        return _json(_criada, 201);
      }));
      await _enviar(tester, 'Marta Silva');
      expect(find.text('Sem ligação à internet'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(nomes, ['Marta Silva', 'Marta Silva']);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('demasiadas tentativas (429) tem mensagem própria', (tester) async {
      await _abrirNome(tester, _api((_) => _json({'detail': '-'}, 429)));
      await _enviar(tester, 'Marta Silva');
      expect(find.text('Demasiadas tentativas'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });
  });

  group('Leitor de ecrã', () {
    testWidgets('botões e campos do ecrã do nome têm etiqueta', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrirNome(tester, _api((_) => _json(_criada, 201)));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantica.dispose();
    });

    testWidgets('botões do ecrã de ler o QR code têm etiqueta', (tester) async {
      final semantica = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(
        home: LerQrScreen(
          api: _api((_) => _json(_criada, 201)),
          store: MemoriaSessaoResidenteStore(),
          camara: const SizedBox(),
        ),
      ));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      expect(find.bySemanticsLabel('Câmara a ler o QR code'), findsOneWidget);
      semantica.dispose();
    });
  });
}
