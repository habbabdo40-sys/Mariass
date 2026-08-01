import 'package:flutter/material.dart';
import '../widgets/playing_card_widget.dart';

class GameTableScreen extends StatelessWidget {
  const GameTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF0B3D0B),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('Mariass', style: TextStyle(color: Colors.white, fontSize: 26)),
              SizedBox(height: 30),
              PlayingCardWidget(rank: 'A', suitSymbol: '♠'),
            ],
          ),
        ),
      ),
    );
  }
}
