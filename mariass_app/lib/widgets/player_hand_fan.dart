import 'package:flutter/material.dart';
import 'playing_card_widget.dart';

class HandCard {
  final String rank;
  final String suitSymbol;
  final bool isRed;
  const HandCard(this.rank, this.suitSymbol, {this.isRed = false});
}

class PlayerHandFan extends StatelessWidget {
  final List<HandCard> cards;
  const PlayerHandFan({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    final n = cards.length;
    final spread = (n - 1) * 0.13;
    return SizedBox(
      height: 150,
      child: Stack(alignment: Alignment.bottomCenter, children: List.generate(n, (i) {
        final angle = -spread / 2 + i * 0.13;
        return Transform.translate(
          offset: Offset(i * 30.0 - (n * 15), angle.abs() * -70),
          child: Transform.rotate(angle: angle, child: PlayingCardWidget(rank: cards[i].rank, suitSymbol: cards[i].suitSymbol, isRed: cards[i].isRed, width: 66)),
        );
      })),
    );
  }
}
