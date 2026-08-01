import 'package:flutter/material.dart';

void main() {
  runApp(const MariassApp());
}

class MariassApp extends StatelessWidget {
  const MariassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mariass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const Scaffold(
        backgroundColor: Color(0xFF0B3D0B),
        body: Center(
          child: Text(
            'Mariass',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
