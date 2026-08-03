import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/game_table_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }
  runApp(const MariassApp());
}

class MariassApp extends StatelessWidget {
  const MariassApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Mariass', debugShowCheckedModeBanner: false, home: const GameTableScreen());
  }
}
