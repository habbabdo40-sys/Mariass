import 'package:flutter/material.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/player_hand_fan.dart';
import '../widgets/opponent_seat.dart';
import '../widgets/auction_panel.dart';
import '../game_engine/trick_logic.dart';

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
  int tricksPlayed = 0;

  List<HandCard> hand = [const HandCard('A', '♠'), const HandCard('K', '♥', isRed: true), const HandCard('10', '♦', isRed: true), const HandCard('J', '♣'), const HandCard('9', '♠')];
  final List<List<HandCard>> botHands = [
    [const HandCard('7', '♣'), const HandCard('8', '♦', isRed: true), const HandCard('Q', '♥', isRed: true)],
    [const HandCard('8', '♠'), const HandCard('7', '♥', isRed: true), const HandCard('9', '♦', isRed: true)],
    [const HandCard('Q', '♣'), const HandCard('K', '♦', isRed: true), const HandCard('7', '♠')],
    [const HandCard('J', '♥', isRed: true), const HandCard('9', '♣'), const HandCard('8', '♥', isRed: true)],
    [const HandCard('K', '♣'), const HandCard('Q', '♠'), const HandCard('J', '♦', isRed: true)],
  ];

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
    if (showAuction || trick.length >= 4 || tricksPlayed >= hand.length + tricksPlayed) return;
    setState(() {
      hand = hand.where((c) => c != card).toList();
      final bots = botHands[tricksPlayed];
      trick = [card, ...bots];
      final winner = determineTrickWinner(trick);
      statusText = 'الفائز بالدورة: ${winner.rank} ${winner.suitSymbol}';
    });
  }

  void nextTrick() {
    setState(() {
      tricksWon += 1;
      tricksPlayed += 1;
      trick = [];
      if (hand.isEmpty) {
        statusText = 'انتهت الجولة! إجمالي أخذاتك: $tricksWon من 5';
      } else {
        statusText = 'دورك للعب - أخذاتك حتى الآن: $tricksWon';
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
              Padding(padding: const EdgeInsets.all(12), child: Text('Mariass - أخذات: $tricksWon', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
              const OpponentSeat(name: 'اللاعب 2'),
              Expanded(
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Padding(padding: EdgeInsets.only(right: 4), child: OpponentSeat(name: 'اللاعب 3')),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    if (trick.isNotEmpty)
                      Wrap(spacing: 4, children: trick.map((c) => PlayingCardWidget(rank: c.rank, suitSymbol: c.suitSymbol, isRed: c.isRed, width: 42)).toList()),
                    const SizedBox(height: 8),
                    Text(statusText, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                    if (trick.length >= 4 && hand.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: nextTrick, child: const Text('الدورة التالية')),
                    ] else if (trick.length >= 4 && hand.isEmpty) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: nextTrick, child: const Text('إنهاء الجولة')),
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
