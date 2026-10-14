import '../../core/localization/app_strings.dart';

import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../core/theme/app_theme.dart';
import '../data/save_repository.dart';
import 'app_session.dart';

class SaveBootstrap extends StatefulWidget {
  const SaveBootstrap({required this.theme, this.repository, super.key});
  final AppTheme theme;
  final SaveRepository? repository;
  @override
  State<SaveBootstrap> createState() => _SaveBootstrapState();
}

class _SaveBootstrapState extends State<SaveBootstrap> {
  late final repository =
      widget.repository ?? SaveRepository(PreferencesStorage());
  AppSession? session;
  Object? failure;
  bool loading = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      failure = null;
    });
    try {
      var save = await repository.load();
      // A valid terminal checkpoint from an interrupted prior version is
      // finalized before it can be exposed as a playable run.
      if (save.activeRun != null) {
        final next = save.completeRun(save.activeRun!.id);
        if (!identical(next, save)) {
          await repository.save(next);
          save = next;
        }
      }
      if (mounted) setState(() => session = AppSession(repository, save));
    } catch (e) {
      if (mounted) setState(() => failure = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (session != null) {
      return CandyverseApp(theme: widget.theme, session: session!);
    }
    return MaterialApp(
      theme: widget.theme.material,
      home: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      const CircularProgressIndicator()
                    else ...[
                      appText(
                        context,
                        'Nie można otworzyć zapisu',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      appText(
                        context,
                        'Twój zapis nie został zastąpiony. Możesz ponowić próbę.',
                      ),
                      FilledButton(
                        onPressed: _load,
                        child: appText(context, 'Spróbuj ponownie'),
                      ),
                      if (failure is SaveRecoveryRequired)
                        TextButton(
                          onPressed: () => _recoverFrom(context),
                          child: appText(context, 'Rozpocznij od nowa'),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _recoverFrom(BuildContext dialogContext) async {
    // The dialog must use the context below MaterialApp's Navigator.
    final yes = await showDialog<bool>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: appText(context, 'Zastąpić uszkodzony zapis?'),
        content: appText(
          context,
          'Postęp z tego zapisu zostanie utracony. Kopia pozostanie lokalnie do diagnostyki.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: appText(context, 'Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: appText(context, 'Rozpocznij od nowa'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await repository.storage.remove(SaveRepository.key);
      await _load();
    } catch (e) {
      if (mounted) setState(() => failure = e);
    }
  }
}
