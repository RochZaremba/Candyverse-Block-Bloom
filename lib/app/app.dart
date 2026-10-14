import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../home/home_screen.dart';

class CandyverseApp extends StatelessWidget {
  const CandyverseApp({required this.theme, super.key});

  final AppTheme theme;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Candyverse: Block & Bloom',
    debugShowCheckedModeBanner: false,
    theme: theme.material,
    home: HomeScreen(theme: theme),
  );
}
