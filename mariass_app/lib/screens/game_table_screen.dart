import 'package:flutter/material.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/player_hand_fan.dart';
import '../widgets/opponent_seat.dart';
import '../widgets/auction_panel.dart';
import '../widgets/round_result_card.dart';
import '../widgets/auction_summary_bar.dart';
import '../widgets/amji_picker_dialog.dart';
import '../game_engine/trick_logic.dart';
import '../game_engine/deck.dart';
import '../game_engine/trick_record.dart';

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
  bool isCapot = false;
  bool isSuccess = false;
  bool matchWon = false;
  bool matchLost = false;
  bool isQuensChosen = false;
  String? bidLabel;
  String statusText = 'دورك: اختر نوع اللعب';
  List<HandCard> trick = [];
  List<PlayedCard> currentTrickPlays = [];
  List<TrickRecord> completedTricks = [];
  int myPoints = 0;
  int matchTotal = 0;
  int opponentTotal = 0;
  static const int targetScore = 1000;
  int tricksPlayed = 0;
  int myTricksWon = 0;
  String? trumpSuit;
  String? amjiResult;

  static const Map<String, String> codeToSuit = {'TREFF': '♣', 'CARRO': '♦', 'COEUR': '♥', 'PICK': '♠'};
  static const List<String> playerNames = ['أنت', 'اللاعب 2', 'اللاعب 3', 'اللاعب 4'];

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
          trumpSuit = codeToSuit[code];
        } else {
          isQuensChosen = true;
        }
        bidLabel = bid['label'] as String;
        statusText = 'الحاكم: ${bid['label']} - دورك للعب';
        showAuction = false;
      }
    });
  }

  void playCard(HandCard card) {
    if (showAuction || trick.length >= 4) return;
    if (!isCardLegal(card, hand, [], trumpSuit)) {
      final hasTrump = trumpSuit != null && hand.any((c) => c.suitSymbol == trumpSuit);
      setState(() => statusText = hasTrump ? 'غير مسموح! يجب القطع بالحكم' : 'غير مسموح! يجب اتباع نفس اللون');
      return;
    }
    setState(() {
      amjiResult = null;
      final handBefore = List<HandCard>.from(hand);
      hand = hand.where((c) => c != card).toList();
      currentTrickPlays = [PlayedCard(card: card, playerName: playerNames[0], handBeforePlay: handBefore, trickBeforePlay: [])];

      final playedSoFar = <HandCard>[card];
      final bots = <HandCard>[];
      for (int i = 1; i <= 3; i++) {
        final botHandBefore = List<HandCard>.from(allHands[i]);
        final chosen = chooseBotCard(botHandBefore, playedSoFar, trumpSuit);
        currentTrickPlays.add(PlayedCard(card: chosen, playerName: playerNames[i], handBeforePlay: botHandBefore, trickBeforePlay: List.from(playedSoFar)));
        allHands[i] = allHands[i].where((c) => c != chosen).toList();
        bots.add(chosen);
        playedSoFar.add(chosen);
      }

      trick = [card, ...bots];
      final winner = determineTrickWinner(trick, trumpSuit);
      final points = trickPoints(trick, trumpSuit);
      statusText = 'الفائز: ${winner.rank} ${winner.suitSymbol} (+$points نقطة)';
    });
  }

  void openAmjiPicker() {
    showDialog(
      context: context,
      builder: (context) => AmjiPickerDialog(
        completedTricks: completedTricks,
        currentTrick: currentTrickPlays.isNotEmpty ? TrickRecord(currentTrickPlays) : null,
        onPick: (picked) {
          Navigator.pop(context);
          final violation = checkAmjiViolation(picked.handBeforePlay, picked.card, picked.trickBeforePlay, trumpSuit);
          setState(() {
            amjiResult = violation ? '✅ أمجي صحيح! ${picked.playerName} خالف القاعدة' : '❌ خطأ! ${picked.playerName} لم يخالف - انقلب عليك الأمجي';
          });
        },
      ),
    );
  }

  void nextTrick() {
    setState(() {
      final points = trickPoints(trick, trumpSuit);
      final winner = determineTrickWinner(trick, trumpSuit);
      final iWon = winner == trick[0];
      if (iWon) {
        myPoints += points;
        myTricksWon += 1;
      }
      completedTricks.add(TrickRecord(List.from(currentTrickPlays)));
      currentTrickPlays = [];
      tricksPlayed += 1;
      trick = [];
      amjiResult = null;
      if (hand.isEmpty) {
        roundOver = true;
        isCapot = myTricksWon == 8;
        final total = trumpSuit != null ? 162 : 260;
        final threshold = total ~/ 2;
        isSuccess = isCapot || myPoints >= threshold;
        if (isCapot) myPoints = trumpSuit != null ? 250 : 350;
        if (isSuccess) {
          matchTotal += myPoints;
        } else {
          opponentTotal += total;
        }
        if (matchTotal >= targetScore) matchWon = true;
        if (opponentTotal >= targetScore) matchLost = true;
        statusText = '';
      } else {
        statusText = 'دورك للعب - نقاطك حتى الآن: $myPoints';
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
      isCapot = false;
      isSuccess = false;
      isQuensChosen = false;
      bidLabel = null;
      trick = [];
      currentTrickPlays = [];
      completedTricks = [];
      amjiResult = null;
      myPoints = 0;
      tricksPlayed = 0;
      myTricksWon = 0;
      trumpSuit = null;
      statusText = 'دورك: اختر نوع اللعب';
      _dealNewHands();
    });
  }

  void startNewMatch() {
    setState(() {
      matchTotal = 0;
      opponentTotal = 0;
      matchWon = false;
      matchLost = false;
      startNewRound();
    });
  }

  @override
  Widget build(BuildContext context) {
    final remaining = 8 - tricksPlayed;
    final total = trumpSuit != null ? 162 : 260;
    final matchOver = matchWon || matchLost;
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Container(
          color: const Color(0xFF0B3D0B),
          child: SafeArea(
            child: Stack(children: [
              Column(children: [
                Padding(padding: const EdgeInsets.all(10), child: Text('Mariass | أنت: $matchTotal - الخصم: $opponentTotal', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                if (!showAuction) AuctionSummaryBar(bidLabel: bidLabel, trumpSuit: trumpSuit, isQuens: isQuensChosen),
                OpponentSeat(name: 'اللاعب 2', cardsCount: remaining),
                Expanded(
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Padding(padding: const EdgeInsets.only(right: 4), child: OpponentSeat(name: 'اللاعب 3', cardsCount: remaining)),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      if (matchWon)
                        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.amber.shade800, borderRadius: BorderRadius.circular(16)), child: const Text('🏆 فزت بالمباراة!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)))
                      else if (matchLost)
                        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.red.shade900, borderRadius: BorderRadius.circular(16)), child: const Text('😞 خسرت المباراة', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)))
                      else if (roundOver)
                        RoundResultCard(isCapot: isCapot, isSuccess: isSuccess, points: myPoints, total: total)
                      else ...[
                        if (trick.isNotEmpty) Wrap(spacing: 4, children: trick.map((c) => PlayingCardWidget(rank: c.rank, suitSymbol: c.suitSymbol, isRed: c.isRed, width: 42, highlight: trumpSuit != null && c.suitSymbol == trumpSuit)).toList()),
                        const SizedBox(height: 8),
                        Text(statusText, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                        if (amjiResult != null) ...[const SizedBox(height: 6), Text(amjiResult!, style: const TextStyle(color: Colors.yellowAccent, fontSize: 12), textAlign: TextAlign.center)],
                      ],
                      if (trick.length >= 4 && !roundOver) ...[const SizedBox(height: 8), ElevatedButton(onPressed: nextTrick, child: const Text('الدورة التالية'))],
                      if (roundOver && !matchOver) ...[const SizedBox(height: 16), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800), onPressed: startNewRound, child: const Text('جولة جديدة', style: TextStyle(color: Colors.white)))],
                      if (matchOver) ...[const SizedBox(height: 16), ElevatedButton(onPressed: startNewMatch, child: const Text('مباراة جديدة'))],
                    ]),
                    Padding(padding: const EdgeInsets.only(left: 4), child: OpponentSeat(name: 'اللاعب 4', cardsCount: remaining)),
                  ]),
                ),
                Center(child: PlayerHandFan(cards: hand, onCardTap: playCard)),
                const SizedBox(height: 10),
                if (showAuction) AuctionPanel(isFirstBidder: isFirstBidder, currentHighestLevel: currentLevel, isQuensAvailable: quensAvailable, onDecision: handleDecision),
              ]),
              if (!showAuction && !roundOver && (completedTricks.isNotEmpty || currentTrickPlays.isNotEmpty))
                Positioned(bottom: 170, right: 16, child: FloatingActionButton.extended(backgroundColor: Colors.red.shade700, onPressed: openAmjiPicker, icon: const Icon(Icons.flag), label: const Text('Amji'))),
            ]),
          ),
        ),
      ),
    );
  }
}
