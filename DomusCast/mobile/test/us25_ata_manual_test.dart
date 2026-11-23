// US-25: ata manual (fallback não-IA), no ecrã da ata do administrador.
//
// Segue os 4 ecrãs de docs/sprintB/design/us-25.html: escrever, aprovação,
// resultado e erro. O servidor falso reproduz o PUT da API: sem ata, ou com a
// transcrição falhada, guardar cria ou converte a ata em manual.
import 'dart:convert';

import 'package:domuscast/screens/ata_screen.dart';
import 'package:domuscast/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _texto = 'Decisão: reparar a entrada até 31 de dezembro.';
const _avisoManual = 'Sem rascunho de IA. A ata será identificada como manual.';

http.Response _json(Object body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

final _reuniao = {
  'id': 7,
  'data_hora': DateTime(2026, 11, 20, 19).toUtc().toIso8601String(),
  'local': 'Sala do condomínio',
  'estado_sync': 'sincronizada',
  'criado_em': DateTime.utc(2026, 11, 1).toIso8601String(),
};

Map<String, dynamic> _ata({
  String estado = 'pendente_revisao',
  String origem = 'manual',
  String? transcricao,
  String? rascunho = _texto,
}) =>
    {
      'id': 1,
      'reuniao_id': 7,
      'estado': estado,
      'origem': origem,
      'transcricao': transcricao,
      'rascunho': rascunho,
      'texto_aprovado': null,
      'aprovada_em': null,
      'aprovada_por': null,
    };

Map<String, dynamic> _erro(String codigo) => {'codigo': codigo, 'mensagem': '', 'request_id': 'r'};

/// Servidor falso com o comportamento da API das US-24 e US-25 para uma ata.
class _Servidor {
  Map<String, dynamic>? ata;
  final pedidos = <http.Request>[];
  Future<http.Response> Function(http.Request)? falhar;

  _Servidor([this.ata]);

  List<String> get rotas => [for (final p in pedidos) '${p.method} ${p.url.path}'];

  http.Response _guardar(http.Request req) {
    final texto = (jsonDecode(req.body) as Map)['rascunho'].toString().trim();
    final atual = ata;
    if (atual == null) {
      ata = _ata(rascunho: texto);
    } else if (atual['estado'] == 'falhou_transcricao') {
      ata = {...atual, 'estado': 'pendente_revisao', 'origem': 'manual', 'transcricao': null};
      ata!['rascunho'] = texto;
    } else if (atual['estado'] == 'pendente_revisao') {
      atual['rascunho'] = texto;
    } else if (atual['estado'] == 'a_transcrever') {
      return _json(_erro('ata_em_processamento'), 409);
    } else {
      return _json(_erro('ata_ja_aprovada'), 409);
    }
    return _json(ata!, 200);
  }

  late final api = ApiService(client: MockClient((req) async {
    pedidos.add(req);
    expect(req.headers['authorization'], 'Bearer cred-admin');
    final falha = falhar;
    if (falha != null) return falha(req);
    return switch ((req.method, req.url.path)) {
      ('GET', '/reunioes/7/ata') =>
        ata == null ? _json(_erro('ata_inexistente'), 404) : _json(ata!, 200),
      ('PUT', '/reunioes/7/ata') => _guardar(req),
      ('POST', '/reunioes/7/ata/aprovar') => () {
          ata = {
            ...ata!,
            'estado': 'aprovada',
            'texto_aprovado': ata!['rascunho'],
            'rascunho': null,
            'transcricao': null,
            'aprovada_em': '2026-11-22T10:00:00Z',
            'aprovada_por': 3,
          };
          return _json(ata!, 200);
        }(),
      _ => _json(_erro('nao_encontrado'), 404),
    };
  }));
}

/// Abre o ecrã da ata por cima de outro, como na app, para o "voltar" funcionar.
Future<void> _abrirAta(WidgetTester tester, _Servidor servidor) async {
  final nav = GlobalKey<NavigatorState>();
  await tester.pumpWidget(MaterialApp(navigatorKey: nav, home: const Scaffold()));
  nav.currentState!.push(MaterialPageRoute<void>(
    builder: (_) => AtaScreen(api: servidor.api, credencial: 'cred-admin', reuniao: _reuniao),
  ));
  await tester.pumpAndSettle();
}

Future<void> _tocar(WidgetTester tester, String texto) async {
  await tester.tap(find.text(texto));
  await tester.pumpAndSettle();
}

String _textoNoEditor(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

Future<void> _escrever(WidgetTester tester, String texto) async {
  await tester.enterText(find.byType(TextField), texto);
  await tester.pump();
}

/// Abre o editor da ata manual numa reunião sem ata e escreve o texto.
Future<_Servidor> _novaAtaManual(WidgetTester tester, [String texto = _texto]) async {
  final servidor = _Servidor();
  await _abrirAta(tester, servidor);
  await _tocar(tester, 'Escrever ata manual');
  await _escrever(tester, texto);
  return servidor;
}

void main() {
  group('1. Escrever', () {
    testWidgets('sem ata, o administrador pode escrever uma ata manual', (tester) async {
      await _abrirAta(tester, _Servidor());

      expect(find.text('Esta reunião ainda não tem ata.'), findsOneWidget);
      expect(find.text('Pode escrever a ata manualmente, sem depender do serviço de IA.'),
          findsOneWidget);

      await _tocar(tester, 'Escrever ata manual');

      expect(find.text('Ata manual'), findsOneWidget); // título
      expect(find.text(_avisoManual), findsOneWidget);
      expect(find.text('Transcrição'), findsNothing);
      expect(_textoNoEditor(tester), isEmpty);
      expect(find.text('Escreva as decisões confirmadas na assembleia.'), findsOneWidget);
      expect(find.text('Guardar rascunho'), findsOneWidget);
      expect(find.text('Aprovar ata'), findsOneWidget);
    });

    testWidgets('guardar cria a ata manual sem a publicar', (tester) async {
      final servidor = await _novaAtaManual(tester);

      await _tocar(tester, 'Guardar rascunho');

      expect(servidor.rotas, ['GET /reunioes/7/ata', 'PUT /reunioes/7/ata']);
      expect(jsonDecode(servidor.pedidos.last.body), {'rascunho': _texto});
      expect(find.text('Rascunho guardado. Ainda não foi publicado.'), findsOneWidget);
      expect(servidor.ata!['origem'], 'manual');
      expect(servidor.ata!['estado'], 'pendente_revisao');
      expect(find.text('Ata manual'), findsOneWidget); // continua no editor
      expect(_textoNoEditor(tester), _texto);
    });

    testWidgets('texto vazio não é enviado', (tester) async {
      final servidor = await _novaAtaManual(tester, '   ');

      await _tocar(tester, 'Guardar rascunho');

      expect(find.text('Escreva o texto da ata antes de guardar.'), findsOneWidget);
      expect(servidor.rotas, ['GET /reunioes/7/ata']);
    });

    testWidgets('voltar sem texto regressa ao "sem ata"', (tester) async {
      final servidor = _Servidor();
      await _abrirAta(tester, servidor);
      await _tocar(tester, 'Escrever ata manual');

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Esta reunião ainda não tem ata.'), findsOneWidget);
      expect(find.text('Escrever ata manual'), findsOneWidget);
      expect(servidor.rotas, ['GET /reunioes/7/ata']);
    });

    testWidgets('voltar com texto por guardar pergunta antes de descartar', (tester) async {
      final servidor = await _novaAtaManual(tester);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Descartar alterações?'), findsOneWidget);

      await _tocar(tester, 'Descartar');

      expect(find.text('Esta reunião ainda não tem ata.'), findsOneWidget);
      expect(servidor.ata, isNull);
    });
  });

  group('2. Aprovação', () {
    testWidgets('ata manual guardada: "Rever ata manual", sem indicação de IA', (tester) async {
      await _abrirAta(tester, _Servidor(_ata()));

      expect(find.text('Rever ata manual'), findsOneWidget);
      expect(find.text('Ata manual. Ainda não publicada.'), findsOneWidget);
      expect(find.text('Texto da ata'), findsOneWidget);
      expect(find.text(_texto), findsOneWidget);
      expect(find.textContaining('Gerado por IA'), findsNothing);
      expect(find.text('Editar rascunho'), findsNothing);

      await _tocar(tester, 'Editar ata');

      expect(find.text('Ata manual'), findsOneWidget);
      expect(find.text(_avisoManual), findsOneWidget);
      expect(_textoNoEditor(tester), _texto);
    });

    testWidgets('aprovar pede confirmação e usa o fluxo da US-24', (tester) async {
      final servidor = await _novaAtaManual(tester);

      await _tocar(tester, 'Aprovar ata');
      expect(find.text('Publicar ata?'), findsOneWidget);
      expect(servidor.rotas, ['GET /reunioes/7/ata']); // nada enviado antes de confirmar

      await _tocar(tester, 'Aprovar e publicar');

      // O texto por guardar vai primeiro (cria a ata); depois publica-se.
      expect(servidor.rotas, [
        'GET /reunioes/7/ata',
        'PUT /reunioes/7/ata',
        'POST /reunioes/7/ata/aprovar',
      ]);
      expect(servidor.ata!['texto_aprovado'], _texto);
    });

    testWidgets('a ata de IA pendente não oferece a ata manual', (tester) async {
      await _abrirAta(
        tester,
        _Servidor(_ata(origem: 'ia', transcricao: 'Ana: proponho reparar a entrada.')),
      );

      expect(find.text('Rever ata'), findsOneWidget);
      expect(find.text('Gerado por IA. Pendente de revisão.'), findsOneWidget);
      expect(find.text('Escrever ata manual'), findsNothing);

      await _tocar(tester, 'Editar rascunho');
      expect(find.text(_avisoManual), findsNothing);
    });
  });

  group('3. Resultado', () {
    testWidgets('depois de aprovar, a origem manual fica explícita', (tester) async {
      await _novaAtaManual(tester);

      await _tocar(tester, 'Aprovar ata');
      await _tocar(tester, 'Aprovar e publicar');

      expect(find.text('Ata aprovada'), findsOneWidget);
      expect(find.text('Ata manual aprovada e publicada aos residentes.'), findsOneWidget);
      expect(find.text(_texto), findsOneWidget);
    });

    testWidgets('a ata de IA aprovada não é apresentada como manual', (tester) async {
      await _abrirAta(tester, _Servidor({
        ..._ata(origem: 'ia', rascunho: null),
        'estado': 'aprovada',
        'texto_aprovado': _texto,
        'aprovada_em': '2026-11-22T10:00:00Z',
      }));

      expect(find.text('Ata aprovada e publicada aos residentes.'), findsOneWidget);
      expect(find.textContaining('manual'), findsNothing);
    });
  });

  group('Transcrição falhada (US-10)', () {
    Map<String, dynamic> falhada() => _ata(
          estado: 'falhou_transcricao',
          origem: 'ia',
          transcricao: 'Transcrição parcial',
          rascunho: null,
        );

    testWidgets('oferece a ata manual e abre o editor vazio', (tester) async {
      await _abrirAta(tester, _Servidor(falhada()));

      expect(find.text('A transcrição falhou.'), findsOneWidget);
      expect(find.text('O áudio continua guardado. Pode escrever a ata manualmente.'),
          findsOneWidget);

      await _tocar(tester, 'Escrever ata manual');

      expect(find.text('Ata manual'), findsOneWidget);
      expect(find.text(_avisoManual), findsOneWidget);
      expect(_textoNoEditor(tester), isEmpty);
    });

    testWidgets('guardar converte a ata em manual', (tester) async {
      final servidor = _Servidor(falhada());
      await _abrirAta(tester, servidor);
      await _tocar(tester, 'Escrever ata manual');
      await _escrever(tester, _texto);

      await _tocar(tester, 'Guardar rascunho');

      expect(servidor.ata!['origem'], 'manual');
      expect(servidor.ata!['estado'], 'pendente_revisao');
      expect(find.text('Rascunho guardado. Ainda não foi publicado.'), findsOneWidget);
    });

    testWidgets('voltar sem texto regressa à transcrição falhada', (tester) async {
      await _abrirAta(tester, _Servidor(falhada()));
      await _tocar(tester, 'Escrever ata manual');

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('A transcrição falhou.'), findsOneWidget);
    });
  });

  group('4. Erro', () {
    testWidgets('sem ligação: o texto fica no editor e "Guardar" volta a tentar', (tester) async {
      final servidor = await _novaAtaManual(tester);
      servidor.falhar = (_) async => throw http.ClientException('sem rede');

      await _tocar(tester, 'Guardar rascunho');

      expect(
        find.text('Não foi possível guardar. O texto continua no editor. '
            'Verifique a ligação e tente novamente.'),
        findsOneWidget,
      );
      expect(_textoNoEditor(tester), _texto);
      expect(find.text('Ata manual'), findsOneWidget);
      expect(servidor.ata, isNull);

      servidor.falhar = null;
      await _tocar(tester, 'Guardar rascunho');

      expect(find.text('Rascunho guardado. Ainda não foi publicado.'), findsOneWidget);
      expect(servidor.ata!['rascunho'], _texto);
    });

    testWidgets('falha a criar a ata ao aprovar: não diz que publicou', (tester) async {
      final servidor = await _novaAtaManual(tester);
      servidor.falhar = (_) async => _json(_erro('servico_indisponivel'), 503);

      await _tocar(tester, 'Aprovar ata');
      await _tocar(tester, 'Aprovar e publicar');

      expect(find.textContaining('O texto continua no editor.'), findsOneWidget);
      expect(_textoNoEditor(tester), _texto);
      expect(find.textContaining('publicada'), findsNothing);
      expect(servidor.rotas.where((r) => r.startsWith('POST')), isEmpty);
    });

    testWidgets('a transcrição começou entretanto (409): avisa e mantém o texto', (tester) async {
      final servidor = await _novaAtaManual(tester);
      // O upload da US-10 chegou primeiro.
      servidor.ata = _ata(estado: 'a_transcrever', origem: 'ia', rascunho: null);

      await _tocar(tester, 'Guardar rascunho');

      expect(find.text('A transcrição ainda está em curso. Tente mais tarde.'), findsOneWidget);
      expect(_textoNoEditor(tester), _texto);
    });

    testWidgets('reunião apagada entretanto (404): mensagem própria', (tester) async {
      final servidor = await _novaAtaManual(tester);
      servidor.falhar = (_) async => _json(_erro('reuniao_nao_encontrada'), 404);

      await _tocar(tester, 'Guardar rascunho');

      expect(find.text('Esta reunião já não existe.'), findsOneWidget);
      expect(_textoNoEditor(tester), _texto);
    });
  });

  group('Acessibilidade (TalkBack)', () {
    testWidgets('o estado da ata manual é anunciado', (tester) async {
      final handle = tester.ensureSemantics();
      await _abrirAta(tester, _Servidor(_ata()));

      expect(
        tester.getSemantics(find.text('Ata manual. Ainda não publicada.')),
        isSemantics(isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('o aviso de ata manual e o erro são anunciados no editor', (tester) async {
      final handle = tester.ensureSemantics();
      final servidor = await _novaAtaManual(tester);
      expect(tester.getSemantics(find.text(_avisoManual)), isSemantics(isLiveRegion: true));

      servidor.falhar = (_) async => throw http.ClientException('sem rede');
      await _tocar(tester, 'Guardar rascunho');

      expect(
        tester.getSemantics(find.textContaining('Não foi possível guardar')),
        isSemantics(isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('"Escrever ata manual" é um botão com rótulo', (tester) async {
      final handle = tester.ensureSemantics();
      await _abrirAta(tester, _Servidor());

      expect(
        find.bySemanticsLabel('Escrever ata manual'),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Escrever ata manual')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });
  });
}
