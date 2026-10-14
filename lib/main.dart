import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'save/application/save_bootstrap.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final theme = await AppTheme.load();
  runApp(SaveBootstrap(theme: theme));
}
