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
  final void Function(HandCard card)? onCardTap;
  const PlayerHandFan({super.key, required this.cards, this.onCardTap});

  @override
  Widget build(BuildContext context) {
    final n = cards.length;
    return SizedBox(
      width: n * 40.0 + 40,
      height: 150,
      child: Stack(alignment: Alignment.bottomCenter, children: List.generate(n, (i) {
        final angle = (i - (n - 1) / 2) * 0.13;
        return Positioned(
          left: i * 34.0,
          bottom: angle.abs() * 40,
          child: GestureDetector(
            onTap: () => onCardTap?.call(cards[i]),
            child: Transform.rotate(angle: angle, child: PlayingCardWidget(rank: cards[i].rank, suitSymbol: cards[i].suitSymbol, isRed: cards[i].isRed, width: 62)),
          ),
        );
      })),
    );
  }
}
