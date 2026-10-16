import 'package:flutter/material.dart';

import 'candy_controls.dart';

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

void showCandyMessage(
  BuildContext context,
  String message, {
  bool success = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xfffff6e6),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: success ? const Color(0xff63cba5) : const Color(0xffed8db8),
          width: 3,
        ),
      ),
      content: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: const SizedBox(
              width: 48,
              height: 48,
              child: CandyBrandImage(icon: true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xff382453),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class CandyDialog extends StatelessWidget {
  const CandyDialog({
    required this.title,
    required this.content,
    this.actions = const [],
    super.key,
  });
  final Widget title;
  final Widget content;
  final List<Widget> actions;
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
            const CandyFriends(height: 120),
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
                              tone: i == 0
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
