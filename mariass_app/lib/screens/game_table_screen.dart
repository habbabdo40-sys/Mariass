import 'package:flutter/material.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/player_hand_fan.dart';
import '../widgets/opponent_seat.dart';
import '../widgets/auction_panel.dart';
import '../game_engine/trick_logic.dart';
import '../game_engine/deck.dart';

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
  bool roundOver = false;
  String statusText = 'دورك: اختر نوع اللعب';
  List<HandCard> trick = [];
  int tricksWon = 0;
  int tricksPlayed = 0;

  late List<List<HandCard>> allHands;
  late List<HandCard> hand;

  @override
  void initState() {
    super.initState();
    _dealNewHands();
  }

  void _dealNewHands() {
    allHands = dealFourHands();
    hand = List.from(allHands[0]);
  }

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
      final bots = [allHands[1][tricksPlayed], allHands[2][tricksPlayed], allHands[3][tricksPlayed]];
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
        roundOver = true;
        statusText = 'انتهت الجولة! إجمالي أخذاتك: $tricksWon من 8';
      } else {
        statusText = 'دورك للعب - أخذاتك حتى الآن: $tricksWon';
      }
    });
  }

  void startNewRound() {
    setState(() {
      showAuction = true;
      isFirstBidder = true;
      currentLevel = 0;
      quensAvailable = false;
      roundOver = false;
      trick = [];
      tricksWon = 0;
      tricksPlayed = 0;
      statusText = 'دورك: اختر نوع اللعب';
      _dealNewHands();
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
                    if (trick.length >= 4 && !roundOver) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: nextTrick, child: const Text('الدورة التالية')),
                    ],
                    if (roundOver) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800),
                        onPressed: startNewRound,
                        child: const Text('جولة جديدة', style: TextStyle(color: Colors.white)),
                      ),
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
