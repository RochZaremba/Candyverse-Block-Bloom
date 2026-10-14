import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/feedback/feedback_service.dart';
import '../settings/settings_model.dart';
import '../home/home_screen.dart';
import '../save/application/app_session.dart';

class CandyverseApp extends StatefulWidget {
  const CandyverseApp({required this.theme, required this.session, super.key});
  final AppTheme theme;
  final AppSession session;
  @override
  State<CandyverseApp> createState() => _CandyverseAppState();
}

class _CandyverseAppState extends State<CandyverseApp> {
  SettingsModel get settings => widget.session.settings;
  late final feedback = FeedbackService(settings);
  @override
  void initState() {
    super.initState();
    feedback;
  }

  @override
  void dispose() {
    feedback.dispose();
    widget.session.dispose();
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
        home: ListenableBuilder(
          listenable: widget.session,
          builder: (context, _) =>
              HomeScreen(theme: widget.theme, session: widget.session),
        ),
      ),
    ),
  );
}
