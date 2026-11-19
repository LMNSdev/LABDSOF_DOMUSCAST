import 'dart:convert';
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
    expect(find.text('Nova avaria'), findsOneWidget);
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
    await tester.ensureVisible(find.text('Submeter reporte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submeter reporte'));
    await tester.pumpAndSettle();

    expect(find.text('Descreve a foto ou remove-a.'), findsOneWidget);
    expect(find.textContaining('identificação do residente'), findsNothing);
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
