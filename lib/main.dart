import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/notifications/foreground_notification_listener.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('[FCM][main] Initializing app; kIsWeb=$kIsWeb, platform=$defaultTargetPlatform');
  if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) {
    try {
      final app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('[FCM][main] Firebase initialized successfully: ${app.name}');
    } catch (e, stack) {
      print('[FCM][main] Firebase.initializeApp error: $e\n$stack');
    }
  }
  print('[FCM][main] Firebase.apps count: ${Firebase.apps.length}');
  runApp(const BasyaApp());
}

class BasyaApp extends StatelessWidget {
  const BasyaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Basya Investama',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    builder: (context, child) => ForegroundNotificationListener(
      messages: Firebase.apps.isEmpty
          ? const Stream<RemoteMessage>.empty()
          : FirebaseMessaging.onMessage,
      child: child ?? const SizedBox.shrink(),
    ),
    home: const SplashPage(),
  );
}
