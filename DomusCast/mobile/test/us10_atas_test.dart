import 'dart:convert';

import 'package:domuscast/screens/ata_screen.dart';
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

final _reuniao = <String, dynamic>{
  'id': 8,
  'data_hora': DateTime(2030, 1, 2, 19).toUtc().toIso8601String(),
  'local': 'Sala comum',
  'estado_sync': 'pendente',
};

Map<String, dynamic> _ata(String estado) => {
      'id': 4,
      'reuniao_id': 8,
      'estado': estado,
      'origem': 'ia',
      'audio_guardado': true,
      'transcricao': estado == 'pendente_revisao'
          ? 'Ponto um, decisão por confirmar.'
          : null,
      'rascunho': estado == 'pendente_revisao'
          ? 'Rascunho com decisão por confirmar.'
          : null,
      'texto_aprovado': null,
    };

final _audio = AudioAta(
  nome: 'assembleia.wav',
  tamanho: 4,
  abrirStream: () => Stream.value([82, 73, 70, 70]),
);

Widget _ecra(ApiService api, {Future<AudioAta?> Function()? escolherAudio}) =>
    MaterialApp(
        home: AtaScreen(
      api: api,
      credencial: 'admin',
      reuniao: _reuniao,
      escolherAudio: escolherAudio ?? () async => _audio,
    ));

void main() {
  testWidgets(
      'avisa da OpenAI antes do envio, usa multipart e mostra processamento',
      (tester) async {
    var pedidos = 0;
    final api = ApiService(client: MockClient((req) async {
      expect(req.headers['authorization'], 'Bearer admin');
      if (req.method == 'GET') {
        return pedidos == 0
            ? _json({'codigo': 'nao_encontrada'}, 404)
            : _json(_ata('a_transcrever'), 200);
      }
      expect(req.url.path, '/reunioes/8/ata/audio');
      expect(req.headers['content-type'], contains('multipart/form-data'));
      expect(req.body, contains('name="audio"; filename="assembleia.wav"'));
      pedidos++;
      return _json(_ata('a_transcrever'), 202);
    }));
    await tester.pumpWidget(_ecra(api));
    await tester.pumpAndSettle();

    expect(find.textContaining('enviados à OpenAI'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Enviar áudio'), findsOneWidget);
    await tester.tap(find.text('Escolher áudio MP3, M4A ou WAV'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enviar áudio'));
    await tester.tap(find.text('Enviar áudio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(pedidos, 1);
    expect(find.textContaining('A transcrever.'), findsOneWidget);
    expect(find.text('Enviar áudio'), findsNothing);
  });

  testWidgets('mostra rascunho IA privado e transcrição pendentes de revisão',
      (tester) async {
    final api = ApiService(
        client: MockClient((_) async => _json(_ata('pendente_revisao'), 200)));
    await tester.pumpWidget(_ecra(api));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pendente de revisão humana'), findsOneWidget);
    expect(find.text('Rascunho com decisão por confirmar.'), findsOneWidget);
    expect(find.text('Ponto um, decisão por confirmar.'), findsOneWidget);
    expect(find.text('Enviar áudio'), findsNothing);
  });

  testWidgets('falha preserva áudio e permite reenviar o mesmo ficheiro',
      (tester) async {
    var envios = 0;
    final api = ApiService(client: MockClient((req) async {
      if (req.method == 'GET') return _json(_ata('falhou_transcricao'), 200);
      envios++;
      return _json(_ata('a_transcrever'), 202);
    }));
    await tester.pumpWidget(_ecra(api));
    await tester.pumpAndSettle();

    expect(find.textContaining('O áudio continua guardado'), findsOneWidget);
    await tester.tap(find.text('Escolher áudio MP3, M4A ou WAV'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tentar transcrição novamente'));
    await tester.tap(find.text('Tentar transcrição novamente'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(envios, 1);
    expect(find.textContaining('A transcrever.'), findsOneWidget);
  });

  testWidgets('reuniões passadas ficam acessíveis ao administrador',
      (tester) async {
    final urls = <Uri>[];
    final api = ApiService(client: MockClient((req) async {
      urls.add(req.url);
      if (req.url.path.endsWith('/ata'))
        return _json({'codigo': 'nao_encontrada'}, 404);
      return _json([_reuniao], 200);
    }));
    await tester.pumpWidget(
        MaterialApp(home: ReunioesScreen(api: api, credencial: 'admin')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mostrar reuniões passadas'));
    await tester.pumpAndSettle();
    expect(urls.last.queryParameters['incluir_passadas'], 'true');
    await tester.tap(find.text('Assembleia de condóminos'));
    await tester.pumpAndSettle();
    expect(find.byType(AtaScreen), findsOneWidget);
  });

  testWidgets('erro de formato é explicado sem fingir que o áudio foi enviado',
      (tester) async {
    final api = ApiService(client: MockClient((req) async {
      if (req.method == 'GET') return _json({'codigo': 'nao_encontrada'}, 404);
      return _json({'codigo': 'formato_audio_nao_suportado'}, 415);
    }));
    await tester.pumpWidget(_ecra(api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escolher áudio MP3, M4A ou WAV'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enviar áudio'));
    await tester.tap(find.text('Enviar áudio'));
    await tester.pumpAndSettle();
    expect(
        find.text('Formato não aceite. Use MP3, M4A ou WAV.'), findsOneWidget);
    expect(find.text('Enviar áudio'), findsOneWidget);
  });

  testWidgets('seleção e envio têm ações acessíveis; estado é anunciado',
      (tester) async {
    final handle = tester.ensureSemantics();
    final api = ApiService(
        client: MockClient((_) async => _json(_ata('a_transcrever'), 200)));
    await tester.pumpWidget(_ecra(api));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final no = tester.getSemantics(find.textContaining('A transcrever.'));
    expect(no.getSemanticsData().flagsCollection.isLiveRegion, isTrue);

    final apiSemAta =
        ApiService(client: MockClient((_) async => _json({}, 404)));
    await tester.pumpWidget(_ecra(apiSemAta));
    await tester.pumpAndSettle();
    final escolher = tester.getSemantics(
        find.bySemanticsLabel(RegExp('Escolher áudio MP3, M4A ou WAV')).first);
    expect(escolher.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    handle.dispose();
  });
}
