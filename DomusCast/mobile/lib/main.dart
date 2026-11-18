import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
import 'screens/landing_screen.dart';

void main() {
  runApp(DomusCastApp(links: AppLinks().uriLinkStream));
}

class DomusCastApp extends StatelessWidget {
  final Stream<Uri>? links;

  const DomusCastApp({super.key, this.links});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DomusCast',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      // Textos do sistema (ex.: "Voltar") e anúncios do leitor de ecrã em PT-PT.
      locale: const Locale('pt', 'PT'),
      supportedLocales: const [Locale('pt', 'PT')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: LandingScreen(links: links),
    );
  }
}
