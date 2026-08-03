import 'package:flutter/material.dart';

void main() {
  runApp(const MariassApp());
}

class MariassApp extends StatelessWidget {
  const MariassApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('Hello Mariass', style: TextStyle(fontSize: 30)))),
    );
  }
}
