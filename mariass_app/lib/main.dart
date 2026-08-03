import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/game_table_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MariassApp());
  try {
    await Firebase.initializeApp();
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
}

class MariassApp extends StatelessWidget {
  const MariassApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Mariass', debugShowCheckedModeBanner: false, home: const GameTableScreen());
  }
}
