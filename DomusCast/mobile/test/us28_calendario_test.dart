// US-28: estado da publicação no calendário externo e lista guardada no dispositivo.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:domuscast/local/reunioes_cache.dart';
import 'package:domuscast/screens/reunioes_screen.dart';
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

Map<String, dynamic> _reuniao(int id, {String estado = 'pendente', String local = 'Sala do condomínio'}) => {
      'id': id,
      'data_hora': DateTime(2030, 11, 25, 19).toUtc().toIso8601String(),
      'local': local,
      'estado_sync': estado,
      'criado_em': '2026-11-24T10:00:00Z',
      'atualizado_em': '2026-11-24T10:00:00Z',
    };

const _condominio = 7;

Widget _lista(ApiService api, CacheReunioes cache, {int condominioId = _condominio}) => MaterialApp(
    home: ReunioesScreen(api: api, credencial: 'cred-123', condominioId: condominioId, cache: cache));

/// Cache com a lista [reunioes] guardada para o condomínio dos testes.
MemoriaCacheReunioes _guardada(List<Map<String, dynamic>> reunioes) =>
    MemoriaCacheReunioes({_condominio: reunioes});

ApiService _api(Future<http.Response> Function(http.Request) tratar) =>
    ApiService(client: MockClient(tratar));

const _avisoGuardadas = 'Não foi possível atualizar. A mostrar dados guardados no dispositivo.';

