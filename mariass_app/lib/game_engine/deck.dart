import 'dart:math';
import '../widgets/player_hand_fan.dart';

const List<String> suits = ['♠', '♥', '♦', '♣'];
const List<String> ranks = ['7', '8', '9', 'J', 'Q', 'K', '10', 'A'];
const List<String> redSuits = ['♥', '♦'];

List<HandCard> buildDeck() {
  final deck = <HandCard>[];
  for (final suit in suits) {
    for (final rank in ranks) {
      deck.add(HandCard(rank, suit, isRed: redSuits.contains(suit)));
    }
  }
  return deck;
}

List<List<HandCard>> dealFourHands() {
  final deck = buildDeck();
  deck.shuffle(Random());
  return [
    deck.sublist(0, 8),
    deck.sublist(8, 16),
    deck.sublist(16, 24),
    deck.sublist(24, 32),
  ];
}
