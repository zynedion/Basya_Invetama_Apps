import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

Future<void> showSystemNotification(
  String title,
  String body,
  String? id,
) async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  await const MethodChannel(
    'basya/notifications',
  ).invokeMethod<void>('show', {'title': title, 'body': body, 'id': id});
}
