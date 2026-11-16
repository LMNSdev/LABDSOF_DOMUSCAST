// Navegação por separadores: os separadores dependem do papel (administrador ou residente).
import 'dart:convert';

import 'package:domuscast/screens/fracoes_screen.dart';
import 'package:domuscast/screens/home_screen.dart';
import 'package:domuscast/services/api_service.dart';
import 'package:domuscast/services/sessao_admin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _sessao = SessaoAdmin(
  condominioId: 7,
  nomeCondominio: 'Rua das Flores, 12',
  credencial: 'cred-123',
);

ApiService _api() => ApiService(client: MockClient((req) async {
      final body = req.url.path.endsWith('/fracoes')
          ? [
              {'id': 1, 'designacao': 'A', 'n_residentes': 0},
            ]
          : <Object>[];
      return http.Response(jsonEncode(body), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    }));

Finder _separador(String nome) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(nome));

void main() {
  testWidgets('administrador tem Reportes, Reuniões, Avisos e Condomínio e abre nos Reportes',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen(api: _api(), sessao: _sessao)));
    await tester.pumpAndSettle();

    for (final s in ['Reportes', 'Reuniões', 'Avisos', 'Condomínio']) {
      expect(_separador(s), findsOneWidget, reason: s);
    }
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 0);
  });

  testWidgets('residente não tem o separador Condomínio', (tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen(api: _api())));
    await tester.pumpAndSettle();

    for (final s in ['Reportes', 'Reuniões', 'Avisos']) {
      expect(_separador(s), findsOneWidget, reason: s);
    }
    expect(_separador('Condomínio'), findsNothing);
  });

  testWidgets('Avisos ainda não está disponível', (tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen(api: _api(), sessao: _sessao)));
    await tester.pumpAndSettle();
    await tester.tap(_separador('Avisos'));
    await tester.pumpAndSettle();
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 0);
  });

  testWidgets('Condomínio abre as frações com seta para voltar, sem perder os separadores',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen(api: _api(), sessao: _sessao)));
    await tester.pumpAndSettle();

    await tester.tap(_separador('Condomínio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Frações e QR codes'));
    await tester.pumpAndSettle();

    expect(find.byType(FracoesScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(FracoesScreen), findsNothing);
    expect(find.text('Frações e QR codes'), findsOneWidget);
  });

  testWidgets('o voltar do Android fecha primeiro o ecrã aberto dentro do separador',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen(api: _api(), sessao: _sessao)));
    await tester.pumpAndSettle();
    await tester.tap(_separador('Condomínio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Frações e QR codes'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(FracoesScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Frações e QR codes'), findsOneWidget);
  });

  testWidgets('o voltar do Android no início de outro separador regressa aos Reportes',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen(api: _api(), sessao: _sessao)));
    await tester.pumpAndSettle();
    await tester.tap(_separador('Condomínio'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 0);
  });

  testWidgets('pode abrir num separador escolhido', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(api: _api(), sessao: _sessao, separadorInicial: Separador.condominio),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Frações e QR codes'), findsOneWidget);
  });

  testWidgets('Reuniões mostra o estado vazio', (tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen(api: _api())));
    await tester.pumpAndSettle();
    await tester.tap(_separador('Reuniões'));
    await tester.pumpAndSettle();
    expect(find.text('As reuniões vão aparecer aqui.'), findsOneWidget);
  });
}
