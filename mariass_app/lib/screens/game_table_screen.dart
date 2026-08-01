import 'package:flutter/material.dart';
import '../widgets/player_hand_fan.dart';
import '../widgets/opponent_seat.dart';

class GameTableScreen extends StatelessWidget {
  const GameTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hand = const [HandCard('A', '♠'), HandCard('K', '♥', isRed: true), HandCard('10', '♦', isRed: true), HandCard('J', '♣'), HandCard('9', '♠')];
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Container(
          color: const Color(0xFF0B3D0B),
          child: SafeArea(
            child: Column(children: [
              const Padding(padding: EdgeInsets.all(12), child: Text('Mariass', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
              const OpponentSeat(name: 'اللاعب 2'),
              const Spacer(),
              const Text('طاولة اللعب', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const Spacer(),
              Center(child: PlayerHandFan(cards: hand)),
              const SizedBox(height: 10),
            ]),
          ),
        ),
      ),
    );
  }
}
