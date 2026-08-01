import 'package:flutter/material.dart';
import 'screens/auction_demo_screen.dart';

void main() {
  runApp(const MariassApp());
}

class MariassApp extends StatelessWidget {
  const MariassApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Mariass', debugShowCheckedModeBanner: false, home: const AuctionDemoScreen());
  }
}
