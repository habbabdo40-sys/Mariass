import 'package:flutter/material.dart';
import 'screens/lobby_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MariassApp());
}

class MariassApp extends StatelessWidget {
  const MariassApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Mariass', debugShowCheckedModeBanner: false, home: const LobbyScreen());
  }
}
