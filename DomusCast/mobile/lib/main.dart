import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/landing_screen.dart';

void main() {
  runApp(const DomusCastApp());
}

class DomusCastApp extends StatelessWidget {
  const DomusCastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DomusCast',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const LandingScreen(),
    );
  }
}
