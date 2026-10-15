import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'save/application/save_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'core/presentation/kingdom_assets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final theme = await AppTheme.load();
  await warmKingdomAssets();
  runApp(SaveBootstrap(theme: theme));
}
