// US-13: agendar reunião (administrador) e lista das reuniões.
import 'dart:convert';

import 'package:domuscast/screens/nova_reuniao_screen.dart';
import 'package:domuscast/screens/reunioes_screen.dart';
import 'package:domuscast/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> _reuniao(int id, DateTime quando,
        {String local = 'Sala do condomínio', String estado = 'pendente'}) =>
    {
      'id': id,
      'data_hora': quando.toUtc().toIso8601String(),
      'local': local,
      'estado_sync': estado,
      'criado_em': DateTime.now().toUtc().toIso8601String(),
    };

final _dia = DateTime(2030, 11, 25);
const _hora = TimeOfDay(hour: 19, minute: 0);

Widget _lista(ApiService api) =>
    MaterialApp(home: ReunioesScreen(api: api, credencial: 'cred-123'));

/// Abre o formulário por cima de outro ecrã, como na app, para poder fechar.
Future<void> _abrirForm(WidgetTester tester, ApiService api,
    {DateTime? dia, TimeOfDay? hora, bool seletores = true}) async {
  final nav = GlobalKey<NavigatorState>();
  await tester.pumpWidget(MaterialApp(navigatorKey: nav, home: const Scaffold()));
  nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => NovaReuniaoScreen(
      api: api,
      credencial: 'cred-123',
      escolherData: seletores ? (_, __) async => dia ?? _dia : null,
      escolherHora: seletores ? (_, __) async => hora ?? _hora : null,
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _preencher(WidgetTester tester, {String local = 'Sala do condomínio'}) async {
  await tester.tap(find.widgetWithText(TextFormField, 'Data'));
  await tester.pump();
  await tester.tap(find.widgetWithText(TextFormField, 'Hora (Portugal continental)'));
  await tester.pump();
  await tester.enterText(find.widgetWithText(TextFormField, 'Local'), local);
}

Future<void> _submeter(WidgetTester tester, [String botao = 'Agendar']) async {
  await tester.tap(find.widgetWithText(FilledButton, botao));
  await tester.pumpAndSettle();
}

void main() {
  group('Lista do administrador', () {
    testWidgets('2. mostra data, hora, local e a publicação pendente', (tester) async {
      String? authorization;
      final api = ApiService(client: MockClient((req) async {
        authorization = req.headers['authorization'];
        return _json([_reuniao(1, DateTime(2030, 11, 25, 19))], 200);
      }));
      await tester.pumpWidget(_lista(api));
      await tester.pumpAndSettle();

      expect(authorization, 'Bearer cred-123');
      expect(find.text('Assembleia de condóminos'), findsOneWidget);
      expect(
        find.text('25/11/2030 às 19:00\nSala do condomínio\nPublicação no calendário pendente'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Agendar reunião'), findsOneWidget);
    });

    testWidgets('mostra os outros estados da publicação', (tester) async {
      final api = ApiService(client: MockClient((_) async => _json([
            _reuniao(1, DateTime(2030, 11, 25, 19), estado: 'sincronizada'),
            _reuniao(2, DateTime(2030, 12, 2, 19), estado: 'alternativo'),
          ], 200)));
      await tester.pumpWidget(_lista(api));
      await tester.pumpAndSettle();

      expect(find.textContaining('Publicada no calendário'), findsOneWidget);
      expect(find.textContaining('só no feed iCal'), findsOneWidget);
    });

    testWidgets('3. estado vazio convida a agendar', (tester) async {
      final api = ApiService(client: MockClient((_) async => _json([], 200)));
      await tester.pumpWidget(_lista(api));
      await tester.pumpAndSettle();

      expect(find.text('Ainda não há reuniões agendadas.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Agendar reunião'), findsOneWidget);
    });

    testWidgets('erro ao carregar mostra Tentar novamente, que volta a pedir', (tester) async {
      var pedidos = 0;
      final api = ApiService(client: MockClient((_) async {
        pedidos++;
        return pedidos == 1 ? _json({}, 503) : _json([], 200);
      }));
      await tester.pumpWidget(_lista(api));
      await tester.pumpAndSettle();
      expect(find.text('Não foi possível carregar as reuniões.'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(pedidos, 2);
      expect(find.text('Ainda não há reuniões agendadas.'), findsOneWidget);
    });

    testWidgets('residente não vê o agendamento nem chama a API', (tester) async {
      var pedidos = 0;
      final api = ApiService(client: MockClient((_) async {
        pedidos++;
        return _json([], 200);
      }));
      await tester.pumpWidget(MaterialApp(home: ReunioesScreen(api: api)));
      await tester.pumpAndSettle();

      expect(find.text('As reuniões vão aparecer aqui.'), findsOneWidget);
      expect(find.text('Agendar reunião'), findsNothing);
      expect(pedidos, 0);
    });

    testWidgets('quando o formulário confirma, volta à lista atualizada com a confirmação',
        (tester) async {
      final reunioes = <Map<String, dynamic>>[];
      final api = ApiService(client: MockClient((_) async => _json(reunioes, 200)));
      await tester.pumpWidget(_lista(api));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Agendar reunião'));
      await tester.pumpAndSettle();
      expect(find.byType(NovaReuniaoScreen), findsOneWidget);

      // O envio do formulário é testado no grupo "Formulário"; aqui só o regresso.
      reunioes.add(_reuniao(1, DateTime(2030, 11, 25, 19)));
      Navigator.of(tester.element(find.byType(NovaReuniaoScreen))).pop(true);
      await tester.pumpAndSettle();

      expect(find.byType(NovaReuniaoScreen), findsNothing);
      expect(find.text('Reunião agendada.'), findsOneWidget);
      expect(find.text('Assembleia de condóminos'), findsOneWidget);
    });
  });

  group('Formulário', () {
    testWidgets('1. envia a data e a hora em UTC e o local, e fecha', (tester) async {
      Map<String, dynamic>? enviado;
      final api = ApiService(client: MockClient((req) async {
        enviado = jsonDecode(req.body) as Map<String, dynamic>;
        expect(req.headers['authorization'], 'Bearer cred-123');
        return _json(_reuniao(1, DateTime(2030, 11, 25, 19)), 201);
      }));
      await _abrirForm(tester, api);
      await _preencher(tester, local: '  Sala do condomínio  ');

      expect(find.text('25/11/2030'), findsOneWidget);
      expect(find.text('19:00'), findsOneWidget);
      await _submeter(tester);

      expect(enviado, {
        'data_hora': DateTime(2030, 11, 25, 19).toUtc().toIso8601String(),
        'local': 'Sala do condomínio',
      });
      expect(find.byType(NovaReuniaoScreen), findsNothing);
    });

    testWidgets('campos vazios mostram os erros e não chamam a API', (tester) async {
      var pedidos = 0;
      final api = ApiService(client: MockClient((_) async {
        pedidos++;
        return _json({}, 500);
      }));
      await tester.pumpWidget(MaterialApp(
        home: NovaReuniaoScreen(api: api, credencial: 'cred-123'),
      ));
      await _submeter(tester);

      expect(find.text('Escolha a data'), findsOneWidget);
      expect(find.text('Escolha a hora'), findsOneWidget);
      expect(find.text('Indique o local'), findsOneWidget);
      expect(pedidos, 0);
    });

    testWidgets('data no passado é recusada sem chamar a API', (tester) async {
      var pedidos = 0;
      final api = ApiService(client: MockClient((_) async {
        pedidos++;
        return _json({}, 500);
      }));
      final ontem = DateTime.now().subtract(const Duration(days: 1));
      await _abrirForm(tester, api, dia: ontem);
      await _preencher(tester);
      await _submeter(tester);

      expect(find.text('A reunião tem de ser no futuro'), findsOneWidget);
      expect(pedidos, 0);
    });

    testWidgets('4. sem ligação não diz que guardou e Tentar novamente reenvia', (tester) async {
      var pedidos = 0;
      final api = ApiService(client: MockClient((_) async {
        pedidos++;
        if (pedidos == 1) throw http.ClientException('sem rede');
        return _json(_reuniao(1, DateTime(2030, 11, 25, 19)), 201);
      }));
      await _abrirForm(tester, api);
      await _preencher(tester);
      await _submeter(tester);

      expect(find.text('Não foi possível guardar a reunião. Verifique a ligação.'), findsOneWidget);
      expect(find.textContaining('fila'), findsNothing);
      expect(find.byType(NovaReuniaoScreen), findsOneWidget);

      await _submeter(tester, 'Tentar novamente');
      expect(pedidos, 2);
      expect(find.byType(NovaReuniaoScreen), findsNothing);
    });

    for (final (status, mensagem) in [
      (422, 'Verifique a data e o local. A reunião tem de ser no futuro.'),
      (403, 'Só o administrador pode agendar reuniões.'),
      (503, 'O serviço está indisponível. Tente novamente daqui a pouco.'),
    ]) {
      testWidgets('erro $status mostra a mensagem própria e mantém os dados', (tester) async {
        final api = ApiService(client: MockClient((_) async => _json({'codigo': 'x'}, status)));
        await _abrirForm(tester, api);
        await _preencher(tester);
        await _submeter(tester);

        expect(find.text(mensagem), findsOneWidget);
        expect(find.text('Sala do condomínio'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Agendar'), findsOneWidget);
      });
    }

    testWidgets('campos e botão têm etiqueta e ação para o leitor de ecrã', (tester) async {
      final handle = tester.ensureSemantics();
      final api = ApiService(client: MockClient((_) async => _json({}, 500)));
      await _abrirForm(tester, api);

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      for (final rotulo in ['Data', 'Hora (Portugal continental)', 'Local', 'Agendar']) {
        final no = tester.getSemantics(find.bySemanticsLabel(RegExp('^${RegExp.escape(rotulo)}')).first);
        expect(no.getSemanticsData().hasAction(SemanticsAction.tap), isTrue, reason: rotulo);
      }
      handle.dispose();
    });
  });
}
