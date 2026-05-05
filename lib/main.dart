import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/welcome/presentation/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: AurisApp(),
    ),
  );
}

class AurisApp extends StatelessWidget {
  const AurisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auris',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const WelcomeScreen(),
    );
  }
}
