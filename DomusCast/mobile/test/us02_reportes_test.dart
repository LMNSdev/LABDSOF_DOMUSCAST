import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:domuscast/screens/novo_reporte_screen.dart';
import 'package:domuscast/screens/reportes_list_screen.dart';
import 'package:domuscast/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

http.Response _json(Object body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  group('POST /reportes', () {
    for (final status in [200, 201]) {
      test('envia multipart com autenticação e aceita HTTP $status', () async {
        http.Request? enviado;
        final api = ApiService(
          baseUrl: 'http://api.test',
          client: MockClient((request) async {
            enviado = request;
            return _json({'id': 42}, status);
          }),
        );

        final resultado = await api.criarReporte(
          credencial: 'credencial-residente',
          descricao: 'Fuga de água',
          fotoBytes: Uint8List.fromList([1, 2, 3]),
          fotoNome: 'fuga.jpg',
          fotoAlt: 'Poça no chão',
          mostrarNome: false,
          idempotencyKey: 'chave-unica',
        );

        expect(resultado['id'], 42);
        expect(enviado!.url.path, '/reportes');
        expect(
            enviado!.headers['Authorization'], 'Bearer credencial-residente');
        expect(enviado!.headers['Idempotency-Key'], 'chave-unica');
        expect(enviado!.headers['content-type'],
            startsWith('multipart/form-data; boundary='));
        final corpo = utf8.decode(enviado!.bodyBytes);
        expect(corpo, contains('name="descricao"'));
        expect(corpo, contains('Fuga de água'));
        expect(corpo, contains('name="foto_alt"'));
        expect(corpo, contains('Poça no chão'));
        expect(corpo, contains('name="mostrar_nome"'));
        expect(corpo, contains('name="foto"; filename="fuga.jpg"'));
        expect(corpo, contains('content-type: image/jpeg'));
      });
    }

    test('envia multipart sem foto e usa mostrar_nome falso por omissão',
        () async {
      http.Request? enviado;
      final api = ApiService(
        baseUrl: 'http://api.test',
        client: MockClient((request) async {
          enviado = request;
          return _json({'id': 7}, 201);
        }),
      );

      await api.criarReporte(
        credencial: 'credencial-residente',
        descricao: 'Elevador parado',
        idempotencyKey: 'chave-sem-foto',
      );

      expect(enviado!.headers['content-type'],
          startsWith('multipart/form-data; boundary='));
      final corpo = utf8.decode(enviado!.bodyBytes);
      expect(corpo, contains('Elevador parado'));
      expect(corpo, contains('name="mostrar_nome"'));
      expect(corpo, isNot(contains('name="foto";')));
    });

    test('converte erros da API em ApiException com a mensagem do contrato',
        () async {
      final api = ApiService(
        baseUrl: 'http://api.test',
        client: MockClient((_) async => _json({
              'codigo': 'dados_invalidos',
              'mensagem': 'A descrição é obrigatória.',
              'request_id': 'request-1',
            }, 422)),
      );

      await expectLater(
        api.criarReporte(
          credencial: 'credencial-residente',
          descricao: 'Fuga',
          idempotencyKey: 'chave-erro',
        ),
        throwsA(
          isA<ApiException>()
              .having((erro) => erro.statusCode, 'statusCode', 422)
              .having((erro) => erro.codigo, 'codigo', 'dados_invalidos')
              .having((erro) => erro.mensagem, 'mensagem',
                  'A descrição é obrigatória.'),
        ),
      );
    });
  });

  testWidgets('formulário apresenta foto opcional e privacidade desligada',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NovoReporteScreen(
            api: ApiService(client: MockClient((_) async => _json({}, 500)))),
      ),
    );

    expect(find.text('Adicionar foto (opcional)'), findsOneWidget);
    expect(find.text('Mostrar o meu nome neste reporte'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse);
    expect(find.textContaining('Não incluas dados pessoais de terceiros'),
        findsOneWidget);
  });

  testWidgets('sem credencial, mantém o formulário e não chama a API',
      (tester) async {
    var chamadas = 0;
    final api = ApiService(
      client: MockClient((_) async {
        chamadas++;
        return _json({}, 201);
      }),
    );

    await tester.pumpWidget(MaterialApp(home: NovoReporteScreen(api: api)));
    await tester.enterText(find.byType(TextFormField).first, 'Fuga na garagem');
    await tester.tap(find.text('Submeter reporte'));
    await tester.pump();

    expect(chamadas, 0);
    expect(find.textContaining('Identifica-te através do QR code da fração'),
        findsOneWidget);
    expect(find.byKey(const Key('aviso-popup')), findsOneWidget);
    expect(find.text('Nova avaria'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('confirma reporte no topo da lista após criar', (tester) async {
    var reportesCarregados = 0;
    final api = ApiService(
      client: MockClient((request) async {
        if (request.method == 'POST') return _json({'id': 42}, 201);
        reportesCarregados++;
        return _json(
          reportesCarregados == 1
              ? []
              : [
                  {
                    'id': 42,
                    'descricao': 'Fuga na garagem',
                    'estado': 'aberto',
                    'criado_em': '2026-11-19T19:00:00',
                  }
                ],
          200,
        );
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ReportesListScreen(
          api: api,
          credencialResidente: 'credencial-residente',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reportar avaria'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Fuga na garagem');
    await tester.ensureVisible(find.text('Submeter reporte'));
    await tester.tap(find.text('Submeter reporte'));
    await tester.pumpAndSettle();

    expect(find.text('Reporte enviado. Estado: Aberto.'), findsOneWidget);
    expect(find.text('Fuga na garagem'), findsOneWidget);
    expect(
        tester.getTopLeft(find.text('Fuga na garagem')).dy, greaterThan(120));
    final popup = tester.widget<Positioned>(
      find
          .ancestor(
            of: find.byKey(const Key('aviso-popup')),
            matching: find.byType(Positioned),
          )
          .first,
    );
    expect(popup.top, 64);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aviso-popup')), findsNothing);
    expect(tester.getTopLeft(find.text('Fuga na garagem')).dy, lessThan(120));
  });

  testWidgets('foto escolhida exige texto alternativo', (tester) async {
    final api = ApiService(
      client: MockClient((_) async => _json({}, 201)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NovoReporteScreen(
          api: api,
          escolherImagem: (_) async => XFile.fromData(
            Uint8List.fromList([1, 2, 3]),
            name: 'foto.png',
            mimeType: 'image/png',
          ),
        ),
      ),
    );

    await tester.tap(find.text('Adicionar foto (opcional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escolher da galeria'));
    await tester.pumpAndSettle();
    final previewImage = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('foto-preview')),
        matching: find.byType(Image),
      ),
    );
    expect(previewImage.fit, BoxFit.contain);
    expect(previewImage.width, double.infinity);
    expect(
      tester.getSize(find.byKey(const Key('foto-preview'))).width,
      tester.view.physicalSize.width / tester.view.devicePixelRatio - 40,
    );
    await tester.ensureVisible(find.text('Submeter reporte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submeter reporte'));
    await tester.pumpAndSettle();

    expect(find.text('Descreve a foto ou remove-a.'), findsOneWidget);
    expect(find.textContaining('identificação do residente'), findsNothing);
  });

  testWidgets('pré-visualização abre foto inteira com zoom e etiqueta',
      (tester) async {
    final semantica = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: NovoReporteScreen(
          api: ApiService(client: MockClient((_) async => _json({}, 500))),
          escolherImagem: (_) async => XFile.fromData(
            base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/Y5sAAAAASUVORK5CYII=',
            ),
            name: 'foto.png',
            mimeType: 'image/png',
          ),
        ),
      ),
    );

    await tester.tap(find.text('Adicionar foto (opcional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escolher da galeria'));
    await tester.pumpAndSettle();

    final previewSemantics =
        tester.getSemantics(find.byKey(const Key('foto-preview')));
    expect(previewSemantics.label, contains('Ampliar foto'));
    expect(previewSemantics.hint, contains('ecrã inteiro'));
    await tester.enterText(
      find.byType(TextFormField).last,
      'Foto de telha partida',
    );

    await tester.tap(find.byKey(const Key('foto-preview')));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.bySemanticsLabel('Foto de telha partida'), findsOneWidget);
    await tester.tap(find.byTooltip('Fechar pré-visualização'));
    await tester.pumpAndSettle();
    semantica.dispose();
  });

  testWidgets('envio mostra progresso e nova tentativa reutiliza a chave',
      (tester) async {
    final chaves = <String>[];
    final bloqueio = Completer<void>();
    var tentativas = 0;
    final api = ApiService(
      client: MockClient((request) async {
        chaves.add(request.headers['Idempotency-Key']!);
        tentativas++;
        if (tentativas == 1) {
          await bloqueio.future;
          throw http.ClientException('Sem ligação');
        }
        return _json({'id': 42}, 201);
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => NovoReporteScreen(
                    api: api,
                    credencialResidente: 'credencial-residente',
                  ),
                ),
              ),
              child: const Text('Abrir formulário'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir formulário'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Fuga na garagem');
    await tester.ensureVisible(find.text('Submeter reporte'));
    await tester.tap(find.text('Submeter reporte'));
    await tester.pump();

    expect(find.text('A enviar o reporte. Aguarda.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'A enviar...'),
          )
          .onPressed,
      isNull,
    );

    bloqueio.complete();
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('aviso-popup')),
        matching: find.textContaining('Os dados ficam no formulário'),
      ),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.text('Fuga na garagem'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.ensureVisible(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(tentativas, 2);
    expect(chaves, hasLength(2));
    expect(chaves[0], chaves[1]);
  });

  testWidgets('recusa foto acima de 5 MB', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NovoReporteScreen(
          api: ApiService(client: MockClient((_) async => _json({}, 201))),
          escolherImagem: (_) async => XFile.fromData(
            Uint8List(5 * 1024 * 1024 + 1),
            name: 'foto.jpg',
            mimeType: 'image/jpeg',
          ),
        ),
      ),
    );

    await tester.tap(find.text('Adicionar foto (opcional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escolher da galeria'));
    await tester.pumpAndSettle();

    expect(find.text('A foto não pode exceder 5 MB.'), findsOneWidget);
    expect(find.text('Adicionar foto (opcional)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('permite tirar uma fotografia com a câmara', (tester) async {
    ImageSource? fonteEscolhida;
    await tester.pumpWidget(
      MaterialApp(
        home: NovoReporteScreen(
          api: ApiService(client: MockClient((_) async => _json({}, 201))),
          escolherImagem: (fonte) async {
            fonteEscolhida = fonte;
            return XFile.fromData(
              Uint8List.fromList([1, 2, 3]),
              name: 'camera.jpg',
              mimeType: 'image/jpeg',
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Adicionar foto (opcional)'));
    await tester.pumpAndSettle();
    expect(find.text('Escolher da galeria'), findsOneWidget);
    expect(find.text('Tirar fotografia'), findsOneWidget);

    await tester.tap(find.text('Tirar fotografia'));
    await tester.pumpAndSettle();

    expect(fonteEscolhida, ImageSource.camera);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('administrador não vê a ação de criar reporte', (tester) async {
    final api = ApiService(
      client: MockClient((_) async => _json([], 200)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReportesListScreen(api: api, podeReportar: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
