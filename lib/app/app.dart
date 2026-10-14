import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/feedback/feedback_service.dart';
import '../settings/settings_model.dart';
import '../home/home_screen.dart';

class CandyverseApp extends StatefulWidget {
  const CandyverseApp({required this.theme, super.key});
  final AppTheme theme;
  @override
  State<CandyverseApp> createState() => _CandyverseAppState();
}

class _CandyverseAppState extends State<CandyverseApp> {
  final settings = SettingsModel();
  late final feedback = FeedbackService(settings);
  @override
  void initState() {
    super.initState();
    feedback;
  }

  @override
  void dispose() {
    feedback.dispose();
    settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SettingsScope(
    settings: settings,
    child: FeedbackScope(
      service: feedback,
      child: MaterialApp(
        title: 'Candyverse: Block & Bloom',
        debugShowCheckedModeBanner: false,
        theme: widget.theme.material,
        home: HomeScreen(theme: widget.theme),
      ),
    ),
  );
}
