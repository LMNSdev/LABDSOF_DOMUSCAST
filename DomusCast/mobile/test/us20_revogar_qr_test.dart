// US-20: o administrador vê os QR codes ativos da fração e revoga um ou todos.
import 'dart:convert';

import 'package:domuscast/screens/fracao_qr_screen.dart';
import 'package:domuscast/services/api_service.dart';
import 'package:domuscast/services/sessao_admin.dart';
import 'package:domuscast/widgets/qr_codes_ativos.dart';
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

/// "16/11 às 14:32" na hora local da máquina que corre os testes.
String _dataHora(DateTime utc) {
  final d = utc.toLocal();
  String dois(int v) => v.toString().padLeft(2, '0');
  return '${dois(d.day)}/${dois(d.month)} às ${dois(d.hour)}:${dois(d.minute)}';
}

/// API falsa da fração 1, com os QR codes ativos em memória.
class _Servidor {
  List<Map<String, dynamic>> ativos;
  final pedidos = <String>[];
  int estadoRevogarUm = 200;

  _Servidor(this.ativos);

  ApiService get api => ApiService(client: MockClient((req) async {
        pedidos.add('${req.method} ${req.url.path}');
        expect(req.headers['Authorization'], 'Bearer cred-123');
        final path = req.url.path;
        if (req.method == 'GET' && path == '/fracoes/1/qr') return _json(ativos, 200);
        if (req.method == 'POST' && path == '/fracoes/1/qr/revogar') {
          final n = ativos.length;
          ativos = [];
          return _json({'revogados': n}, 200);
        }
        if (req.method == 'POST' && path == '/fracoes/1/qr') {
          ativos = [
            ...ativos,
            {'id': 9, 'criado_em': '2026-11-18T09:00:00Z', 'n_residentes': 0},
          ];
          return _json({
            'id': 9,
            'token': 'tok-novo',
            'link': 'domuscast://entrar?t=tok-novo',
            'fracao': 'A',
            'criado_em': '2026-11-18T09:00:00Z',
          }, 201);
        }
        final um = RegExp(r'^/qr/(\d+)/revogar$').firstMatch(path);
        if (req.method == 'POST' && um != null) {
          final id = int.parse(um.group(1)!);
          ativos = ativos.where((q) => q['id'] != id).toList();
          if (estadoRevogarUm != 200) {
            return _json({'codigo': 'nao_encontrado', 'mensagem': 'x', 'request_id': 'r'},
                estadoRevogarUm);
          }
          return _json({'revogados': 1}, 200);
        }
        return _json({}, 500);
      }));
}

List<Map<String, dynamic>> _doisAtivos() => [
      {'id': 1, 'criado_em': '2026-11-16T14:32:00Z', 'n_residentes': 3},
      {'id': 2, 'criado_em': '2026-11-17T10:05:00Z', 'n_residentes': 1},
    ];

Widget _secao(ApiService api, {void Function(int?)? onRevogado}) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: QrCodesAtivos(
            api: api,
            sessao: _sessao,
            fracaoId: 1,
            designacao: 'A',
            onRevogado: onRevogado,
          ),
        ),
      ),
    );

Finder _noDialogo(String texto) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(texto));

