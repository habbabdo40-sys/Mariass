import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final String? roomCode;
  final int myIndex;
  final List<String>? playerUids;
  const GameTableScreen({super.key, this.roomCode, this.myIndex = 0, this.playerUids});
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
  List<bool> hasPassedBid = [false, false, false, false];
  int leaderIndex = 0;
  int? declarerIndex;
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
    _startPresenceSync();
  }

  final _db = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _handsSub;
  StreamSubscription<DatabaseEvent>? _bidSub;
  int _bidTurnGlobal = 0;
  StreamSubscription<DatabaseEvent>? _trickSub;
  List<String> _trickPlaysRaw = [];
  bool _trickStarted = false;
  StreamSubscription<DatabaseEvent>? _presenceSub;
    StreamSubscription<DatabaseEvent>? _connectionSub;
      Map<String, bool> _onlineStatus = {};
        Timer? _turnTimeoutTimer;
  bool _isBotSeat(int g) {
    final uids = widget.playerUids;
    if (uids == null || g < 0 || g >= uids.length) return false;
    final uid = uids[g];
    if (uid.startsWith('bot_')) return true;
    if (_onlineStatus[uid] == false) return true;
    return false;
  }

  void _startPresenceSync() {
    if (widget.roomCode == null) return;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid != null) {
      final myPlayerRef = _db.child('rooms/${widget.roomCode}/players/$myUid');
      _connectionSub = _db.child('.info/connected').onValue.listen((event) {
        final connected = event.snapshot.value as bool? ?? false;
        if (connected) {
          myPlayerRef.child('online').onDisconnect().set(false);
          myPlayerRef.update({'online': true});
        }
      });
    }
    _presenceSub = _db.child('rooms/${widget.roomCode}/players').onValue.listen((event) {
      if (!event.snapshot.exists) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final updated = <String, bool>{};
      data.forEach((uid, val) {
        final playerData = Map<String, dynamic>.from(val as Map);
        updated[uid] = playerData['online'] as bool? ?? true;
      });
      setState(() {
        _onlineStatus = updated;
      });
    });
  }

  int _localFromGlobal(int g) => (g - widget.myIndex + 4) % 4;
  int _globalFromLocal(int l) => (widget.myIndex + l) % 4;

  void _dealNewHands() {
    if (widget.roomCode == null) {
      allHands = dealFourHands();
      hand = List.from(allHands[0]);
      return;
    }
    _handsSub?.cancel();
    final gameRef = _db.child('rooms/${widget.roomCode}/game/hands');
    if (widget.myIndex == 0) {
      final newHands = dealFourHands();
      final serialized = {
        for (int i = 0; i < 4; i++)
          'p$i': newHands[i].map((c) => '${c.rank}|${c.suitSymbol}|${c.isRed}').toList()
      };
      gameRef.set(serialized);
    }
    _handsSub = gameRef.onValue.listen((event) {
      if (!event.snapshot.exists) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final loaded = List<List<HandCard>>.generate(4, (i) {
        final list = List<dynamic>.from(data['p$i'] as List);
        return list.map((raw) {
          final parts = (raw as String).split('|');
          return HandCard(parts[0], parts[1], isRed: parts[2] == 'true');
        }).toList();
      });
      final rotated = List<List<HandCard>>.generate(4, (i) => loaded[(widget.myIndex + i) % 4]);
      setState(() {
        allHands = rotated;
        hand = List.from(allHands[0]);
      });
      _handsSub?.cancel();
      _startBidSync();
    });
  }

  @override
  void dispose() {
    _handsSub?.cancel();
    _bidSub?.cancel();
    _trickSub?.cancel();
    _presenceSub?.cancel();
        _connectionSub?.cancel();
            _turnTimeoutTimer?.cancel();
                super.dispose();
                }

  void _startBidSync() {
    if (widget.roomCode == null) return;
    _bidSub?.cancel();
    final bidRef = _db.child('rooms/${widget.roomCode}/game/bid');
    if (widget.myIndex == 0) {
      bidRef.set({
        'turn': 0,
        'level': 0,
        'quensAvailable': false,
        'trumpSuit': null,
        'declarer': null,
        'bidLabel': null,
        'hasPassed': [false, false, false, false],
        'isFirstBidder': true,
        'showAuction': true,
        'statusText': 'دور المزايدة الأول',
      });
    }
    _bidSub = bidRef.onValue.listen((event) {
      if (!event.snapshot.exists) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final hasPassedGlobal = List<dynamic>.from(data['hasPassed'] as List).map((e) => e == true).toList();
      final turnGlobal = data['turn'] as int? ?? 0;
      final auctionOn = data['showAuction'] as bool? ?? true;
      final declarerGlobal = data['declarer'] as int?;
      setState(() {
        currentLevel = data['level'] as int? ?? 0;
        quensAvailable = data['quensAvailable'] as bool? ?? false;
        trumpSuit = data['trumpSuit'] as String?;
        bidLabel = data['bidLabel'] as String?;
        declarerIndex = declarerGlobal == null ? null : _localFromGlobal(declarerGlobal);
        isFirstBidder = data['isFirstBidder'] as bool? ?? false;
        showAuction = auctionOn;
        statusText = data['statusText'] as String? ?? statusText;
        hasPassedBid = List.generate(4, (l) => hasPassedGlobal[_globalFromLocal(l)]);
        _bidTurnGlobal = turnGlobal;
      });
      if (!auctionOn) {
              _turnTimeoutTimer?.cancel();
                      if (!_trickStarted) {
                                _trickStarted = true;
                                          _startTrickSync();
                                                  }
                                                          return;
                                                                }
                                                                      _turnTimeoutTimer?.cancel();
                                                                            if (widget.myIndex == 0 && _isBotSeat(turnGlobal)) {
                                                                                    _hostDecideBotBid(turnGlobal, data);
                                                                                          } else if (widget.myIndex == 0) {
                                                                                                  _turnTimeoutTimer = Timer(const Duration(seconds: 30), () => _hostTimeoutBid(turnGlobal));
                                                                                                        }
                                                                                                            });
                                                                                                              }

                                                                                                                void _hostTimeoutBid(int seat) async {
                                                                                                                    final bidRef = _db.child('rooms/${widget.roomCode}/game/bid');
                                                                                                                        final snap = await bidRef.get();
                                                                                                                            if (!snap.exists) return;
                                                                                                                                final data = Map<String, dynamic>.from(snap.value as Map);
                                                                                                                                    final currentTurn = data['turn'] as int? ?? -1;
                                                                                                                                        if (currentTurn != seat) return;
                                                                                                                                            _hostDecideBotBid(seat, data);
                                                                                                                                              }

                                                                                                                                                void _hostDecideBotBid(int seat, Map<String, dynamic> data) {
      final cardsInSuit = hand.where((c) => c.suitSymbol == suit).toList();
      final points = cardsInSuit.fold<int>(0, (sum, c) => sum + cardPoints(c, suit));
      scores[entry.key] = cardsInSuit.length * 15 + points;
    }
    final bestSuitCode = scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final bestSuitLevel = bidLadder.firstWhere((b) => b['code'] == bestSuitCode)['level'] as int;
    final sunPointsTotal = hand.fold<int>(0, (sum, c) => sum + cardPoints(c, null));
    String? chosenCode;
    if (scores[bestSuitCode]! >= 70 && bestSuitLevel > level) {
      chosenCode = bestSuitCode;
    } else if (sunPointsTotal >= 25 && 6 > level) {
      chosenCode = 'SUN';
    } else if (scores[bestSuitCode]! >= 55 && bestSuitLevel > level) {
      chosenCode = bestSuitCode;
    }
    _applyOrPassBidRemote(seat, chosenCode ?? 'BASS');
  }

  void _startTrickSync() {
    if (widget.roomCode == null) return;
    _trickSub?.cancel();
    final trickRef = _db.child('rooms/${widget.roomCode}/game/trick');
    if (widget.myIndex == 0) {
      trickRef.set({'plays': <String>[], 'leader': 0, 'turn': 0});
    }
    _trickSub = trickRef.onValue.listen((event) {
      if (!event.snapshot.exists) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final playsRaw = List<dynamic>.from(data['plays'] as List? ?? []);
      final leaderGlobal = data['leader'] as int? ?? 0;
      final turnGlobal = data['turn'] as int? ?? leaderGlobal;
      _trickPlaysRaw = playsRaw.cast<String>();

      setState(() {
        leaderIndex = _localFromGlobal(leaderGlobal);
        final newPlays = <PlayedCard>[];
        for (final raw in _trickPlaysRaw) {
          final parts = raw.split('|');
          final seatGlobal = int.parse(parts[0]);
          final card = HandCard(parts[1], parts[2], isRed: parts[3] == 'true');
          final seatLocal = _localFromGlobal(seatGlobal);
          final handBefore = List<HandCard>.from(allHands[seatLocal]);
          final trickBefore = newPlays.map((p) => p.card).toList();
          allHands[seatLocal] = allHands[seatLocal].where((c) => c != card).toList();
          if (seatLocal == 0) hand = List.from(allHands[0]);
          newPlays.add(PlayedCard(card: card, playerName: playerNames[seatLocal], handBeforePlay: handBefore, trickBeforePlay: trickBefore));
        }
        currentTrickPlays = newPlays;
        trick = newPlays.map((p) => p.card).toList();
      });

      if (currentTrickPlays.length >= 4) {
              _turnTimeoutTimer?.cancel();
                      _processCompletedTrickAndAdvance(trickRef);
                              return;
                                    }
                                          _turnTimeoutTimer?.cancel();
                                                if (widget.myIndex == 0 && _isBotSeat(turnGlobal)) {
                                                        _hostPlayBotCard(turnGlobal, trickRef);
                                                              } else if (widget.myIndex == 0) {
                                                                      _turnTimeoutTimer = Timer(const Duration(seconds: 30), () => _hostTimeoutCard(turnGlobal));
                                                                            }
                                                                                });
                                                                                  }

                                                                                    void _hostTimeoutCard(int seatGlobal) async {
                                                                                        final trickRef = _db.child('rooms/${widget.roomCode}/game/trick');
                                                                                            final snap = await trickRef.get();
                                                                                                if (!snap.exists) return;
                                                                                                    final data = Map<String, dynamic>.from(snap.value as Map);
                                                                                                        final currentTurn = data['turn'] as int? ?? -1;
                                                                                                            if (currentTurn != seatGlobal) return;
                                                                                                                _hostPlayBotCard(seatGlobal, trickRef);
                                                                                                                  }

                                                                                                                    void _processCompletedTrickAndAdvance(DatabaseReference trickRef) {
    final points = trickPoints(trick, trumpSuit);
    final winner = determineTrickWinner(trick, trumpSuit);
    final winnerPlay = currentTrickPlays.firstWhere((p) => p.card == winner);
    final winnerIndexLocal = playerNames.indexOf(winnerPlay.playerName);
    final iWon = winnerIndexLocal == 0 || winnerIndexLocal == 1;
    setState(() {
      if (iWon) {
        myPoints += points;
        myTricksWon += 1;
      }
      completedTricks.add(TrickRecord(List.from(currentTrickPlays)));
      currentTrickPlays = [];
      tricksPlayed += 1;
      trick = [];
      amjiResult = null;
      leaderIndex = winnerIndexLocal;
      statusText = 'ربح ${winner.rank}${winner.suitSymbol} (+$points نقطة)';

      if (hand.isEmpty) {
        roundOver = true;
        isCapot = myTricksWon == 8;
        final total = trumpSuit != null ? 162 : 260;
        final threshold = total ~/ 2;
        isSuccess = isCapot || myPoints >= threshold;
        if (isCapot) myPoints = trumpSuit != null ? 250 : 350;
        final multiplier = isQuensChosen ? 2 : 1;
        if (isSuccess) {
          matchTotal += myPoints * multiplier;
        } else {
          opponentTotal += total * multiplier;
        }
        if (matchTotal >= targetScore) matchWon = true;
        if (opponentTotal >= targetScore) matchLost = true;
        statusText = '';
      }
    });

    if (widget.myIndex != 0) return;
    if (hand.isEmpty) return; // نهاية الجولة: startNewRound يعيد التوزيع لاحقاً
    final winnerGlobal = _globalFromLocal(winnerIndexLocal);
    trickRef.set({'plays': <String>[], 'leader': winnerGlobal, 'turn': winnerGlobal});
  }

  void _hostPlayBotCard(int seatGlobal, DatabaseReference trickRef) {
    final seatLocal = _localFromGlobal(seatGlobal);
    final botHandBefore = List<HandCard>.from(allHands[seatLocal]);
    final playedSoFar = currentTrickPlays.map((p) => p.card).toList();
    final allPlayedThisRound = [
      ...completedTricks.expand((t) => t.plays.map((p) => p.card)),
      ...playedSoFar,
    ];
    final myTeam = seatLocal == 0 || seatLocal == 1 ? 0 : 1;
    final partnerIsWinning = playedSoFar.isNotEmpty && (() {
      final currentBest = determineTrickWinner(playedSoFar, trumpSuit);
      final bestPlay = currentTrickPlays.firstWhere((p) => p.card == currentBest);
      final bestIndex = playerNames.indexOf(bestPlay.playerName);
      final bestTeam = bestIndex == 0 || bestIndex == 1 ? 0 : 1;
      return bestTeam == myTeam;
    })();
    final partnerIndex = seatLocal == 0 ? 1 : (seatLocal == 1 ? 0 : (seatLocal == 2 ? 3 : 2));
    final signals = _analyzePartnerSignals(partnerIndex);
    final declarerTeam = declarerIndex == null ? null : (declarerIndex == 0 || declarerIndex == 1 ? 0 : 1);
    final isDeclarerTeam = declarerTeam == myTeam;
    final chosen = chooseBotCard(botHandBefore, playedSoFar, trumpSuit, allPlayedThisRound,
        partnerIsWinning, signals['excluded'] as Set<String>, signals['requested'] as String?, isDeclarerTeam);

    final newPlays = List<String>.from(_trickPlaysRaw)
      ..add('$seatGlobal|${chosen.rank}|${chosen.suitSymbol}|${chosen.isRed}');
    trickRef.update({'plays': newPlays, 'turn': (seatGlobal + 1) % 4});
  }

  void _submitMyCard(HandCard card) {
    if (widget.roomCode == null) return;
    final trickRef = _db.child('rooms/${widget.roomCode}/game/trick');
    final seatGlobal = widget.myIndex;
    final newPlays = List<String>.from(_trickPlaysRaw)
      ..add('$seatGlobal|${card.rank}|${card.suitSymbol}|${card.isRed}');
    trickRef.update({'plays': newPlays, 'turn': (seatGlobal + 1) % 4});
  }

  void _submitMyBid(String code) {
    _applyOrPassBidRemote(widget.myIndex, code);
  }

  Future<void> _applyOrPassBidRemote(int seat, String code) async {
    final bidRef = _db.child('rooms/${widget.roomCode}/game/bid');
    final snap = await bidRef.get();
    if (!snap.exists) return;
    final data = Map<String, dynamic>.from(snap.value as Map);
    final hasPassed = List<dynamic>.from(data['hasPassed'] as List).map((e) => e == true).toList();
    int level = data['level'] as int? ?? 0;
    bool quens = data['quensAvailable'] as bool? ?? false;
    String? suit = data['trumpSuit'] as String?;
    int? declarer = data['declarer'] as int?;
    String? label = data['bidLabel'] as String?;
    String newStatus;

    if (code == 'QUENS') {
      quens = true;
      newStatus = '${playerNames[_localFromGlobal(seat)]}: اختار كوينز';
    } else if (code == 'BASS') {
      hasPassed[seat] = true;
      newStatus = '${playerNames[_localFromGlobal(seat)]}: مرر';
    } else {
      final bid = bidLadder.firstWhere((b) => b['code'] == code);
      level = bid['level'] as int;
      suit = codeToSuit[code];
      declarer = seat;
      label = bid['label'] as String;
      newStatus = '${playerNames[_localFromGlobal(seat)]}: ${bid['label']}';
    }

    final nextTurn = (seat + 1) % 4;
    final remainingActive = List.generate(4, (i) => i).where((i) => i > seat && !hasPassed[i]).toList();
    final stop = seat == 3 || level >= 7 || remainingActive.isEmpty;

    await bidRef.update({
      'hasPassed': hasPassed,
      'level': level,
      'quensAvailable': quens,
      'trumpSuit': suit,
      'declarer': declarer,
      'bidLabel': label,
      'isFirstBidder': false,
      'turn': stop ? seat : nextTurn,
      'showAuction': !stop,
      'statusText': newStatus,
    });
  }

  void handleDecision(String code) {
    if (widget.roomCode != null) {
      _submitMyBid(code);
      return;
    }
    setState(() {
      if (code == 'QUENS') {
        isQuensChosen = true;
        bidLabel = 'Quens x2';
        statusText = 'دور اللعب: Quens x2';
      } else if (code == 'BASS') {
        hasPassedBid[0] = true;
        statusText = 'تم التمرير';
      } else {
        _applyBid(0, code);
      }
      isFirstBidder = false;
      _runBotBidding();
      final activePlayers = List.generate(4, (i) => i).where((i) => !hasPassedBid[i]).toList();
      if (activePlayers.length <= 1 || currentLevel >= 7) {
        showAuction = false;
      }
    });
  }

  void _applyBid(int playerIndex, String code) {
    final bid = bidLadder.firstWhere((b) => b['code'] == code);
    declarerIndex = playerIndex;
    currentLevel = bid['level'] as int;
    quensAvailable = true;
    trumpSuit = codeToSuit[code];
    bidLabel = bid['label'] as String;
    statusText = playerIndex == 0
        ? 'دور اللعب: ${bid['label']}'
        : '${playerNames[playerIndex]} زايد: ${bid['label']}';
  }

  void _runBotBidding() {
    for (int i = 1; i <= 3; i++) {
      if (hasPassedBid[i]) continue;
      final activeCount = List.generate(4, (j) => j).where((j) => !hasPassedBid[j]).length;
      if (activeCount <= 1 || currentLevel >= 7) break;
      final hand = allHands[i];
      final scores = <String, int>{};
      for (final entry in codeToSuit.entries) {
        final suit = entry.value;
        final cardsInSuit = hand.where((c) => c.suitSymbol == suit).toList();
        final points = cardsInSuit.fold<int>(0, (sum, c) => sum + cardPoints(c, suit));
        scores[entry.key] = cardsInSuit.length * 15 + points;
      }
      final bestSuitCode = scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      final bestSuitLevel = bidLadder.firstWhere((b) => b['code'] == bestSuitCode)['level'] as int;
      final sunPointsTotal = hand.fold<int>(0, (sum, c) => sum + cardPoints(c, null));

      String? chosenCode;
      if (scores[bestSuitCode]! >= 70 && bestSuitLevel > currentLevel) {
        chosenCode = bestSuitCode;
      } else if (sunPointsTotal >= 25 && 6 > currentLevel) {
        chosenCode = 'SUN';
      } else if (scores[bestSuitCode]! >= 55 && bestSuitLevel > currentLevel) {
        chosenCode = bestSuitCode;
      }

      if (chosenCode != null) {
        _applyBid(i, chosenCode);
      } else {
        hasPassedBid[i] = true;
      }
    }
  }

  Map<String, dynamic> _analyzePartnerSignals(int partnerIndex) {
    final partnerName = playerNames[partnerIndex];
    final excluded = <String>{};
    String? requested;
    for (final t in completedTricks) {
      if (t.plays.isEmpty) continue;
      final ledSuit = t.plays[0].card.suitSymbol;
      if (trumpSuit == null || ledSuit != trumpSuit) continue;
      final partnerPlays = t.plays.where((p) => p.playerName == partnerName).toList();
      if (partnerPlays.isEmpty) continue;
      final card = partnerPlays.first.card;
      if (card.suitSymbol == trumpSuit) continue;
      if (card.rank == 'A') {
        requested = card.suitSymbol;
      } else {
        excluded.add(card.suitSymbol);
      }
    }
    return {'excluded': excluded, 'requested': requested};
  }

  void playCard(HandCard card) {
    if (widget.roomCode != null) {
      if (showAuction || currentTrickPlays.length >= 4) return;
      final order = List.generate(4, (i) => (leaderIndex + i) % 4);
      final humanTurnIndex = order.indexOf(0);
      if (currentTrickPlays.length != humanTurnIndex) return;
      final currentTrick = currentTrickPlays.map((p) => p.card).toList();
      if (!isCardLegal(card, hand, currentTrick, trumpSuit)) {
        final hasTrump = trumpSuit != null && hand.any((c) => c.suitSymbol == trumpSuit);
        setState(() => statusText = hasTrump ? 'يجب لعب الحكم أو تعليته إن أمكن' : 'يجب مجاراة اللون المفتوح');
        return;
      }
      _submitMyCard(card);
      return;
    }
    if (showAuction || currentTrickPlays.length >= 4) return;
    final order = List.generate(4, (i) => (leaderIndex + i) % 4);
    final humanTurnIndex = order.indexOf(0);
    if (currentTrickPlays.length != humanTurnIndex) return;
    final currentTrick = currentTrickPlays.map((p) => p.card).toList();
    if (!isCardLegal(card, hand, currentTrick, trumpSuit)) {
      final hasTrump = trumpSuit != null && hand.any((c) => c.suitSymbol == trumpSuit);
      setState(() => statusText = hasTrump ? 'يجب اللعب بلون الحكم إن أمكن' : 'يجب اللعب بنفس لون الورقة المفتوحة');
      return;
    }
    setState(() {
      amjiResult = null;
      final handBefore = List<HandCard>.from(hand);
      hand = hand.where((c) => c != card).toList();
      currentTrickPlays.add(PlayedCard(card: card, playerName: playerNames[0], handBeforePlay: handBefore, trickBeforePlay: List.from(currentTrick)));
      trick.add(card);

      for (int step = humanTurnIndex + 1; step < 4; step++) {
        final i = order[step];
        final botHandBefore = List<HandCard>.from(allHands[i]);
        final playedSoFar = currentTrickPlays.map((p) => p.card).toList();
        final allPlayedThisRound = [
          ...completedTricks.expand((t) => t.plays.map((p) => p.card)),
          ...playedSoFar,
        ];
        final myTeam = i == 0 || i == 1 ? 0 : 1;
        final partnerIsWinning = playedSoFar.isNotEmpty && (() {
          final currentBest = determineTrickWinner(playedSoFar, trumpSuit);
          final bestPlay = currentTrickPlays.firstWhere((p) => p.card == currentBest);
          final bestIndex = playerNames.indexOf(bestPlay.playerName);
          final bestTeam = bestIndex == 0 || bestIndex == 1 ? 0 : 1;
          return bestTeam == myTeam;
        })();
        final partnerIndex = i == 0 ? 1 : (i == 1 ? 0 : (i == 2 ? 3 : 2));
        final signals = _analyzePartnerSignals(partnerIndex);
        final declarerTeam = declarerIndex == null ? null : (declarerIndex == 0 || declarerIndex == 1 ? 0 : 1);
        final isDeclarerTeam = declarerTeam == myTeam;
        final chosen = chooseBotCard(botHandBefore, playedSoFar, trumpSuit, allPlayedThisRound, partnerIsWinning, signals['excluded'] as Set<String>, signals['requested'] as String?, isDeclarerTeam);
        currentTrickPlays.add(PlayedCard(card: chosen, playerName: playerNames[i], handBeforePlay: botHandBefore, trickBeforePlay: List.from(playedSoFar)));
        allHands[i] = allHands[i].where((c) => c != chosen).toList();
        trick.add(chosen);
      }

      final winner = determineTrickWinner(trick, trumpSuit);
      final points = trickPoints(trick, trumpSuit);
      statusText = 'ربح ${winner.rank}${winner.suitSymbol} (+$points نقطة)';
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
      final winnerPlay = currentTrickPlays.firstWhere((p) => p.card == winner);
      final winnerIndex = playerNames.indexOf(winnerPlay.playerName);
      final iWon = winnerIndex == 0 || winnerIndex == 1;
      if (iWon) {
        myPoints += points;
        myTricksWon += 1;
      }
      completedTricks.add(TrickRecord(List.from(currentTrickPlays)));
      currentTrickPlays = [];
      tricksPlayed += 1;
      trick = [];
      amjiResult = null;
      leaderIndex = winnerIndex;
      if (hand.isEmpty) {
        roundOver = true;
        isCapot = myTricksWon == 8;
        final total = trumpSuit != null ? 162 : 260;
        final threshold = total ~/ 2;
        isSuccess = isCapot || myPoints >= threshold;
        if (isCapot) myPoints = trumpSuit != null ? 250 : 350;
        final multiplier = isQuensChosen ? 2 : 1;
        if (isSuccess) {
          matchTotal += myPoints * multiplier;
        } else {
          opponentTotal += total * multiplier;
        }
        if (matchTotal >= targetScore) matchWon = true;
        if (opponentTotal >= targetScore) matchLost = true;
        statusText = '';
      } else {
        statusText = 'دور اللعب: $myPoints';
        _playLeadingBots();
      }
    });
  }

  void _playLeadingBots() {
    final order = List.generate(4, (i) => (leaderIndex + i) % 4);
    final humanTurnIndex = order.indexOf(0);
    for (int step = 0; step < humanTurnIndex; step++) {
      final i = order[step];
      final botHandBefore = List<HandCard>.from(allHands[i]);
      final playedSoFar = currentTrickPlays.map((p) => p.card).toList();
      final allPlayedThisRound = [
        ...completedTricks.expand((t) => t.plays.map((p) => p.card)),
        ...playedSoFar,
      ];
      final myTeam = i == 0 || i == 1 ? 0 : 1;
      final partnerIsWinning = playedSoFar.isNotEmpty && (() {
        final currentBest = determineTrickWinner(playedSoFar, trumpSuit);
        final bestPlay = currentTrickPlays.firstWhere((p) => p.card == currentBest);
        final bestIndex = playerNames.indexOf(bestPlay.playerName);
        final bestTeam = bestIndex == 0 || bestIndex == 1 ? 0 : 1;
        return bestTeam == myTeam;
      })();
      final partnerIndex = i == 0 ? 1 : (i == 1 ? 0 : (i == 2 ? 3 : 2));
      final signals = _analyzePartnerSignals(partnerIndex);
      final declarerTeam = declarerIndex == null ? null : (declarerIndex == 0 || declarerIndex == 1 ? 0 : 1);
      final isDeclarerTeam = declarerTeam == myTeam;
      final chosen = chooseBotCard(botHandBefore, playedSoFar, trumpSuit, allPlayedThisRound, partnerIsWinning, signals['excluded'] as Set<String>, signals['requested'] as String?, isDeclarerTeam);
      currentTrickPlays.add(PlayedCard(card: chosen, playerName: playerNames[i], handBeforePlay: botHandBefore, trickBeforePlay: List.from(playedSoFar)));
      allHands[i] = allHands[i].where((c) => c != chosen).toList();
      trick.add(chosen);
    }
  }

  void startNewRound() {
    _trickStarted = false;
    setState(() {
      showAuction = true;
      isFirstBidder = true;
      currentLevel = 0;
      quensAvailable = false;
      roundOver = false;
      isCapot = false;
      isSuccess = false;
      isQuensChosen = false;
      hasPassedBid = [false, false, false, false];
      declarerIndex = null;
      bidLabel = null;
      trick = [];
      currentTrickPlays = [];
      completedTricks = [];
      leaderIndex = 0;
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
                if (showAuction) IgnorePointer(ignoring: widget.roomCode != null && _bidTurnGlobal != widget.myIndex, child: Opacity(opacity: (widget.roomCode != null && _bidTurnGlobal != widget.myIndex) ? 0.4 : 1.0, child: AuctionPanel(isFirstBidder: isFirstBidder, currentHighestLevel: currentLevel, isQuensAvailable: quensAvailable, onDecision: handleDecision))),
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
