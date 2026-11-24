import 'dart:convert';

import 'package:domuscast/local/queue_db.dart';
import 'package:domuscast/screens/reporte_detalhe_screen.dart';
import 'package:domuscast/screens/reportes_list_screen.dart';
import 'package:domuscast/services/api_service.dart';
import 'package:domuscast/widgets/estado_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> reporte(String estado, {List<Map<String, dynamic>>? historico}) => {
  'id': 104,
  'descricao': 'Fuga de água na garagem',
  'estado': estado,
  'criado_em': '2026-11-19T09:20:00Z',
  'atualizado_em': '2026-11-19T09:20:00Z',
  'meu': false,
  'autor_nome': 'Marta Silva',
  'fracao': 'A',
  'foto_url': null,
  'historico': historico ??
      [
        {'estado_novo': 'aberto', 'autor_tipo': 'sistema', 'criado_em': '2026-11-19T09:20:00Z'},
      ],
};

Future<void> abrirDetalhe(WidgetTester tester, ApiService api, {bool admin = true}) async {
  await tester.pumpWidget(MaterialApp(home: ReporteDetalheScreen(
    // Chave nova para um segundo detalhe no mesmo teste não reutilizar o estado anterior.
    key: UniqueKey(),
    api: api,
    credencial: admin ? 'admin' : 'residente',
    reporteId: 104,
    podeMudarEstado: admin,
  )));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('administrador muda o estado a partir da lista e vê o histórico', (tester) async {
    final pedidos = <http.Request>[];
    final api = ApiService(
      baseUrl: 'http://api.test',
      client: MockClient((request) async {
        pedidos.add(request);
        if (request.method == 'PATCH') {
          return jsonResponse(reporte('em_curso', historico: [
            {'estado_novo': 'aberto', 'autor_tipo': 'sistema', 'criado_em': '2026-11-19T09:20:00Z'},
            {
              'estado_anterior': 'aberto',
              'estado_novo': 'em_curso',
              'nota': 'Técnico contactado',
              'autor_tipo': 'administrador',
              'criado_em': '2026-11-19T10:15:00Z',
            },
          ]));
        }
        if (request.url.path == '/reportes/104') return jsonResponse(reporte('aberto'));
        return jsonResponse([reporte('aberto')]);
      }),
    );
    await tester.pumpWidget(MaterialApp(home: ReportesListScreen(
      api: api,
      credencial: 'admin',
      podeReportar: false,
      podeMudarEstado: true,
      fila: MemoriaFilaReportes(),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fuga de água na garagem'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Mudar estado'));
    await tester.pumpAndSettle();
    expect(find.text('Atualizar reporte'), findsOneWidget);
    expect(find.text('Em curso'), findsOneWidget);
    expect(find.text('A nota fica visível no histórico.'), findsOneWidget);

    // A nota é obrigatória: sem ela, não sai nenhum pedido.
    await tester.tap(find.text('Guardar alteração'));
    await tester.pumpAndSettle();
    expect(find.text('Escreva uma nota'), findsOneWidget);
    expect(pedidos.where((p) => p.method == 'PATCH'), isEmpty);

    await tester.enterText(find.byType(TextFormField), '  Técnico contactado ');
    await tester.tap(find.text('Guardar alteração'));
    await tester.pumpAndSettle();

    final patch = pedidos.singleWhere((p) => p.method == 'PATCH');
    expect(patch.url.path, '/reportes/104/estado');
    expect(patch.headers['Authorization'], 'Bearer admin');
    expect(jsonDecode(patch.body), {'estado': 'em_curso', 'nota': 'Técnico contactado'});

    expect(find.text('Atualizar reporte'), findsNothing);
    expect(find.text('Alteração guardada. O histórico não pode ser editado.'), findsOneWidget);
    expect(find.widgetWithText(EstadoBadge, 'Em curso'), findsOneWidget);
    expect(find.textContaining('Técnico contactado'), findsOneWidget);
    // Em curso ainda pode avançar para Resolvido.
    expect(find.widgetWithText(FilledButton, 'Mudar estado'), findsOneWidget);
  });

  testWidgets('detalhe segue o wireframe: título, histórico e botão fixo', (tester) async {
    final semantics = tester.ensureSemantics();
    final api = ApiService(client: MockClient((_) async => jsonResponse(reporte('em_curso', historico: [
      {'estado_novo': 'aberto', 'autor_tipo': 'sistema', 'criado_em': '2026-11-19T09:20:00Z'},
      {
        'estado_anterior': 'aberto',
        'estado_novo': 'em_curso',
        'nota': 'Técnico contactado',
        'autor_tipo': 'administrador',
        'criado_em': '2026-11-19T10:15:00Z',
      },
    ]))));
    await abrirDetalhe(tester, api);

    expect(find.text('Reporte #104'), findsOneWidget);
    expect(find.widgetWithText(EstadoBadge, 'Em curso'), findsOneWidget);
    expect(find.textContaining('estado inicial'), findsOneWidget);
    // A entrada mais recente aparece primeiro e é lida de uma só vez.
    expect(
      tester.getTopLeft(find.text('Técnico contactado')).dy,
      lessThan(tester.getTopLeft(find.textContaining('estado inicial')).dy),
    );
    expect(
      tester.getSemantics(find.text('Técnico contactado')).label,
      allOf(contains('Em curso'), contains('Técnico contactado')),
    );
    // O botão fica fixo por baixo do conteúdo, como na US-13.
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.bottomNavigationBar, isNotNull);
    semantics.dispose();
  });

  testWidgets('campo da nota é anunciado com o rótulo', (tester) async {
    final semantics = tester.ensureSemantics();
    final api = ApiService(client: MockClient((_) async => jsonResponse(reporte('aberto'))));
    await abrirDetalhe(tester, api);
    await tester.tap(find.widgetWithText(FilledButton, 'Mudar estado'));
    await tester.pumpAndSettle();

    final campo = tester.getSemantics(find.byType(EditableText));
    expect(campo.label, contains('Nota obrigatória'));
    expect(campo, isSemantics(isTextField: true));
    expect(
      tester.getSemantics(find.widgetWithText(EstadoBadge, 'Em curso')).label,
      allOf(contains('Novo estado'), contains('Em curso')),
    );
    semantics.dispose();
  });

  testWidgets('em curso só pode passar a resolvido', (tester) async {
    final api = ApiService(client: MockClient((_) async => jsonResponse(reporte('em_curso'))));
    await abrirDetalhe(tester, api);
    await tester.tap(find.widgetWithText(FilledButton, 'Mudar estado'));
    await tester.pumpAndSettle();
    expect(find.text('Resolvido'), findsOneWidget);
  });

  testWidgets('residente e reporte resolvido não mostram Mudar estado', (tester) async {
    final aberto = ApiService(client: MockClient((_) async => jsonResponse(reporte('aberto'))));
    await abrirDetalhe(tester, aberto, admin: false);
    expect(find.text('Mudar estado'), findsNothing);

    final resolvido = ApiService(client: MockClient((_) async => jsonResponse(reporte('resolvido'))));
    await abrirDetalhe(tester, resolvido);
    expect(find.text('Mudar estado'), findsNothing);
  });

  testWidgets('conflito mostra a falha e volta ao detalhe sem repetir o pedido', (tester) async {
    var gets = 0;
    var patches = 0;
    final api = ApiService(client: MockClient((request) async {
      if (request.method == 'PATCH') {
        patches++;
        return jsonResponse({
          'codigo': 'transicao_invalida',
          'mensagem': 'O reporte está Em curso; só pode passar para Resolvido.',
          'request_id': 'abc',
        }, 409);
      }
      gets++;
      return jsonResponse(reporte(gets == 1 ? 'aberto' : 'em_curso'));
    }));
    await abrirDetalhe(tester, api);
    await tester.tap(find.widgetWithText(FilledButton, 'Mudar estado'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Técnico contactado');
    await tester.tap(find.text('Guardar alteração'));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível guardar a alteração.'), findsOneWidget);
    expect(find.textContaining('atualizado noutro dispositivo'), findsOneWidget);
    expect(find.text('Guardar alteração'), findsNothing);

    await tester.tap(find.text('Voltar ao detalhe'));
    await tester.pumpAndSettle();
    expect(patches, 1);
    expect(gets, 2);
    expect(find.widgetWithText(EstadoBadge, 'Em curso'), findsOneWidget);
  });

  testWidgets('sem ligação não apresenta a alteração como guardada', (tester) async {
    final api = ApiService(client: MockClient((request) async {
      if (request.method == 'PATCH') throw http.ClientException('sem rede');
      return jsonResponse(reporte('aberto'));
    }));
    await abrirDetalhe(tester, api);
    await tester.tap(find.widgetWithText(FilledButton, 'Mudar estado'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Técnico contactado');
    await tester.tap(find.text('Guardar alteração'));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível guardar a alteração.'), findsOneWidget);
    expect(find.textContaining('Sem ligação'), findsOneWidget);
    await tester.tap(find.text('Voltar ao detalhe'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Alteração guardada'), findsNothing);
    expect(find.widgetWithText(EstadoBadge, 'Aberto'), findsOneWidget);
  });

  testWidgets('nota recusada pela API fica no formulário para corrigir', (tester) async {
    final api = ApiService(client: MockClient((request) async {
      if (request.method == 'PATCH') {
        return jsonResponse({'codigo': 'dados_invalidos', 'mensagem': 'x', 'request_id': 'r'}, 422);
      }
      return jsonResponse(reporte('aberto'));
    }));
    await abrirDetalhe(tester, api);
    await tester.tap(find.widgetWithText(FilledButton, 'Mudar estado'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Nota');
    await tester.tap(find.text('Guardar alteração'));
    await tester.pumpAndSettle();

    expect(find.textContaining('entre 1 e 500 caracteres'), findsOneWidget);
    expect(find.text('Guardar alteração'), findsOneWidget);
  });

  testWidgets('erros são anunciados ao leitor de ecrã', (tester) async {
    final semantics = tester.ensureSemantics();
    final api = ApiService(client: MockClient((request) async {
      if (request.method == 'PATCH') return jsonResponse({'codigo': 'servico_indisponivel'}, 503);
      return jsonResponse(reporte('aberto'));
    }));
    await abrirDetalhe(tester, api);
    await tester.tap(find.widgetWithText(FilledButton, 'Mudar estado'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Nota');
    await tester.tap(find.text('Guardar alteração'));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.text('Não foi possível guardar a alteração.')),
      matchesSemantics(isLiveRegion: true, label: 'Não foi possível guardar a alteração.'),
    );
    semantics.dispose();
  });
}
