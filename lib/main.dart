import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // Notification setup must not prevent access to the app.
      debugPrint(
        'Firebase initialization unavailable; notifications disabled.',
      );
    }
  }
  runApp(const BasyaApp());
}

class BasyaApp extends StatelessWidget {
  const BasyaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Basya Investama',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const SplashPage(),
  );
}
