// US-09: privacidade do nome em cada reporte (wireframe docs/sprintB/design/us-09.html).
import 'dart:convert';

import 'package:domuscast/screens/novo_reporte_screen.dart';
import 'package:domuscast/screens/reportes_list_screen.dart';
import 'package:domuscast/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> _reporte({
  required String descricao,
  bool mostrarNome = false,
  String? autorNome,
  String? fracao,
  bool meu = false,
}) =>
    {
      'id': descricao.hashCode,
      'descricao': descricao,
      'foto_url': null,
      'estado': 'aberto',
      'criado_em': '2026-11-18T10:00:00Z',
      'atualizado_em': '2026-11-18T10:00:00Z',
      'mostrar_nome': mostrarNome,
      'autor_nome': autorNome,
      'fracao': fracao,
      'meu': meu,
    };

Future<void> _abrirLista(
  WidgetTester tester,
  List<Map<String, dynamic>> reportes, {
  bool podeReportar = true,
}) async {
  final api = ApiService(client: MockClient((_) async => _json(reportes, 200)));
  await tester.pumpWidget(MaterialApp(
    home: ReportesListScreen(api: api, credencial: 'cred-1', podeReportar: podeReportar),
  ));
  await tester.pumpAndSettle();
}

const _desligado =
    'Desligado: os vizinhos veem "Residente". O administrador vê sempre o seu nome e fração.';

void main() {
  group('Formulário', () {
    testWidgets('1. opção do nome começa desligada e explica o efeito', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: NovoReporteScreen(credencial: 'cred-1', nome: 'Marta Silva'),
      ));

      final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(toggle.value, isFalse);
      expect(find.text('Mostrar o meu nome neste reporte'), findsOneWidget);
      expect(find.text(_desligado), findsOneWidget);
    });

    testWidgets('2. ligar a opção mostra o nome e envia mostrar_nome verdadeiro', (tester) async {
      Map<String, dynamic>? enviado;
      final api = ApiService(client: MockClient((req) async {
        enviado = jsonDecode(req.body) as Map<String, dynamic>;
        return _json(_reporte(descricao: 'Fuga', mostrarNome: true, meu: true), 201);
      }));

      await tester.pumpWidget(MaterialApp(
        home: NovoReporteScreen(credencial: 'cred-1', nome: 'Marta Silva', api: api),
      ));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      expect(
        find.text('Ligado: os vizinhos veem "Marta Silva". A fração continua escondida.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextFormField), 'Fuga');
      await tester.tap(find.text('Submeter reporte'));
      await tester.pumpAndSettle();
      expect(enviado?['mostrar_nome'], isTrue);
      expect(enviado?['descricao'], 'Fuga');
      expect(enviado?.keys, isNot(contains('telefone')));
    });

    testWidgets('sem ligar a opção envia mostrar_nome falso', (tester) async {
      Map<String, dynamic>? enviado;
      final api = ApiService(client: MockClient((req) async {
        enviado = jsonDecode(req.body) as Map<String, dynamic>;
        return _json(_reporte(descricao: 'Fuga', meu: true), 201);
      }));

      await tester.pumpWidget(MaterialApp(
        home: NovoReporteScreen(credencial: 'cred-1', nome: 'Marta Silva', api: api),
      ));
      await tester.enterText(find.byType(TextFormField), 'Fuga');
      await tester.tap(find.text('Submeter reporte'));
      await tester.pumpAndSettle();
      expect(enviado?['mostrar_nome'], isFalse);
    });

    testWidgets('credencial inválida (401) mostra a mensagem e não guarda offline', (tester) async {
      final api = ApiService(client: MockClient((_) async => _json({'detail': 'x'}, 401)));

      await tester.pumpWidget(MaterialApp(
        home: NovoReporteScreen(credencial: 'cred-1', api: api),
      ));
      await tester.enterText(find.byType(TextFormField), 'Fuga');
      await tester.tap(find.text('Submeter reporte'));
      await tester.pumpAndSettle();
      expect(
        find.text('A sua identidade já não é válida. Leia de novo o QR code da fração.'),
        findsOneWidget,
      );
      expect(find.text('Nova avaria'), findsOneWidget);
    });

    testWidgets('a opção do nome tem etiqueta para o leitor de ecrã', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(const MaterialApp(home: NovoReporteScreen(credencial: 'cred-1')));
      expect(
        find.bySemanticsLabel(RegExp('Mostrar o meu nome neste reporte')),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });

  group('Lista', () {
    testWidgets('3. outro residente vê "Residente" ou o nome mostrado, nunca a fração',
        (tester) async {
      await _abrirLista(tester, [
        _reporte(descricao: 'Fuga de água na garagem'),
        _reporte(descricao: 'Luz da escada fundida', mostrarNome: true, autorNome: 'Marta Silva'),
      ]);

      expect(find.textContaining('Residente - '), findsOneWidget);
      expect(find.textContaining('Marta Silva - '), findsOneWidget);
      expect(find.textContaining('fração'), findsNothing);
    });

    testWidgets('4. o autor vê "O meu reporte" e se o nome está visível', (tester) async {
      await _abrirLista(tester, [
        _reporte(descricao: 'Fuga de água na garagem', meu: true),
        _reporte(
          descricao: 'Luz da escada fundida',
          mostrarNome: true,
          autorNome: 'Marta Silva',
          meu: true,
        ),
      ]);

      expect(find.text('O meu reporte - nome oculto aos vizinhos'), findsOneWidget);
      expect(find.text('O meu reporte - nome visível aos vizinhos'), findsOneWidget);
    });

    testWidgets('5. o administrador vê nome e fração, e a etiqueta "nome visível"',
        (tester) async {
      await _abrirLista(
        tester,
        [
          _reporte(descricao: 'Fuga de água na garagem', autorNome: 'Marta Silva', fracao: 'C'),
          _reporte(
            descricao: 'Luz da escada fundida',
            mostrarNome: true,
            autorNome: 'Marta Silva',
            fracao: 'C',
          ),
        ],
        podeReportar: false,
      );

      expect(find.textContaining('Marta Silva, fração C - '), findsNWidgets(2));
      expect(find.text('nome visível'), findsOneWidget);
      expect(find.text('Reportar avaria'), findsNothing);
    });
  });
}
