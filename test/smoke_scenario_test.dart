import 'package:candyverse/save/data/save_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/android_smoke_test.dart' as smoke;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('smoke UI sequence validates all fixture transitions on host', (
    tester,
  ) async {
    final report = <String, dynamic>{};
    await smoke.runSmokeScenario(
      tester,
      binding: binding,
      repo: SaveRepository(MemoryStorage()),
      reportData: report,
      storageKind: 'memory-host-validation',
      minimumDwellCycles: 1,
      uiTimeout: const Duration(seconds: 5),
    );
    final metrics = report['metrics'] as Map<String, dynamic>;
    expect(metrics['storageKind'], 'memory-host-validation');
    expect(metrics['requestedActiveMinutes'], 0);
    expect(metrics['dwellCycles'], 1);
    expect(metrics['dwellMoves'], greaterThan(0));
    expect(metrics['dwellReactions'], 20);
  });
}
