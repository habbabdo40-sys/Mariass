import '../widgets/player_hand_fan.dart';

const List<String> sunOrder = ['7', '8', '9', 'J', 'Q', 'K', '10', 'A'];
const Map<String, int> sunPoints = {'7': 0, '8': 0, '9': 0, 'J': 2, 'Q': 3, 'K': 4, '10': 10, 'A': 11};

HandCard determineTrickWinner(List<HandCard> trick) {
  final ledSuit = trick[0].suitSymbol;
  final contenders = trick.where((c) => c.suitSymbol == ledSuit).toList();
  return contenders.reduce((best, c) => sunOrder.indexOf(c.rank) > sunOrder.indexOf(best.rank) ? c : best);
}

int trickPoints(List<HandCard> trick) {
  return trick.fold(0, (sum, c) => sum + (sunPoints[c.rank] ?? 0));
}
