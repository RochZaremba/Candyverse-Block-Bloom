import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The checked-in design tokens are the single source of visual values.
class AppTheme {
  AppTheme._(this.palette, this.panelRadius);

  final Map<String, Color> palette;
  final double panelRadius;

  static Future<AppTheme> load() async {
    final json = jsonDecode(
      await rootBundle.loadString('assets/design_tokens.json'),
    ) as Map<String, dynamic>;
    final palette = (json['palette'] as Map<String, dynamic>).map(
      (name, hex) => MapEntry(
        name,
        Color(int.parse((hex as String).replaceFirst('#', 'FF'), radix: 16)),
      ),
    );
    return AppTheme._(palette, (json['radiusDp']['panel'] as num).toDouble());
  }

  Color color(String name) => palette[name]!;

  ThemeData get material => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: color('candyPink'),
      surface: color('creamWhite'),
      onSurface: color('ink'),
    ),
    scaffoldBackgroundColor: color('creamWhite'),
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: color('ink'),
      displayColor: color('ink'),
    ),
  );
}
