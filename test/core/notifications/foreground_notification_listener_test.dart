import 'dart:async';
import 'package:basya_investama/core/notifications/foreground_notification_listener.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Foreground messages use system notifications without an overlay', (tester) async {
    final messages = StreamController<RemoteMessage>();
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('basya/notifications'), (call) async { calls.add(call); });
    await tester.pumpWidget(MaterialApp(
      builder: (_, child) => ForegroundNotificationListener(messages: messages.stream, child: child!),
      home: const Scaffold(body: Text('Beranda')),
    ));
    messages.add(const RemoteMessage(messageId: 'test-message',
      notification: RemoteNotification(title: 'Kabar Basya', body: 'Pesan baru')));
    await tester.pumpAndSettle();
    expect(calls.single.method, 'show');
    expect(calls.single.arguments['title'], 'Kabar Basya');
    expect(find.text('Kabar Basya'), findsNothing);
    expect(find.byType(Dismissible), findsNothing);
    expect(find.text('Beranda'), findsOneWidget);
    messages.add(const RemoteMessage(data: {'event': 'silent'}));
    await tester.pumpAndSettle();
    expect(calls.length, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(messages.hasListener, isFalse);
    unawaited(messages.close());
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('basya/notifications'), null);
  });
}
