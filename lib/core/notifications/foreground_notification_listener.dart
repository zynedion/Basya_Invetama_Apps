import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'system_notification.dart';

/// Receives foreground messages without drawing an in-app overlay.
class ForegroundNotificationListener extends StatefulWidget {
  const ForegroundNotificationListener({
    super.key,
    required this.messages,
    required this.child,
  });

  final Stream<RemoteMessage> messages;
  final Widget child;

  @override
  State<ForegroundNotificationListener> createState() =>
      _ForegroundNotificationListenerState();
}

class _ForegroundNotificationListenerState
    extends State<ForegroundNotificationListener> {
  StreamSubscription<RemoteMessage>? _subscription;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _subscription = widget.messages.listen((message) {
      final title = message.notification?.title?.trim() ?? '';
      final body = message.notification?.body?.trim() ?? '';
      // Data-only messages may be silent updates, not user-facing alerts.
      if (!mounted || (title.isEmpty && body.isEmpty)) return;
      unawaited(
        showSystemNotification(
          title.isEmpty ? 'Basya Investama' : title,
          body,
          message.messageId,
        ).catchError((Object _) {
          // System notification failure must not interrupt the app.
        }),
      );
    }, onError: (Object _) {});
  }

  @override
  void didUpdateWidget(ForegroundNotificationListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages != widget.messages) {
      unawaited(_subscription?.cancel());
      _listen();
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