void main() {
  testWidgets('1. pendente: estado e nota de sincronização automática', (tester) async {
    await tester.pumpWidget(_lista(_api((_) async => _json([_reuniao(1)], 200)), MemoriaCacheReunioes()));
    await tester.pumpAndSettle();

    expect(find.text('Publicação pendente'), findsOneWidget);
    expect(find.text('A sincronização é automática.'), findsOneWidget);
  });

  testWidgets('2. sincronizada: sem notas', (tester) async {
    await tester.pumpWidget(_lista(
        _api((_) async => _json([_reuniao(1, estado: 'sincronizada')], 200)), MemoriaCacheReunioes()));
    await tester.pumpAndSettle();

    expect(find.text('Sincronizada com o calendário'), findsOneWidget);
    expect(find.text('A sincronização é automática.'), findsNothing);
    expect(find.text('A API mantém os dados da reunião.'), findsNothing);
  });

  testWidgets('3. alternativo: feed iCal e dados mantidos pela API', (tester) async {
    await tester.pumpWidget(_lista(
        _api((_) async => _json([_reuniao(1, estado: 'alternativo')], 200)), MemoriaCacheReunioes()));
    await tester.pumpAndSettle();

    expect(find.text('Serviço externo indisponível. Disponível no feed iCal.'), findsOneWidget);
    expect(find.text('A API mantém os dados da reunião.'), findsOneWidget);
    expect(find.text('A sincronização é automática.'), findsNothing);
  });

  testWidgets('a lista recebida fica guardada no dispositivo', (tester) async {
    final cache = MemoriaCacheReunioes();
    await tester.pumpWidget(_lista(
        _api((_) async => _json([_reuniao(1, estado: 'sincronizada')], 200)), cache));
    await tester.pumpAndSettle();

    expect(cache.listas, {
      _condominio: [_reuniao(1, estado: 'sincronizada')],
    });
  });

  testWidgets('4. sem ligação mostra a lista guardada, sem estado, com o aviso', (tester) async {
    final cache = _guardada([_reuniao(1, local: 'Garagem')]);
    await tester.pumpWidget(_lista(_api((_) async => throw http.ClientException('sem rede')), cache));
    await tester.pumpAndSettle();

    expect(find.text(_avisoGuardadas), findsOneWidget);
    expect(find.text('25/11/2030 às 19:00\nGaragem'), findsOneWidget);
    expect(find.text('Publicação pendente'), findsNothing);
    expect(find.text('A sincronização será tentada quando houver ligação.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Agendar reunião'), findsOneWidget);
  });

  testWidgets('API indisponível (503) também mostra a lista guardada', (tester) async {
    final cache = _guardada([_reuniao(1)]);
    await tester.pumpWidget(_lista(_api((_) async => _json({'codigo': 'servico_indisponivel'}, 503)), cache));
    await tester.pumpAndSettle();

    expect(find.text(_avisoGuardadas), findsOneWidget);
  });

  testWidgets('a lista guardada de outro condomínio não aparece', (tester) async {
    final cache = MemoriaCacheReunioes({99: [_reuniao(1, local: 'Outro prédio')]});
    await tester.pumpWidget(_lista(_api((_) async => throw http.ClientException('sem rede')), cache));
    await tester.pumpAndSettle();

    expect(find.textContaining('Outro prédio'), findsNothing);
    expect(find.text('Não foi possível carregar as reuniões.'), findsOneWidget);
  });

  for (final (nome, erro) in [
    ('timeout', TimeoutException('lento')),
    ('TLS', const HandshakeException('portal Wi-Fi')),
    ('resposta que não é JSON', const FormatException('<html>')),
  ]) {
    testWidgets('erro inesperado ($nome) mostra a lista guardada e não fica a carregar',
        (tester) async {
      await tester.pumpWidget(_lista(_api((_) async => throw erro), _guardada([_reuniao(1)])));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(_avisoGuardadas), findsOneWidget);
    });
  }

  testWidgets('API que não responde: ao fim do timeout mostra a lista guardada', (tester) async {
    // O pedido fica pendurado, como num servidor que aceita a ligação e não responde.
    final api = _api((_) => Completer<http.Response>().future);
    await tester.pumpWidget(_lista(api, _guardada([_reuniao(1, local: 'Garagem')])));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(ApiService.timeoutReunioes);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(_avisoGuardadas), findsOneWidget);
    expect(find.text('25/11/2030 às 19:00\nGaragem'), findsOneWidget);
  });

  testWidgets('em segundo plano não volta a pedir; ao voltar pede logo', (tester) async {
    var pedidos = 0;
    final api = _api((_) async {
      pedidos++;
      return _json([_reuniao(1)], 200);
    });
    await tester.pumpWidget(_lista(api, MemoriaCacheReunioes()));
    await tester.pumpAndSettle();
    expect(pedidos, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(intervaloAtualizacao * 3);
    expect(pedidos, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(pedidos, 2);
  });

  testWidgets('sem ligação e sem lista guardada mostra o erro', (tester) async {
    await tester.pumpWidget(
        _lista(_api((_) async => throw http.ClientException('sem rede')), MemoriaCacheReunioes()));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar as reuniões.'), findsOneWidget);
    expect(find.text(_avisoGuardadas), findsNothing);
  });

  testWidgets('erro que não é de ligação (403) não usa a lista guardada', (tester) async {
    final cache = _guardada([_reuniao(1)]);
    await tester.pumpWidget(_lista(_api((_) async => _json({'codigo': 'sem_permissao'}, 403)), cache));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar as reuniões.'), findsOneWidget);
    expect(find.text(_avisoGuardadas), findsNothing);
  });

  testWidgets('com publicação pendente volta a pedir a lista e mostra o novo estado', (tester) async {
    var pedidos = 0;
    final api = _api((_) async {
      pedidos++;
      return _json([_reuniao(1, estado: pedidos == 1 ? 'pendente' : 'sincronizada')], 200);
    });
    await tester.pumpWidget(_lista(api, MemoriaCacheReunioes()));
    await tester.pumpAndSettle();
    expect(find.text('Publicação pendente'), findsOneWidget);

    await tester.pump(intervaloAtualizacao);
    await tester.pumpAndSettle();

    expect(pedidos, 2);
    expect(find.text('Sincronizada com o calendário'), findsOneWidget);

    // Já não há nada pendente: não volta a pedir.
    await tester.pump(intervaloAtualizacao * 2);
    expect(pedidos, 2);
  });

  testWidgets('quando a ligação volta, a lista atualiza sozinha e o aviso desaparece', (tester) async {
    var pedidos = 0;
    final api = _api((_) async {
      pedidos++;
      if (pedidos == 1) throw http.ClientException('sem rede');
      return _json([_reuniao(1, estado: 'sincronizada')], 200);
    });
    await tester.pumpWidget(_lista(api, _guardada([_reuniao(1)])));
    await tester.pumpAndSettle();
    expect(find.text(_avisoGuardadas), findsOneWidget);

    await tester.pump(intervaloAtualizacao);
    await tester.pumpAndSettle();

    expect(find.text(_avisoGuardadas), findsNothing);
    expect(find.text('Sincronizada com o calendário'), findsOneWidget);
  });

  testWidgets('estados e aviso têm contraste e o botão tem etiqueta', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_lista(
      _api((_) async => _json([
            _reuniao(1),
            _reuniao(2, estado: 'sincronizada'),
            _reuniao(3, estado: 'alternativo'),
          ], 200)),
      MemoriaCacheReunioes(),
    ));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    // O TalkBack lê o cartão de uma vez: título, data, local e estado.
    expect(find.bySemanticsLabel(RegExp('Sincronizada com o calendário')), findsOneWidget);
    handle.dispose();
  });
}
