import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
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
      home: LandingScreen(links: links),
    );
  }
}
