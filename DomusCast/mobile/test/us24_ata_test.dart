// US-24: rever, editar e aprovar a ata (administrador).
//
// A ata nasce na US-10, ainda por implementar: o servidor falso abaixo começa com
// uma ata no estado em que o Worker a deixaria.
import 'dart:convert';

import 'package:domuscast/screens/ata_screen.dart';
import 'package:domuscast/screens/reunioes_screen.dart';
import 'package:domuscast/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _transcricao = 'Ana: proponho reparar a entrada. Rui: concordo.';
const _rascunho = 'Decisão: reparar a entrada. Prazo: por confirmar.';
const _editado = 'Decisão: reparar a entrada até 31 de dezembro.';

http.Response _json(Object body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> _reuniao(int id, DateTime quando) => {
      'id': id,
      'data_hora': quando.toUtc().toIso8601String(),
      'local': 'Sala do condomínio',
      'estado_sync': 'sincronizada',
      'criado_em': DateTime.utc(2026, 11, 1).toIso8601String(),
    };

final _reuniaoPassada = _reuniao(7, DateTime(2026, 11, 20, 19));

Map<String, dynamic> _ata({
  String estado = 'pendente_revisao',
  String? transcricao = _transcricao,
  String? rascunho = _rascunho,
  String? textoAprovado,
}) =>
    {
      'id': 1,
      'reuniao_id': 7,
      'estado': estado,
      'origem': 'ia',
      'transcricao': transcricao,
      'rascunho': rascunho,
      'texto_aprovado': textoAprovado,
      'aprovada_em': textoAprovado == null ? null : '2026-11-22T10:00:00Z',
      'aprovada_por': textoAprovado == null ? null : 3,
    };

/// Servidor falso com o comportamento da API da US-24 para uma ata.
/// [falhar] devolve uma resposta (ou lança um erro) em vez do comportamento normal.
class _Servidor {
  Map<String, dynamic>? ata;
  final pedidos = <http.Request>[];
  Future<http.Response> Function(http.Request)? falhar;

  _Servidor([this.ata]);

  List<String> get rotas => [for (final p in pedidos) '${p.method} ${p.url.path}'];

  late final api = ApiService(client: MockClient((req) async {
    pedidos.add(req);
    expect(req.headers['authorization'], 'Bearer cred-admin');
    final falha = falhar;
    if (falha != null) return falha(req);
    final ata = this.ata;
    return switch ((req.method, req.url.path)) {
      ('GET', '/reunioes/7/ata') => ata == null
          ? _json({'codigo': 'ata_inexistente', 'mensagem': '', 'request_id': 'r'}, 404)
          : _json(ata, 200),
      ('PUT', '/reunioes/7/ata') => () {
          ata!['rascunho'] = (jsonDecode(req.body) as Map)['rascunho'].toString().trim();
          return _json(ata, 200);
        }(),
      ('POST', '/reunioes/7/ata/aprovar') => () {
          this.ata = _ata(
            estado: 'aprovada',
            transcricao: null,
            rascunho: null,
            textoAprovado: ata!['rascunho'] as String,
          );
          return _json(this.ata!, 200);
        }(),
      _ => _json({'codigo': 'nao_encontrado'}, 404),
    };
  }));
}

/// Abre o ecrã da ata por cima de outro, como na app, para o "voltar" funcionar.
Future<void> _abrirAta(WidgetTester tester, _Servidor servidor) async {
  final nav = GlobalKey<NavigatorState>();
  await tester.pumpWidget(MaterialApp(navigatorKey: nav, home: const Scaffold()));
  nav.currentState!.push(MaterialPageRoute<void>(
    builder: (_) => AtaScreen(api: servidor.api, credencial: 'cred-admin', reuniao: _reuniaoPassada),
  ));
  await tester.pumpAndSettle();
}

Future<void> _tocar(WidgetTester tester, String texto) async {
  await tester.tap(find.text(texto));
  await tester.pumpAndSettle();
}

String _textoNoEditor(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

Future<void> _editarPara(WidgetTester tester, String texto) async {
  await _tocar(tester, 'Editar rascunho');
  await tester.enterText(find.byType(TextField), texto);
  await tester.pump();
}

void main() {
  group('ApiService', () {
    test('getAta, guardarRascunhoAta e aprovarAta usam as rotas e o corpo da API', () async {
      final pedidos = <http.Request>[];
      final api = ApiService(client: MockClient((req) async {
        pedidos.add(req);
        return _json(_ata(), 200);
      }));

      await api.getAta(7, 'c');
      await api.guardarRascunhoAta(7, 'c', _editado);
      await api.aprovarAta(7, 'c');

      expect([for (final p in pedidos) '${p.method} ${p.url.path}'], [
        'GET /reunioes/7/ata',
        'PUT /reunioes/7/ata',
        'POST /reunioes/7/ata/aprovar',
      ]);
      expect(pedidos[1].headers['content-type'], startsWith('application/json'));
      expect(jsonDecode(pedidos[1].body), {'rascunho': _editado});
      expect(pedidos[2].body, isEmpty); // a aprovação publica o rascunho guardado
    });

    test('erro da API traz o código para a app escolher a mensagem', () async {
      final api = ApiService(client: MockClient(
          (_) async => _json({'codigo': 'ata_ja_aprovada', 'mensagem': 'm', 'request_id': 'r'}, 409)));

      expect(
        () => api.aprovarAta(7, 'c'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having((e) => e.codigo, 'codigo', 'ata_ja_aprovada')),
      );
    });

    test('getReunioes só envia desde quando é pedido', () async {
      final urls = <Uri>[];
      final api = ApiService(client: MockClient((req) async {
        urls.add(req.url);
        return _json([], 200);
      }));

      await api.getReunioes('c');
      await api.getReunioes('c', desde: DateTime.utc(2000));

      expect(urls[0].query, isEmpty);
      expect(urls[1].queryParameters['desde'], '2000-01-01T00:00:00.000Z');
    });
  });

  group('Lista de reuniões', () {
    Future<List<Uri>> abrirLista(WidgetTester tester, List<Map<String, dynamic>> reunioes,
        {Map<String, dynamic>? ata}) async {
      final urls = <Uri>[];
      final api = ApiService(client: MockClient((req) async {
        urls.add(req.url);
        if (req.url.path == '/reunioes') return _json(reunioes, 200);
        return _json(ata ?? _ata(), 200);
      }));
      await tester.pumpWidget(MaterialApp(home: ReunioesScreen(api: api, credencial: 'cred-admin')));
      await tester.pumpAndSettle();
      return urls;
    }

    testWidgets('mostra as reuniões anteriores, da mais recente para a mais antiga', (tester) async {
      final urls = await abrirLista(tester, [
        _reuniao(1, DateTime(2026, 10, 1, 19)),
        _reuniao(2, DateTime(2026, 11, 20, 19)),
        _reuniao(3, DateTime(2030, 1, 10, 19)),
      ]);

      // Um só pedido, com `desde`, para trazer também as reuniões que já passaram.
      expect(urls.single.queryParameters['desde'], isNotNull);
      expect(find.text('Reuniões anteriores'), findsOneWidget);
      final y = [
        for (final data in ['10/01/2030', '20/11/2026', '01/10/2026'])
          tester.getTopLeft(find.textContaining(data)).dy,
      ];
      expect(y[0] < y[1] && y[1] < y[2], isTrue, reason: 'próxima, depois anteriores por data');
      expect(find.textContaining('Ver ata'), findsNWidgets(2));
    });

    testWidgets('sem reuniões futuras, mostra o aviso e as anteriores', (tester) async {
      await abrirLista(tester, [_reuniao(2, DateTime(2026, 11, 20, 19))]);

      expect(find.text('Ainda não há reuniões agendadas.'), findsOneWidget);
      expect(find.text('Reuniões anteriores'), findsOneWidget);
    });

    testWidgets('tocar numa reunião abre a ata dessa reunião', (tester) async {
      final urls = await abrirLista(tester, [_reuniao(7, DateTime(2026, 11, 20, 19))]);

      await tester.tap(find.text('Assembleia de condóminos'));
      await tester.pumpAndSettle();

      expect(find.byType(AtaScreen), findsOneWidget);
      expect(urls.last.path, '/reunioes/7/ata');
    });
  });

  group('Rever (critério 1)', () {
    testWidgets('mostra o rascunho como gerado por IA e pendente de revisão', (tester) async {
      await _abrirAta(tester, _Servidor(_ata()));

      expect(find.text('Rever ata'), findsOneWidget);
      expect(find.text('Gerado por IA. Pendente de revisão.'), findsOneWidget);
      expect(find.text(_rascunho), findsOneWidget);
      expect(find.text('20/11/2026 às 19:00'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Editar rascunho'), findsOneWidget);
    });

    testWidgets('a transcrição fica fechada e abre-se para consultar', (tester) async {
      await _abrirAta(tester, _Servidor(_ata()));
      expect(find.text(_transcricao), findsNothing);

      await _tocar(tester, 'Transcrição');

      expect(find.text(_transcricao), findsOneWidget);
    });

    testWidgets('a transcrição também se consulta enquanto se edita', (tester) async {
      await _abrirAta(tester, _Servidor(_ata()));
      await _tocar(tester, 'Editar rascunho');

      await _tocar(tester, 'Transcrição');

      expect(find.text(_transcricao), findsOneWidget);
    });
  });

  group('Editar', () {
    testWidgets('o editor começa com o rascunho guardado', (tester) async {
      await _abrirAta(tester, _Servidor(_ata()));

      await _tocar(tester, 'Editar rascunho');

      expect(find.text('Editar ata'), findsOneWidget);
      expect(_textoNoEditor(tester), _rascunho);
      expect(find.text('A alteração fica como rascunho até aprovar.'), findsOneWidget);
    });

    testWidgets('guardar envia o texto e não publica', (tester) async {
      final servidor = _Servidor(_ata());
      await _abrirAta(tester, servidor);
      await _editarPara(tester, _editado);

      await _tocar(tester, 'Guardar rascunho');

      expect(servidor.rotas, ['GET /reunioes/7/ata', 'PUT /reunioes/7/ata']);
      expect(jsonDecode(servidor.pedidos.last.body), {'rascunho': _editado});
      expect(find.text('Rascunho guardado. Ainda não foi publicado.'), findsOneWidget);
      expect(find.text('Editar ata'), findsOneWidget); // continua no editor
    });

    testWidgets('texto vazio não chama a API', (tester) async {
      final servidor = _Servidor(_ata());
      await _abrirAta(tester, servidor);
      await _editarPara(tester, '   ');

      await _tocar(tester, 'Guardar rascunho');
      await _tocar(tester, 'Aprovar ata');

      expect(find.text('Escreva o texto da ata antes de guardar.'), findsOneWidget);
      expect(servidor.rotas, ['GET /reunioes/7/ata']);
    });

    testWidgets('o editor limita o texto a $kMaxTextoAta caracteres', (tester) async {
      await _abrirAta(tester, _Servidor(_ata()));
      await _tocar(tester, 'Editar rascunho');

      expect(tester.widget<TextField>(find.byType(TextField)).maxLength, 20000);
    });

    testWidgets('voltar sem alterações regressa à revisão', (tester) async {
      await _abrirAta(tester, _Servidor(_ata()));
      await _tocar(tester, 'Editar rascunho');

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Rever ata'), findsOneWidget);
      expect(find.text('Descartar alterações?'), findsNothing);
    });

    testWidgets('voltar com alterações pergunta antes de as descartar', (tester) async {
      await _abrirAta(tester, _Servidor(_ata()));
      await _editarPara(tester, _editado);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Descartar alterações?'), findsOneWidget);

      await _tocar(tester, 'Continuar a editar');
      expect(_textoNoEditor(tester), _editado);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await _tocar(tester, 'Descartar');
      expect(find.text('Rever ata'), findsOneWidget);
      expect(find.text(_rascunho), findsOneWidget);
    });
  });

  group('Aprovar (critério 2)', () {
    testWidgets('pede confirmação e "Voltar a rever" não publica nada', (tester) async {
      final servidor = _Servidor(_ata());
      await _abrirAta(tester, servidor);
      await _editarPara(tester, _editado);

      await _tocar(tester, 'Aprovar ata');
      expect(find.text('Publicar ata?'), findsOneWidget);
      expect(
        find.text('A ata ficará visível aos residentes. Confirme que reviu as decisões e os dados.'),
        findsOneWidget,
      );

      await _tocar(tester, 'Voltar a rever');

      expect(servidor.rotas, ['GET /reunioes/7/ata']);
      expect(_textoNoEditor(tester), _editado);
    });

    testWidgets('aprovar guarda primeiro as alterações e depois publica', (tester) async {
      final servidor = _Servidor(_ata());
      await _abrirAta(tester, servidor);
      await _editarPara(tester, _editado);

      await _tocar(tester, 'Aprovar ata');
      await _tocar(tester, 'Aprovar e publicar');

      expect(servidor.rotas, [
        'GET /reunioes/7/ata',
        'PUT /reunioes/7/ata',
        'POST /reunioes/7/ata/aprovar',
      ]);
      expect(find.text('Ata aprovada'), findsOneWidget);
      expect(find.text('Ata aprovada e publicada aos residentes.'), findsWidgets);
      expect(find.text(_editado), findsOneWidget);
      // Fica só o texto aprovado: sem transcrição nem botão de edição.
      expect(find.text('Transcrição'), findsNothing);
      expect(find.text('Editar rascunho'), findsNothing);
      expect(find.textContaining('Aprovada pelo administrador'), findsOneWidget);
    });

    testWidgets('sem alterações por guardar, aprovar só publica', (tester) async {
      final servidor = _Servidor(_ata());
      await _abrirAta(tester, servidor);
      await _tocar(tester, 'Editar rascunho');

      await _tocar(tester, 'Aprovar ata');
      await _tocar(tester, 'Aprovar e publicar');

      expect(servidor.rotas, ['GET /reunioes/7/ata', 'POST /reunioes/7/ata/aprovar']);
      expect(find.text(_rascunho), findsOneWidget);
    });

    testWidgets('ata já aprovada por outro administrador mostra a publicada', (tester) async {
      final servidor = _Servidor(_ata());
      await _abrirAta(tester, servidor);
      await _editarPara(tester, _editado);
      // Entretanto, outro administrador aprovou a ata com o texto original.
      servidor.ata = _ata(estado: 'aprovada', transcricao: null, rascunho: null, textoAprovado: _rascunho);
      servidor.falhar = (req) async => req.method == 'GET'
          ? _json(servidor.ata!, 200)
          : _json({'codigo': 'ata_ja_aprovada', 'mensagem': '', 'request_id': 'r'}, 409);

      await _tocar(tester, 'Aprovar ata');
      await _tocar(tester, 'Aprovar e publicar');

      expect(
        find.text('Esta ata já tinha sido aprovada. As alterações não foram publicadas.'),
        findsOneWidget,
      );
      expect(find.text('Ata aprovada'), findsOneWidget);
      expect(find.text(_rascunho), findsOneWidget);
    });
  });

  group('Erros ao guardar ou aprovar', () {
    testWidgets('sem ligação: o texto fica no editor e "Guardar" volta a tentar', (tester) async {
      final servidor = _Servidor(_ata());
      await _abrirAta(tester, servidor);
      await _editarPara(tester, _editado);
      servidor.falhar = (_) async => throw http.ClientException('sem rede');

      await _tocar(tester, 'Guardar rascunho');

      expect(
        find.text('Não foi possível guardar. O texto continua no editor. '
            'Verifique a ligação e tente novamente.'),
        findsOneWidget,
      );
      expect(_textoNoEditor(tester), _editado);
      expect(find.textContaining('guardado'), findsNothing); // nunca diz que guardou

      servidor.falhar = null;
      await _tocar(tester, 'Guardar rascunho');
      expect(find.text('Rascunho guardado. Ainda não foi publicado.'), findsOneWidget);
      expect(servidor.ata!['rascunho'], _editado);
    });

    testWidgets('falha ao publicar depois de guardar: não diz que publicou', (tester) async {
      final servidor = _Servidor(_ata());
      await _abrirAta(tester, servidor);
      await _editarPara(tester, _editado);
      servidor.falhar = (req) async =>
          req.method == 'POST' ? _json({'codigo': 'servico_indisponivel'}, 503) : _json(
              servidor.ata!..['rascunho'] = _editado, 200);

      await _tocar(tester, 'Aprovar ata');
      await _tocar(tester, 'Aprovar e publicar');

      expect(
        find.text('O serviço está indisponível. O texto continua no editor. '
            'Tente novamente daqui a pouco.'),
        findsOneWidget,
      );
      expect(find.text('Editar ata'), findsOneWidget);
      expect(_textoNoEditor(tester), _editado);
      expect(find.textContaining('publicada'), findsNothing);

      // O rascunho já ficou guardado: tentar de novo só publica.
      servidor.falhar = null;
      await _tocar(tester, 'Aprovar ata');
      await _tocar(tester, 'Aprovar e publicar');
      expect(servidor.rotas.last, 'POST /reunioes/7/ata/aprovar');
      expect(servidor.rotas.where((r) => r.startsWith('PUT')), hasLength(1));
      expect(find.text('Ata aprovada'), findsOneWidget);
    });

    for (final (status, codigo, mensagem) in [
      (422, 'dados_invalidos', 'O texto da ata tem de ter entre 1 e 20000 caracteres.'),
      (409, 'ata_em_processamento', 'A transcrição ainda está em curso. Tente mais tarde.'),
      (409, 'ata_sem_rascunho', 'Esta ata já não pode ser editada.'),
      (403, 'sem_permissao', 'Só o administrador pode rever e aprovar a ata.'),
      (404, 'ata_inexistente', 'Esta ata já não existe.'),
    ]) {
      testWidgets('$status $codigo mostra a mensagem própria e mantém o texto', (tester) async {
        final servidor = _Servidor(_ata());
        await _abrirAta(tester, servidor);
        await _editarPara(tester, _editado);
        servidor.falhar = (_) async => _json({'codigo': codigo, 'mensagem': '', 'request_id': 'r'}, status);

        await _tocar(tester, 'Guardar rascunho');

        expect(find.text(mensagem), findsOneWidget);
        expect(_textoNoEditor(tester), _editado);
      });
    }

    testWidgets('a mensagem de erro desaparece quando se volta a escrever', (tester) async {
      final servidor = _Servidor(_ata());
      await _abrirAta(tester, servidor);
      await _editarPara(tester, '');
      await _tocar(tester, 'Guardar rascunho');
      expect(find.text('Escreva o texto da ata antes de guardar.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), _editado);
      await tester.pump();

      expect(find.text('Escreva o texto da ata antes de guardar.'), findsNothing);
    });
  });

  group('Outros estados da ata', () {
    testWidgets('sem ata: informa e não permite editar', (tester) async {
      await _abrirAta(tester, _Servidor());

      expect(find.text('Esta reunião ainda não tem ata.'), findsOneWidget);
      expect(find.text('Editar rascunho'), findsNothing);
    });

    testWidgets('a transcrever: informa e "Atualizar estado" volta a pedir', (tester) async {
      final servidor = _Servidor(_ata(estado: 'a_transcrever', transcricao: null, rascunho: null));
      await _abrirAta(tester, servidor);
      expect(find.text('A transcrever.'), findsOneWidget);
      expect(find.text('Editar rascunho'), findsNothing);

      servidor.ata = _ata();
      await _tocar(tester, 'Atualizar estado');

      expect(servidor.rotas, ['GET /reunioes/7/ata', 'GET /reunioes/7/ata']);
      expect(find.text('Gerado por IA. Pendente de revisão.'), findsOneWidget);
    });

    testWidgets('transcrição falhada: informa e não permite editar o rascunho', (tester) async {
      await _abrirAta(
          tester, _Servidor(_ata(estado: 'falhou_transcricao', transcricao: null, rascunho: null)));

      expect(find.text('A transcrição falhou.'), findsOneWidget);
      // A partir daqui, a ata manual é da US-25 (test/us25_ata_manual_test.dart).
      expect(find.text('O áudio continua guardado. Pode escrever a ata manualmente.'),
          findsOneWidget);
      expect(find.text('Editar rascunho'), findsNothing);
    });

    testWidgets('já aprovada: só o texto aprovado, sem edição', (tester) async {
      await _abrirAta(tester, _Servidor(_ata(
          estado: 'aprovada', transcricao: null, rascunho: null, textoAprovado: _editado)));

      expect(find.text('Ata aprovada'), findsOneWidget);
      expect(find.text(_editado), findsOneWidget);
      // A hora mostrada depende do fuso do telemóvel; o dia é o mesmo em Portugal.
      expect(find.textContaining('Aprovada pelo administrador em 22/11/2026'), findsOneWidget);
      expect(find.textContaining('O áudio, a transcrição e o rascunho foram eliminados.'),
          findsOneWidget);
      expect(find.text('Editar rascunho'), findsNothing);
    });

    testWidgets('erro ao carregar: "Tentar novamente" volta a pedir', (tester) async {
      final servidor = _Servidor(_ata());
      servidor.falhar = (_) async => _json({'codigo': 'servico_indisponivel'}, 503);
      await _abrirAta(tester, servidor);
      expect(find.text('Não foi possível carregar a ata.'), findsOneWidget);

      servidor.falhar = null;
      await _tocar(tester, 'Tentar novamente');

      expect(find.text('Gerado por IA. Pendente de revisão.'), findsOneWidget);
    });

    testWidgets('sem ligação ao carregar: mensagem própria', (tester) async {
      final servidor = _Servidor(_ata());
      servidor.falhar = (_) async => throw http.ClientException('sem rede');
      await _abrirAta(tester, servidor);

      expect(find.text('Não foi possível carregar a ata. Verifique a ligação.'), findsOneWidget);
    });

    testWidgets('reunião que já não existe: mensagem própria', (tester) async {
      final servidor = _Servidor(_ata());
      servidor.falhar = (_) async => _json({'codigo': 'reuniao_nao_encontrada'}, 404);
      await _abrirAta(tester, servidor);

      expect(find.text('Esta reunião já não existe.'), findsOneWidget);
    });
  });

  group('Acessibilidade (TalkBack)', () {
    Future<void> verificar(WidgetTester tester) async {
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    }

    testWidgets('revisão, editor e ata aprovada cumprem as regras de acessibilidade',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _abrirAta(tester, _Servidor(_ata()));
      await verificar(tester);

      await _editarPara(tester, _editado);
      await verificar(tester);

      await _tocar(tester, 'Aprovar ata');
      await _tocar(tester, 'Aprovar e publicar');
      await verificar(tester);
      handle.dispose();
    });

    testWidgets('o estado da ata e os erros são anunciados (live region)', (tester) async {
      final handle = tester.ensureSemantics();
      final servidor = _Servidor(_ata());
      await _abrirAta(tester, servidor);

      expect(
        tester.getSemantics(find.text('Gerado por IA. Pendente de revisão.')),
        isSemantics(isLiveRegion: true),
      );

      await _editarPara(tester, _editado);
      servidor.falhar = (_) async => throw http.ClientException('sem rede');
      await _tocar(tester, 'Guardar rascunho');
      expect(
        tester.getSemantics(find.textContaining('Não foi possível guardar')),
        isSemantics(isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('o campo de texto tem rótulo para o leitor de ecrã', (tester) async {
      final handle = tester.ensureSemantics();
      await _abrirAta(tester, _Servidor(_ata()));
      await _tocar(tester, 'Editar rascunho');

      expect(find.bySemanticsLabel(RegExp('Texto da ata')), findsOneWidget);
      handle.dispose();
    });
  });
}
