import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifikasi')),
    // Content will come from the backend GET API, not FCM payloads.
    body: const SizedBox.expand(),
  );
}
