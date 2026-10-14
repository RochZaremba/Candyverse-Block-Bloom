import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Original vector jelly: recessed empty cells and glossy candy blocks.
class CandyTile extends StatelessWidget {
  const CandyTile({
    required this.theme,
    this.skin,
    this.ghost = false,
    this.invalid = false,
    super.key,
  });
  final AppTheme theme;
  final String? skin;
  final bool ghost;
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    final color = theme.palette[skin] ?? theme.color('candyPink');
    return Padding(
      padding: const EdgeInsets.all(2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: skin == null
              ? theme.color('ink').withValues(alpha: .07)
              : null,
          gradient: skin == null
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(color, theme.color('creamWhite'), .4)!,
                    color,
                  ],
                ),
          border: Border.all(
            color: invalid
                ? theme.color('danger')
                : skin == null
                ? theme.color('ink').withValues(alpha: .06)
                : theme.color('creamWhite').withValues(alpha: ghost ? .9 : .5),
            width: invalid ? 2 : 1,
          ),
          boxShadow: skin == null || ghost
              ? null
              : [
                  BoxShadow(
                    color: theme.color('ink').withValues(alpha: .16),
                    offset: const Offset(0, 2),
                    blurRadius: 1,
                  ),
                ],
        ),
        child: skin == null
            ? null
            : Opacity(
                opacity: ghost ? .45 : 1,
                child: Align(
                  alignment: const Alignment(-.45, -.6),
                  child: FractionallySizedBox(
                    widthFactor: .48,
                    heightFactor: .16,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.color('creamWhite').withValues(alpha: .65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
