import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The checked-in design tokens are the single source of visual values.
class AppTheme {
  AppTheme._(
    this.palette,
    this.panelRadius,
    this.tileRadius,
    this.cardRadius,
    this.tilePlaceMs,
    this.lineClearMs,
    this.maxParticles,
  );

  final Map<String, Color> palette;
  final double panelRadius;
  final double tileRadius;
  final double cardRadius;
  final int tilePlaceMs;
  final int lineClearMs;
  final int maxParticles;

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
    return AppTheme._(
      palette,
      (json['radiusDp']['panel'] as num).toDouble(),
      (json['radiusDp']['tile'] as num).toDouble(),
      (json['radiusDp']['card'] as num).toDouble(),
      json['motionMs']['tilePlace'] as int,
      json['motionMs']['lineClear'] as int,
      json['particles']['maxConcurrent'] as int,
    );
  }

  Color color(String name) => palette[name]!;

  ThemeData get material => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: color('candyPink'),
      surface: color('creamWhite'),
      onSurface: color('ink'),
    ),
    scaffoldBackgroundColor: color('creamWhite'),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: 'Roboto',
      bodyColor: color('ink'),
      displayColor: color('ink'),
    ),
  );
}
