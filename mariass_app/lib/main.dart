import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/lobby_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MariassApp());
}

Future<void> _initFirebase() async {
  await Firebase.initializeApp();
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }
}

class MariassApp extends StatelessWidget {
  const MariassApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mariass',
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: _initFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('خطأ في الاتصال: ${snapshot.error}', style: const TextStyle(color: Colors.red)))));
          }
          return const LobbyScreen();
        },
      ),
    );
  }
}
