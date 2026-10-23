import 'package:flutter/material.dart';

import 'candy_controls.dart';
import '../localization/app_strings.dart';

/// Candyverse's supplied artwork, cropped by layout without editing the source.
class CandyBrandImage extends StatelessWidget {
  const CandyBrandImage({this.icon = false, super.key});
  final bool icon;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Original sheet: 1536×1024; banner top1536×512, icon bottom-left512².
          final scale = icon ? width / 512 : width / 1536;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: 0,
                top: icon ? -512 * scale : 0,
                width: 1536 * scale,
                height: 1024 * scale,
                child: Image.asset(
                  'assets/kingdom/brand-sheet.png',
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

enum CandyNoticeKind { information, success, error }

class CandyNotice extends StatelessWidget {
  const CandyNotice({
    required this.message,
    this.kind = CandyNoticeKind.information,
    this.onDismiss,
    this.action,
    super.key,
  });
  final String message;
  final CandyNoticeKind kind;
  final VoidCallback? onDismiss;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(16) > 22;
    final glyph = CandyGlyph(switch (kind) {
      CandyNoticeKind.success => CandySymbol.success,
      CandyNoticeKind.error => CandySymbol.attention,
      CandyNoticeKind.information => CandySymbol.info,
    });
    final dismiss = onDismiss == null
        ? const SizedBox.shrink()
        : IconButton(
            onPressed: onDismiss,
            tooltip: AppStrings.of(context)
                .text('Zamknij komunikat', 'Dismiss message'),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.close_rounded, color: candyInk),
          );
    final text = ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .4,
      ),
      child: SingleChildScrollView(
        child: Text(
          message,
          style: const TextStyle(
            color: candyInk,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
    return Semantics(
      liveRegion: true,
      child: CandyPanel(
        radius: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (large) ...[
              Row(children: [glyph, const Spacer(), dismiss]),
              const SizedBox(height: 8),
              text,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  glyph,
                  const SizedBox(width: 10),
                  Expanded(child: text),
                  dismiss,
                ],
              ),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}

void showCandyMessage(
  BuildContext context,
  String message, {
  bool success = false,
  bool error = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.removeCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.all(12),
      duration: MediaQuery.accessibleNavigationOf(context)
          ? const Duration(days: 1)
          : const Duration(seconds: 8),
      content: CandyNotice(
        message: message,
        kind: error
            ? CandyNoticeKind.error
            : success
            ? CandyNoticeKind.success
            : CandyNoticeKind.information,
        onDismiss: messenger.hideCurrentSnackBar,
      ),
    ),
  );
}

class CandyDialog extends StatelessWidget {
  const CandyDialog({
    required this.title,
    required this.content,
    this.actions = const [],
    this.showFriends = true,
    super.key,
  });
  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final bool showFriends;
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showFriends) const CandyFriends(height: 120),
            CandyPanel(
              radius: 34,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DefaultTextStyle.merge(
                    style: const TextStyle(
                      fontFamily: 'LilitaOne',
                      fontSize: 27,
                      color: candyInk,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                    child: title is Text && (title as Text).data != null
                        ? CandyLettering(
                            (title as Text).data!,
                            size: 29,
                            color: const Color(0xffff94d8),
                          )
                        : title,
                  ),
                  const SizedBox(height: 14),
                  DefaultTextStyle.merge(
                    style: const TextStyle(
                      color: candyInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * .30,
                      ),
                      child: SingleChildScrollView(child: content),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < actions.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child:
                          actions[i] is ButtonStyleButton &&
                              (actions[i] as ButtonStyleButton).child is Text
                          ? CandyAction(
                              key: actions[i].key,
                              label:
                                  ((actions[i] as ButtonStyleButton).child
                                          as Text)
                                      .data ??
                                  '',
                              onPressed:
                                  (actions[i] as ButtonStyleButton).onPressed,
                              tone: actions[i].key == const Key('confirm-reset')
                                  ? CandyButtonTone.pink
                                  : i == 0
                                  ? CandyButtonTone.gold
                                  : CandyButtonTone.aqua,
                              fontSize: 22,
                              height: 58,
                            )
                          : actions[i],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
