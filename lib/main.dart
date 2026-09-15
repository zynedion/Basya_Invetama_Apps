import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
