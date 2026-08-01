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
  return card.suitSymbol == trumpSuit;
}

bool checkAmjiViolation(List<HandCard> handBeforePlay, HandCard playedCard, List<HandCard> trickBeforePlay, String? trumpSuit) {
  return !isCardLegal(playedCard, handBeforePlay, trickBeforePlay, trumpSuit);
}
