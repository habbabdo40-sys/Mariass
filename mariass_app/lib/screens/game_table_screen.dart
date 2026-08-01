import 'package:flutter/material.dart';
import '../widgets/playing_card_widget.dart';
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
  HandCard? playedCard;

  List<HandCard> hand = const [HandCard('A', '♠'), HandCard('K', '♥', isRed: true), HandCard('10', '♦', isRed: true), HandCard('J', '♣'), HandCard('9', '♠')];

  void handleDecision(String code) {
    setState(() {
      if (code == 'BASS') {
        statusText = 'تم التمرير';
      } else {
        final bid = code == 'QUENS' ? {'label': 'Quens ×2'} : bidLadder.firstWhere((b) => b['code'] == code);
        if (code != 'QUENS') {
          currentLevel = bidLadder.firstWhere((b) => b['code'] == code)['level'] as int;
          isFirstBidder = false;
          quensAvailable = true;
        }
        statusText = 'الحاكم: ${bid['label']} - دورك للعب';
        showAuction = false;
      }
    });
  }

  void playCard(HandCard card) {
    setState(() {
      playedCard = card;
      hand = hand.where((c) => c != card).toList();
      statusText = 'رميت: ${card.rank} ${card.suitSymbol}';
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
              const Padding(padding: EdgeInsets.all(12), child: Text('Mariass', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
              const OpponentSeat(name: 'اللاعب 2'),
              Expanded(
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Padding(padding: EdgeInsets.only(right: 4), child: OpponentSeat(name: 'اللاعب 3')),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    if (playedCard != null) PlayingCardWidget(rank: playedCard!.rank, suitSymbol: playedCard!.suitSymbol, isRed: playedCard!.isRed, width: 56),
                    const SizedBox(height: 8),
                    Text(statusText, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                  ]),
                  const Padding(padding: EdgeInsets.only(left: 4), child: OpponentSeat(name: 'اللاعب 4')),
                ]),
              ),
              GestureDetector(
                onTapUp: (details) {
                  if (!showAuction && hand.isNotEmpty) playCard(hand.first);
                },
                child: Center(child: PlayerHandFan(cards: hand)),
              ),
              const SizedBox(height: 10),
              if (showAuction) AuctionPanel(isFirstBidder: isFirstBidder, currentHighestLevel: currentLevel, isQuensAvailable: quensAvailable, onDecision: handleDecision),
            ]),
          ),
        ),
      ),
    );
  }
}
