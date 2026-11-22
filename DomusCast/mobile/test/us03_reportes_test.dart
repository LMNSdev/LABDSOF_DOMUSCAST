import 'dart:convert';

import 'package:domuscast/local/queue_db.dart';
import 'package:domuscast/screens/reportes_list_screen.dart';
import 'package:domuscast/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  testWidgets('filters by ownership and status, then opens history', (
    tester,
  ) async {
    final requested = <Uri>[];
    final api = ApiService(
      baseUrl: 'http://api.test',
      client: MockClient((request) async {
        requested.add(request.url);
        if (request.url.path == '/reportes/7') {
          return jsonResponse({
            'id': 7,
            'descricao': 'Elevador parado',
            'estado': 'em_curso',
            'criado_em': '2026-11-19T09:00:00Z',
            'atualizado_em': '2026-11-20T10:00:00Z',
            'meu': true,
            'foto_url': null,
            'historico': [
              {'estado_novo': 'aberto', 'criado_em': '2026-11-19T09:00:00Z'},
              {
                'estado_novo': 'em_curso',
                'criado_em': '2026-11-20T10:00:00Z',
                'nota': 'Técnico agendado',
              },
            ],
          });
        }
        return jsonResponse([
          {
            'id': 7,
            'descricao': 'Elevador parado',
            'estado': 'em_curso',
            'criado_em': '2026-11-19T09:00:00Z',
            'atualizado_em': '2026-11-20T10:00:00Z',
            'meu': true,
          },
        ]);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReportesListScreen(
          api: api,
          credencial: 'residente',
          fila: MemoriaFilaReportes(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Elevador parado'), findsOneWidget);
    await tester.tap(find.text('Os meus'));
    await tester.pumpAndSettle();
    expect(requested.last.queryParameters['filtro'], 'meus');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Em curso'));
    await tester.pumpAndSettle();
    expect(requested.last.queryParameters['estado'], 'em_curso');
    await tester.tap(find.text('Elevador parado'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico'), findsOneWidget);
    expect(find.textContaining('Técnico agendado'), findsOneWidget);
  });

  testWidgets('administrator sees status filters without ownership filter', (
    tester,
  ) async {
    final api = ApiService(client: MockClient((_) async => jsonResponse([])));
    await tester.pumpWidget(
      MaterialApp(
        home: ReportesListScreen(
          api: api,
          credencial: 'admin',
          podeReportar: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Os meus'), findsNothing);
    expect(find.text('Qualquer estado'), findsOneWidget);
    expect(find.text('Nenhum reporte ainda'), findsOneWidget);
  });

  testWidgets('refreshes every 30 seconds only while tab is active', (
    tester,
  ) async {
    var calls = 0;
    final active = ValueNotifier<bool>(true);
    final api = ApiService(
      client: MockClient((_) async {
        calls++;
        return jsonResponse([]);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReportesListScreen(
          api: api,
          credencial: 'admin',
          podeReportar: false,
          ativo: active,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);
    active.value = false;
    await tester.pump(const Duration(seconds: 31));
    expect(calls, 1);
    active.value = true;
    await tester.pumpAndSettle();
    expect(calls, 2);
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(calls, 3);
    await tester.pumpWidget(const SizedBox.shrink());
    active.dispose();
  });
}
