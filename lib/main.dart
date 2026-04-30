import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Firebase/Notification init error: $e');
  }

  runApp(const AloVuApp());
}

class AloVuApp extends StatelessWidget {
  const AloVuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ALOVU - Đặt sân thể thao',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: Colors.green[600],
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
