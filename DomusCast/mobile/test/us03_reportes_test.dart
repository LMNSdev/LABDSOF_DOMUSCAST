import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:domuscast/local/queue_db.dart';
import 'package:domuscast/screens/reporte_detalhe_screen.dart';
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
  testWidgets('filtra os meus reportes por estado e abre o histórico', (
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

  testWidgets('administrador vê estados sem filtro Os meus', (
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

  testWidgets('atualiza de 30 em 30 segundos só no separador ativo', (
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

  testWidgets('suspende pedidos enquanto a app está em segundo plano', (
    tester,
  ) async {
    var calls = 0;
    final api = ApiService(client: MockClient((_) async {
      calls++;
      return jsonResponse([]);
    }));
    await tester.pumpWidget(MaterialApp(home: ReportesListScreen(
      api: api, credencial: 'admin', podeReportar: false,
    )));
    await tester.pumpAndSettle();
    expect(calls, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 31));
    expect(calls, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('falha no refresh mantém a lista carregada', (tester) async {
    var calls = 0;
    final api = ApiService(client: MockClient((_) async {
      calls++;
      if (calls > 1) throw http.ClientException('sem rede');
      return jsonResponse([{
        'id': 7, 'descricao': 'Elevador parado', 'estado': 'aberto',
        'criado_em': '2026-11-19T09:00:00Z',
        'atualizado_em': '2026-11-19T09:00:00Z',
      }]);
    }));
    await tester.pumpWidget(MaterialApp(home: ReportesListScreen(
      api: api, credencial: 'admin', podeReportar: false,
    )));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('Elevador parado'), findsOneWidget);
    expect(find.text('Sem ligação. A mostrar a última lista.'), findsOneWidget);
    expect(find.text('Sem ligação ao servidor'), findsNothing);
  });

  testWidgets('ignora resposta de filtro antigo', (tester) async {
    final oldResponse = Completer<http.Response>();
    final api = ApiService(client: MockClient((request) async {
      if (!request.url.queryParameters.containsKey('estado')) {
        return oldResponse.future;
      }
      return jsonResponse([{
        'id': 2, 'descricao': 'Reporte em curso', 'estado': 'em_curso',
        'criado_em': '2026-11-19T09:00:00Z',
        'atualizado_em': '2026-11-19T09:00:00Z',
      }]);
    }));
    await tester.pumpWidget(MaterialApp(home: ReportesListScreen(
      api: api, credencial: 'admin', podeReportar: false,
    )));
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Em curso'));
    await tester.pump();
    oldResponse.complete(jsonResponse([{
      'id': 1, 'descricao': 'Reporte antigo', 'estado': 'aberto',
      'criado_em': '2026-11-19T09:00:00Z',
      'atualizado_em': '2026-11-19T09:00:00Z',
    }]));
    await tester.pumpAndSettle();
    expect(find.text('Reporte antigo'), findsNothing);
    expect(find.text('Reporte em curso'), findsOneWidget);
  });

  testWidgets('detalhe atualiza o estado e o histórico aos 30 segundos', (
    tester,
  ) async {
    var calls = 0;
    final api = ApiService(client: MockClient((_) async {
      calls++;
      return jsonResponse({
        'id': 7, 'descricao': 'Elevador parado',
        'estado': calls == 1 ? 'aberto' : 'em_curso',
        'historico': [
          {'estado_novo': 'aberto', 'criado_em': '2026-11-19T09:00:00Z'},
          if (calls > 1) {'estado_novo': 'em_curso',
            'criado_em': '2026-11-20T10:00:00Z', 'nota': 'Técnico marcado'},
        ],
      });
    }));
    await tester.pumpWidget(MaterialApp(home: ReporteDetalheScreen(
      api: api, reporteId: 7, credencial: 'residente',
    )));
    await tester.pumpAndSettle();
    expect(find.text('Aberto'), findsWidgets);
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.textContaining('Técnico marcado'), findsOneWidget);
  });

  testWidgets('detalhe mostra erro de rede e sessão inválida', (tester) async {
    final rede = ApiService(client: MockClient((_) async =>
        throw http.ClientException('sem rede')));
    await tester.pumpWidget(MaterialApp(home: ReporteDetalheScreen(
      api: rede, reporteId: 7, credencial: 'admin',
    )));
    await tester.pumpAndSettle();
    expect(find.textContaining('Verifique a ligação'), findsOneWidget);

    final invalida = ApiService(client: MockClient((_) async =>
        jsonResponse({'codigo': 'nao_autenticado'}, 401)));
    await tester.pumpWidget(MaterialApp(home: ReporteDetalheScreen(
      key: const ValueKey('invalida'), api: invalida,
      reporteId: 7, credencial: 'admin',
    )));
    await tester.pumpAndSettle();
    expect(find.text('A sua sessão já não é válida.'), findsOneWidget);
  });

  testWidgets('detalhe do vizinho só mostra nome autorizado e foto com texto alternativo', (
    tester,
  ) async {
    final png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScL/nwAAAABJRU5ErkJggg==');
    final api = ApiService(client: MockClient((request) async {
      if (request.url.path.endsWith('/foto')) return http.Response.bytes(Uint8List.fromList(png), 200);
      return jsonResponse({
        'id': 7, 'descricao': 'Luz fundida', 'estado': 'aberto',
        'autor_nome': 'Ana Costa', 'fracao': null, 'meu': false,
        'foto_url': '/reportes/7/foto', 'foto_alt': 'Lâmpada fundida',
        'historico': [],
      });
    }));
    await tester.pumpWidget(MaterialApp(home: ReporteDetalheScreen(
      api: api, reporteId: 7, credencial: 'vizinho',
    )));
    await tester.pumpAndSettle();
    expect(find.text('Ana Costa'), findsOneWidget);
    expect(find.textContaining('fração'), findsNothing);
    expect(find.bySemanticsLabel('Lâmpada fundida'), findsOneWidget);
  });

  testWidgets('detalhe reutiliza a foto e mantém-na se o refresh falhar', (
    tester,
  ) async {
    final png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScL/nwAAAABJRU5ErkJggg==');
    var pedidosDetalhe = 0;
    var pedidosFoto = 0;
    final api = ApiService(client: MockClient((request) async {
      if (request.url.path.endsWith('/foto')) {
        pedidosFoto++;
        if (pedidosFoto == 2) throw http.ClientException('foto indisponível');
        return http.Response.bytes(Uint8List.fromList(png), 200);
      }
      pedidosDetalhe++;
      return jsonResponse({
        'id': 7,
        'descricao': 'Luz fundida',
        'estado': 'aberto',
        'foto_url': pedidosDetalhe >= 3
            ? '/reportes/7/foto?v=2'
            : '/reportes/7/foto',
        'foto_alt': pedidosDetalhe >= 3
            ? 'Nova lâmpada fundida'
            : 'Lâmpada fundida',
        'historico': [],
      });
    }));
    await tester.pumpWidget(MaterialApp(home: ReporteDetalheScreen(
      api: api, reporteId: 7, credencial: 'admin',
    )));
    await tester.pumpAndSettle();
    expect(pedidosFoto, 1);
    expect(find.bySemanticsLabel('Lâmpada fundida'), findsOneWidget);

    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(pedidosDetalhe, 2);
    expect(pedidosFoto, 1);

    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(pedidosFoto, 2);
    expect(find.bySemanticsLabel('Lâmpada fundida'), findsOneWidget);
    expect(find.bySemanticsLabel('Nova lâmpada fundida'), findsNothing);
    expect(find.text('Foto indisponível.'), findsNothing);

    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(pedidosFoto, 3);
    expect(find.bySemanticsLabel('Nova lâmpada fundida'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(pedidosFoto, 3);
  });

  testWidgets('administrador vê autor e fração na lista', (tester) async {
    final api = ApiService(client: MockClient((_) async => jsonResponse([{
      'id': 7, 'descricao': 'Luz fundida', 'estado': 'aberto',
      'autor_nome': 'Ana Costa', 'fracao': 'A', 'meu': false,
      'criado_em': '2026-11-19T09:00:00Z',
      'atualizado_em': '2026-11-19T09:00:00Z',
    }])));
    await tester.pumpWidget(MaterialApp(home: ReportesListScreen(
      api: api, credencial: 'admin', podeReportar: false,
    )));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ana Costa, fração A'), findsOneWidget);
  });
}
