import '../widgets/player_hand_fan.dart';

const List<String> sunOrder = ['7', '8', '9', 'J', 'Q', 'K', '10', 'A'];
const Map<String, int> sunPoints = {'7': 0, '8': 0, '9': 0, 'J': 2, 'Q': 3, 'K': 4, '10': 10, 'A': 11};
const List<String> hakemTrumpOrder = ['7', '8', 'Q', 'K', '10', 'A', '9', 'J'];
const Map<String, int> hakemTrumpPoints = {'7': 0, '8': 0, 'Q': 3, 'K': 4, '10': 10, 'A': 11, '9': 14, 'J': 20};

int cardStrength(HandCard c, String? trumpSuit) {
  if (trumpSuit != null && c.suitSymbol == trumpSuit) return 100 + hakemTrumpOrder.indexOf(c.rank);
  return sunOrder.indexOf(c.rank);
}

int cardPoints(HandCard c, String? trumpSuit) {
  if (trumpSuit != null && c.suitSymbol == trumpSuit) return hakemTrumpPoints[c.rank] ?? 0;
  return sunPoints[c.rank] ?? 0;
}

HandCard determineTrickWinner(List<HandCard> trick, String? trumpSuit) {
  final ledSuit = trick[0].suitSymbol;
  final contenders = trick.where((c) => c.suitSymbol == ledSuit || (trumpSuit != null && c.suitSymbol == trumpSuit)).toList();
  return contenders.reduce((best, c) => cardStrength(c, trumpSuit) > cardStrength(best, trumpSuit) ? c : best);
}

int trickPoints(List<HandCard> trick, String? trumpSuit) {
  return trick.fold(0, (sum, c) => sum + cardPoints(c, trumpSuit));
}

bool isCardLegal(HandCard card, List<HandCard> hand, List<HandCard> currentTrick, String? trumpSuit) {
  if (currentTrick.isEmpty) return true;
  final ledSuit = currentTrick[0].suitSymbol;
  final hasLedSuit = hand.any((c) => c.suitSymbol == ledSuit);
  if (hasLedSuit) return card.suitSymbol == ledSuit;
  if (trumpSuit == null) return true;
  final hasTrump = hand.any((c) => c.suitSymbol == trumpSuit);
  if (!hasTrump) return true;
  if (card.suitSymbol != trumpSuit) return false;
  final trumpsInTrick = currentTrick.where((c) => c.suitSymbol == trumpSuit).toList();
  if (trumpsInTrick.isEmpty) return true;
  final highestTrumpSoFar = trumpsInTrick.reduce(
    (best, c) => cardStrength(c, trumpSuit) > cardStrength(best, trumpSuit) ? c : best,
  );
  final higherTrumpsInHand = hand.where(
    (c) => c.suitSymbol == trumpSuit && cardStrength(c, trumpSuit) > cardStrength(highestTrumpSoFar, trumpSuit),
  ).toList();
  if (higherTrumpsInHand.isEmpty) return true;
  return cardStrength(card, trumpSuit) > cardStrength(highestTrumpSoFar, trumpSuit);
}

bool checkAmjiViolation(List<HandCard> handBeforePlay, HandCard playedCard, List<HandCard> trickBeforePlay, String? trumpSuit) {
  return !isCardLegal(playedCard, handBeforePlay, trickBeforePlay, trumpSuit);
}


bool _isSafeLead(HandCard card, List<HandCard> playedSoFar, String? trumpSuit) {
  final order = (trumpSuit != null && card.suitSymbol == trumpSuit) ? hakemTrumpOrder : sunOrder;
  final idx = order.indexOf(card.rank);
  final higherRanks = order.sublist(idx + 1);
  final higherPlayed = playedSoFar.where(
    (c) => c.suitSymbol == card.suitSymbol && higherRanks.contains(c.rank),
  ).length;
  return higherPlayed == higherRanks.length;
}

HandCard chooseBotCard(
  List<HandCard> hand,
  List<HandCard> currentTrick,
  String? trumpSuit, [
  List<HandCard> playedSoFarThisRound = const [],
  bool partnerIsWinning = false,
  Set<String> partnerExcludedSuits = const {},
  String? partnerRequestedSuit,
]) {
  final legal = hand.where((c) => isCardLegal(c, hand, currentTrick, trumpSuit)).toList();
  if (legal.isEmpty) return hand.first;

  if (currentTrick.isEmpty) {
    if (trumpSuit != null) {
      final trumpCards = legal.where((c) => c.suitSymbol == trumpSuit).toList();
      if (trumpCards.length >= 2) {
        final trumpPlayed = playedSoFarThisRound.where((c) => c.suitSymbol == trumpSuit).length;
        final trumpRemaining = 8 - trumpPlayed - trumpCards.length;
        if (trumpRemaining > 0) {
          trumpCards.sort((a, b) => cardStrength(b, trumpSuit).compareTo(cardStrength(a, trumpSuit)));
          return trumpCards.first;
        }
      }
    }

    final nonTrump = legal.where((c) => trumpSuit == null || c.suitSymbol != trumpSuit).toList();
    if (nonTrump.isNotEmpty) {
      if (partnerRequestedSuit != null) {
        final requested = nonTrump.where((c) => c.suitSymbol == partnerRequestedSuit).toList();
        if (requested.isNotEmpty) {
          requested.sort((a, b) => cardStrength(b, trumpSuit).compareTo(cardStrength(a, trumpSuit)));
          return requested.first;
        }
      }
      final avoiding = nonTrump.where((c) => !partnerExcludedSuits.contains(c.suitSymbol)).toList();
      final pool = avoiding.isNotEmpty ? avoiding : nonTrump;
      final safeLeads = pool.where((c) => _isSafeLead(c, playedSoFarThisRound, trumpSuit)).toList();
      if (safeLeads.isNotEmpty) {
        safeLeads.sort((a, b) => cardStrength(b, trumpSuit).compareTo(cardStrength(a, trumpSuit)));
        return safeLeads.first;
      }
      pool.sort((a, b) => cardStrength(b, trumpSuit).compareTo(cardStrength(a, trumpSuit)));
      return pool.first;
    }
    legal.sort((a, b) => cardStrength(a, trumpSuit).compareTo(cardStrength(b, trumpSuit)));
    return legal.first;
  }

  if (!partnerIsWinning) {
    final canWinCards = legal.where((c) {
      final hypothetical = [...currentTrick, c];
      return determineTrickWinner(hypothetical, trumpSuit) == c;
    }).toList();

    if (canWinCards.isNotEmpty) {
      canWinCards.sort((a, b) => cardStrength(a, trumpSuit).compareTo(cardStrength(b, trumpSuit)));
      return canWinCards.first;
    }
  }

  legal.sort((a, b) => cardPoints(a, trumpSuit).compareTo(cardPoints(b, trumpSuit)));
  return legal.first;
}
