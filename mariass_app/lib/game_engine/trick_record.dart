import '../widgets/player_hand_fan.dart';

class PlayedCard {
  final HandCard card;
  final String playerName;
  final List<HandCard> handBeforePlay;
  final List<HandCard> trickBeforePlay;

  PlayedCard({required this.card, required this.playerName, required this.handBeforePlay, required this.trickBeforePlay});
}

class TrickRecord {
  final List<PlayedCard> plays;
  TrickRecord(this.plays);
}
