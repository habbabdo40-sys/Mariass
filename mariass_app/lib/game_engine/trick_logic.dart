import '../widgets/player_hand_fan.dart';

const List<String> sunOrder = ['7', '8', '9', 'J', 'Q', 'K', '10', 'A'];

HandCard determineTrickWinner(List<HandCard> trick) {
  final ledSuit = trick[0].suitSymbol;
  final contenders = trick.where((c) => c.suitSymbol == ledSuit).toList();
  return contenders.reduce((best, c) => sunOrder.indexOf(c.rank) > sunOrder.indexOf(best.rank) ? c : best);
}
