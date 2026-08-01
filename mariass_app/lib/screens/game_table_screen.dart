import 'package:flutter/material.dart';
import '../widgets/player_hand_fan.dart';
import '../widgets/opponent_seat.dart';
import '../widgets/auction_panel.dart';

class GameTableScreen extends StatefulWidget {
  const GameTableScreen({super.key});
  @override
  State<GameTableScreen> createState() => _GameTableScreenState();
}

class _GameTableScreenState extends State<GameTableScreen> {
  bool showAuction = true;
  bool isFirstBidder = true;
  int currentLevel = 0;
  bool quensAvailable = false;
  String statusText = 'دورك: اختر نوع اللعب';

  final hand = const [HandCard('A', '♠'), HandCard('K', '♥', isRed: true), HandCard('10', '♦', isRed: true), HandCard('J', '♣'), HandCard('9', '♠')];

  void handleDecision(String code) {
    setState(() {
      if (code == 'BASS') {
        statusText = 'تم التمرير';
      } else if (code == 'QUENS') {
        statusText = 'تم اختيار Quens ×2 - بدء اللعب';
        showAuction = false;
      } else {
        final bid = bidLadder.firstWhere((b) => b['code'] == code);
        currentLevel = bid['level'] as int;
        statusText = 'الحاكم: ${bid['label']}';
        isFirstBidder = false;
        quensAvailable = true;
        showAuction = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
              Text(statusText, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const Spacer(),
              Center(child: PlayerHandFan(cards: hand)),
              const SizedBox(height: 10),
              if (showAuction) AuctionPanel(isFirstBidder: isFirstBidder, currentHighestLevel: currentLevel, isQuensAvailable: quensAvailable, onDecision: handleDecision),
            ]),
          ),
        ),
      ),
    );
  }
}
