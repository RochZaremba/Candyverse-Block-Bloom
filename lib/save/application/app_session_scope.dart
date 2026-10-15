import 'package:flutter/widgets.dart';

import 'app_session.dart';

class AppSessionScope extends InheritedNotifier<AppSession> {
  const AppSessionScope({
    required AppSession session,
    required super.child,
    super.key,
  }) : super(notifier: session);
  static AppSession? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSessionScope>()?.notifier;
}
