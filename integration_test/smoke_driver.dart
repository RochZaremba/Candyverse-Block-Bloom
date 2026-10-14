import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final directory = Directory(
    Platform.environment['CANDYVERSE_QA_OUTPUT'] ?? 'build/qa-smoke',
  )..createSync(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      await File('${directory.path}/$safeName.png').writeAsBytes(bytes);
      return true;
    },
    responseDataCallback: (data) async {
      await File('${directory.path}/report.json').writeAsString(
        const JsonEncoder.withIndent('  ')
            .convert(data?['metrics'] ?? {'status': 'failed-before-metrics'}),
      );
    },
  );
}
