import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: const Color(0xfffff8eb),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
      side: const BorderSide(color: Color(0xffeea3c7), width: 3),
    ),
    title: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: const SizedBox(
            width: 72,
            height: 72,
            child: CandyBrandImage(icon: true),
          ),
        ),
        const SizedBox(height: 12),
        title,
      ],
    ),
    content: content,
    actions: actions,
    actionsOverflowButtonSpacing: 8,
  );
}
