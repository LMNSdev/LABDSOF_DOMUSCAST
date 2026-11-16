// US-01: criar condomínio, ver frações e gerar o QR code de uma fração.
import 'dart:convert';

import 'package:domuscast/screens/criar_condominio_screen.dart';
import 'package:domuscast/screens/fracao_qr_screen.dart';
import 'package:domuscast/screens/fracoes_screen.dart';
import 'package:domuscast/screens/landing_screen.dart';
import 'package:domuscast/services/api_service.dart';
import 'package:domuscast/services/sessao_admin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qr_flutter/qr_flutter.dart';

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

Widget _app(Widget home) => MaterialApp(home: home);

void main() {
  testWidgets('entrada mostra o botão do administrador', (tester) async {
    await tester.pumpWidget(_app(LandingScreen(store: MemoriaSessaoAdminStore())));
    await tester.pump();
    expect(find.text('Sou administrador: criar condomínio'), findsOneWidget);
  });

  testWidgets('entrada abre a lista de frações se já houver sessão de administrador',
      (tester) async {
    final api = ApiService(client: MockClient((_) async => _json([], 200)));
    await tester.pumpWidget(_app(LandingScreen(
      store: MemoriaSessaoAdminStore(_sessao),
      api: api,
    )));
    await tester.pumpAndSettle();
    expect(find.byType(FracoesScreen), findsOneWidget);
  });

  group('Criar condomínio', () {
    testWidgets('campos vazios mostram erros e não chamam a API', (tester) async {
      var chamadas = 0;
      final api = ApiService(client: MockClient((_) async {
        chamadas++;
        return _json({}, 500);
      }));
      await tester.pumpWidget(_app(CriarCondominioScreen(api: api, store: MemoriaSessaoAdminStore())));
      await tester.tap(find.widgetWithText(FilledButton, 'Criar condomínio'));
      await tester.pump();
      expect(find.text('Indique o nome do condomínio'), findsOneWidget);
      expect(find.text('Indique o seu nome'), findsOneWidget);
      expect(find.text('Entre 1 e 200 frações'), findsOneWidget);
      expect(chamadas, 0);
    });

    for (final n in ['0', '201']) {
      testWidgets('nº de frações $n é recusado', (tester) async {
        await tester.pumpWidget(_app(CriarCondominioScreen(
          api: ApiService(client: MockClient((_) async => _json({}, 500))),
          store: MemoriaSessaoAdminStore(),
        )));
        await tester.enterText(find.byKey(const Key('nFracoes')), n);
        await tester.tap(find.widgetWithText(FilledButton, 'Criar condomínio'));
        await tester.pump();
        expect(find.text('Entre 1 e 200 frações'), findsOneWidget);
      });
    }

    testWidgets('criar envia os dados, guarda a sessão e abre as frações', (tester) async {
      Map<String, dynamic>? enviado;
      final store = MemoriaSessaoAdminStore();
      final api = ApiService(client: MockClient((req) async {
        if (req.method == 'POST' && req.url.path == '/condominios') {
          enviado = jsonDecode(req.body) as Map<String, dynamic>;
          return _json({
            'id': 7,
            'nome': 'Rua das Flores, 12',
            'n_fracoes': 2,
            'credencial_admin': 'cred-123',
            'fracoes': [
              {'id': 1, 'designacao': 'A'},
              {'id': 2, 'designacao': 'B'},
            ],
          }, 201);
        }
        return _json([
          {'id': 1, 'designacao': 'A', 'n_residentes': 0},
          {'id': 2, 'designacao': 'B', 'n_residentes': 0},
        ], 200);
      }));
      await tester.pumpWidget(_app(CriarCondominioScreen(api: api, store: store)));
      await tester.enterText(find.byKey(const Key('nome')), 'Rua das Flores, 12');
      await tester.enterText(find.byKey(const Key('nomeAdmin')), 'Ana Costa');
      await tester.enterText(find.byKey(const Key('nFracoes')), '2');
      await tester.tap(find.widgetWithText(FilledButton, 'Criar condomínio'));
      await tester.pumpAndSettle();

      expect(enviado, {'nome': 'Rua das Flores, 12', 'nome_admin': 'Ana Costa', 'n_fracoes': 2});
      expect(await store.ler(), _sessao);
      expect(find.byType(FracoesScreen), findsOneWidget);
      expect(find.text('Fração A'), findsOneWidget);
    });

    testWidgets('limite de pedidos (429) mostra mensagem', (tester) async {
      final api = ApiService(client: MockClient((_) async => _json({'detail': 'x'}, 429)));
      await tester.pumpWidget(_app(CriarCondominioScreen(api: api, store: MemoriaSessaoAdminStore())));
      await tester.enterText(find.byKey(const Key('nome')), 'Prédio');
      await tester.enterText(find.byKey(const Key('nomeAdmin')), 'Ana');
      await tester.enterText(find.byKey(const Key('nFracoes')), '3');
      await tester.tap(find.widgetWithText(FilledButton, 'Criar condomínio'));
      await tester.pumpAndSettle();
      expect(find.text('Demasiadas tentativas. Tente daqui a uma hora.'), findsOneWidget);
    });
  });

  testWidgets('lista de frações mostra designação e residentes, com credencial', (tester) async {
    String? authHeader;
    final api = ApiService(client: MockClient((req) async {
      authHeader = req.headers['Authorization'];
      expect(req.url.path, '/condominios/7/fracoes');
      return _json([
        {'id': 1, 'designacao': 'A', 'n_residentes': 0},
        {'id': 2, 'designacao': 'B', 'n_residentes': 3},
      ], 200);
    }));
    await tester.pumpWidget(_app(FracoesScreen(api: api, sessao: _sessao)));
    await tester.pumpAndSettle();
    expect(authHeader, 'Bearer cred-123');
    expect(find.text('Rua das Flores, 12'), findsOneWidget);
    expect(find.text('Fração A'), findsOneWidget);
    expect(find.text('0 residentes'), findsOneWidget);
    expect(find.text('3 residentes'), findsOneWidget);
  });

  group('QR da fração', () {
    testWidgets('antes de gerar não mostra QR', (tester) async {
      await tester.pumpWidget(_app(FracaoQrScreen(
        api: ApiService(client: MockClient((_) async => _json({}, 500))),
        sessao: _sessao,
        fracaoId: 1,
        designacao: 'A',
      )));
      expect(find.text('Gerar QR code'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('gerar mostra o QR com o link e as ações', (tester) async {
      final api = ApiService(client: MockClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/fracoes/1/qr');
        expect(req.headers['Authorization'], 'Bearer cred-123');
        return _json({
          'token': 'tok-abc',
          'link': 'domuscast://entrar?t=tok-abc',
          'fracao': 'A',
          'criado_em': '2026-11-16T14:02:00Z',
        }, 201);
      }));
      await tester.pumpWidget(_app(FracaoQrScreen(
        api: api,
        sessao: _sessao,
        fracaoId: 1,
        designacao: 'A',
      )));
      await tester.tap(find.text('Gerar QR code'));
      await tester.pumpAndSettle();

      // O QR codifica o link de entrada (a chave do widget é o conteúdo codificado).
      expect(
        find.byKey(const ValueKey('qr:domuscast://entrar?t=tok-abc')),
        findsOneWidget,
      );
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Partilhar'), findsOneWidget);
      expect(find.text('Ecrã inteiro'), findsOneWidget);
      expect(find.textContaining('Os QR codes gerados antes continuam válidos'), findsOneWidget);
    });

    testWidgets('erro ao gerar mostra mensagem', (tester) async {
      await tester.pumpWidget(_app(FracaoQrScreen(
        api: ApiService(client: MockClient((_) async => _json({}, 500))),
        sessao: _sessao,
        fracaoId: 1,
        designacao: 'A',
      )));
      await tester.tap(find.text('Gerar QR code'));
      await tester.pumpAndSettle();
      expect(find.text('Não foi possível gerar o QR code. Verifique a ligação.'), findsOneWidget);
    });
  });
}
