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
  List<HandCard> trick = [];
  int tricksWon = 0;

  List<HandCard> hand = const [HandCard('A', '♠'), HandCard('K', '♥', isRed: true), HandCard('10', '♦', isRed: true), HandCard('J', '♣'), HandCard('9', '♠')];

  final botCards = const [HandCard('7', '♣'), HandCard('8', '♦', isRed: true), HandCard('Q', '♥', isRed: true)];

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
    if (showAuction || trick.length >= 4) return;
    setState(() {
      hand = hand.where((c) => c != card).toList();
      trick = [card, ...botCards];
      statusText = 'اكتملت الدورة - 4 أوراق';
    });
  }

  void clearTrick() {
    setState(() {
      tricksWon += 1;
      trick = [];
      statusText = 'أخذت الدورة! المجموع: $tricksWon';
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
                    if (trick.isNotEmpty)
                      Wrap(spacing: 4, children: trick.map((c) => PlayingCardWidget(rank: c.rank, suitSymbol: c.suitSymbol, isRed: c.isRed, width: 42)).toList()),
                    const SizedBox(height: 8),
                    Text(statusText, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                    if (trick.length >= 4) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: clearTrick, child: const Text('اجمع الأخذة')),
                    ],
                  ]),
                  const Padding(padding: EdgeInsets.only(left: 4), child: OpponentSeat(name: 'اللاعب 4')),
                ]),
              ),
              Center(child: PlayerHandFan(cards: hand, onCardTap: playCard)),
              const SizedBox(height: 10),
              if (showAuction) AuctionPanel(isFirstBidder: isFirstBidder, currentHighestLevel: currentLevel, isQuensAvailable: quensAvailable, onDecision: handleDecision),
            ]),
          ),
        ),
      ),
    );
  }
}