void main() {
  testWidgets('1. lista os QR codes ativos com data e residentes', (tester) async {
    final servidor = _Servidor(_doisAtivos());
    await tester.pumpWidget(_secao(servidor.api));
    await tester.pumpAndSettle();

    expect(find.text('QR codes ativos'), findsOneWidget);
    expect(find.text(_dataHora(DateTime.utc(2026, 11, 16, 14, 32))), findsOneWidget);
    expect(find.text(_dataHora(DateTime.utc(2026, 11, 17, 10, 5))), findsOneWidget);
    expect(find.text('3 residentes entraram'), findsOneWidget);
    expect(find.text('1 residente entrou'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Revogar'), findsNWidgets(2));
    expect(find.text('Revogar todos'), findsOneWidget);
  });

  testWidgets('2. revogar um pede confirmação e Cancelar não chama a API', (tester) async {
    final servidor = _Servidor(_doisAtivos());
    await tester.pumpWidget(_secao(servidor.api));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Revogar').first);
    await tester.pumpAndSettle();
    expect(find.text('Revogar este QR code?'), findsOneWidget);
    expect(
      find.text('Deixa de permitir novos acessos. '
          'Os 3 residentes que já entraram continuam com acesso.'),
      findsOneWidget,
    );

    await tester.tap(_noDialogo('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(servidor.pedidos.where((p) => p.startsWith('POST')), isEmpty);
  });

  testWidgets('2b. confirmar revoga, mostra 1 QR code revogado e recarrega', (tester) async {
    final servidor = _Servidor(_doisAtivos());
    int? revogado;
    await tester.pumpWidget(_secao(servidor.api, onRevogado: (id) => revogado = id));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Revogar').first);
    await tester.pumpAndSettle();
    await tester.tap(_noDialogo('Revogar'));
    await tester.pumpAndSettle();

    expect(servidor.pedidos, contains('POST /qr/1/revogar'));
    expect(find.text('1 QR code revogado.'), findsOneWidget);
    expect(find.text('3 residentes entraram'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Revogar'), findsOneWidget);
    expect(revogado, 1);
  });

  testWidgets('um QR code sem residentes só avisa que deixa de dar acesso', (tester) async {
    final servidor = _Servidor([
      {'id': 4, 'criado_em': '2026-11-17T10:05:00Z', 'n_residentes': 0},
    ]);
    await tester.pumpWidget(_secao(servidor.api));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Revogar'));
    await tester.pumpAndSettle();
    expect(_noDialogo('Deixa de permitir novos acessos.'), findsOneWidget);
  });

  testWidgets('3. revogar todos pede confirmação com a fração e mostra 2 QR codes revogados',
      (tester) async {
    final servidor = _Servidor(_doisAtivos());
    await tester.pumpWidget(_secao(servidor.api));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Revogar todos'));
    await tester.pumpAndSettle();
    expect(find.text('Revogar todos os QR codes da fração A?'), findsOneWidget);
    expect(
      find.text('Ninguém consegue entrar com eles. Quem já entrou mantém o acesso; '
          'para remover alguém, use a lista de residentes.'),
      findsOneWidget,
    );

    await tester.tap(_noDialogo('Revogar todos'));
    await tester.pumpAndSettle();
    expect(servidor.pedidos, contains('POST /fracoes/1/qr/revogar'));
    expect(find.text('2 QR codes revogados.'), findsOneWidget);
    expect(
      find.text('Nenhum QR code ativo. Gere um novo para dar acesso a um residente.'),
      findsOneWidget,
    );
  });

  testWidgets('4. sem QR codes ativos mostra o convite para gerar um novo', (tester) async {
    await tester.pumpWidget(_secao(_Servidor([]).api));
    await tester.pumpAndSettle();
    expect(
      find.text('Nenhum QR code ativo. Gere um novo para dar acesso a um residente.'),
      findsOneWidget,
    );
    expect(find.text('Revogar todos'), findsNothing);
  });

  testWidgets('QR já revogado (404) recarrega a lista com a mensagem própria', (tester) async {
    final servidor = _Servidor(_doisAtivos())..estadoRevogarUm = 404;
    await tester.pumpWidget(_secao(servidor.api));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Revogar').first);
    await tester.pumpAndSettle();
    await tester.tap(_noDialogo('Revogar'));
    await tester.pumpAndSettle();

    expect(find.text('Este QR code já tinha sido revogado.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Revogar'), findsOneWidget);
  });

  testWidgets('sem ligação ao revogar avisa que nada foi revogado', (tester) async {
    var chamadas = 0;
    final api = ApiService(client: MockClient((req) async {
      chamadas++;
      if (req.method == 'GET') return _json(_doisAtivos(), 200);
      throw http.ClientException('sem rede');
    }));
    await tester.pumpWidget(_secao(api));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Revogar todos'));
    await tester.pumpAndSettle();
    await tester.tap(_noDialogo('Revogar todos'));
    await tester.pumpAndSettle();

    expect(chamadas, greaterThan(1));
    expect(find.text('Sem ligação. O QR code não foi revogado.'), findsOneWidget);
  });

  testWidgets('erro ao carregar mostra mensagem e Tentar de novo', (tester) async {
    await tester.pumpWidget(_secao(ApiService(client: MockClient((_) async => _json({}, 500)))));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar os QR codes.'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
  });

  group('No ecrã da fração', () {
    Future<void> abrir(WidgetTester tester, _Servidor servidor) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: FracaoQrScreen(api: servidor.api, sessao: _sessao, fracaoId: 1, designacao: 'A'),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('gerar um QR novo atualiza a lista', (tester) async {
      final servidor = _Servidor([
        {'id': 1, 'criado_em': '2026-11-16T14:32:00Z', 'n_residentes': 3},
      ]);
      await abrir(tester, servidor);
      expect(find.widgetWithText(TextButton, 'Revogar'), findsOneWidget);

      await tester.tap(find.text('Gerar QR code'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextButton, 'Revogar'), findsNWidgets(2));
      expect(find.text('0 residentes entraram'), findsOneWidget);
    });

    testWidgets('revogar o QR mostrado tira-o do ecrã e volta Gerar QR code', (tester) async {
      final servidor = _Servidor([]);
      await abrir(tester, servidor);

      await tester.tap(find.text('Gerar QR code'));
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);

      await tester.tap(find.text('Revogar todos'));
      await tester.pumpAndSettle();
      await tester.tap(_noDialogo('Revogar todos'));
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('Gerar QR code'), findsOneWidget);
      expect(find.text('1 QR code revogado.'), findsOneWidget);
    });

    testWidgets('revogar na lista o QR mostrado tira-o do ecrã', (tester) async {
      final servidor = _Servidor([]);
      await abrir(tester, servidor);

      await tester.tap(find.text('Gerar QR code'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Revogar'));
      await tester.pumpAndSettle();
      await tester.tap(_noDialogo('Revogar'));
      await tester.pumpAndSettle();

      expect(servidor.pedidos, contains('POST /qr/9/revogar'));
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('Gerar QR code'), findsOneWidget);
    });

    testWidgets('revogar outro QR code mantém no ecrã o que acabou de ser gerado',
        (tester) async {
      final servidor = _Servidor([
        {'id': 1, 'criado_em': '2026-11-16T14:32:00Z', 'n_residentes': 3},
      ]);
      await abrir(tester, servidor);

      await tester.tap(find.text('Gerar QR code'));
      await tester.pumpAndSettle();
      // O mais antigo (id 1) aparece primeiro na lista.
      await tester.tap(find.widgetWithText(TextButton, 'Revogar').first);
      await tester.pumpAndSettle();
      await tester.tap(_noDialogo('Revogar'));
      await tester.pumpAndSettle();

      expect(servidor.pedidos, contains('POST /qr/1/revogar'));
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Partilhar'), findsOneWidget);
    });
  });
}
