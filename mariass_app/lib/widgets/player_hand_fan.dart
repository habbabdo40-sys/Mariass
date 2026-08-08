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
                          if (n == 0) return const SizedBox(height: 120);
                              const cardWidth = 58.0;
                                  const cardHeight = cardWidth * 1.42;
                                      return LayoutBuilder(builder: (context, constraints) {
                                            final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : cardWidth * n;
                                                  final naturalSpacing = cardWidth * 0.6;
                                                        final totalNatural = cardWidth + (n - 1) * naturalSpacing;
                                                              final spacing = (n > 1 && totalNatural > maxWidth) ? (maxWidth - cardWidth) / (n - 1) : naturalSpacing;
                                                                    final fanWidth = cardWidth + (n - 1) * spacing;
                                                                          return SizedBox(
                                                                                  width: fanWidth,
                                                                                          height: cardHeight + 22,
                                                                                                  child: Stack(alignment: Alignment.bottomCenter, children: List.generate(n, (i) {
                                                                                                            final mid = (n - 1) / 2;
                                                                                                                      final angle = (i - mid) * 0.085;
                                                                                                                                final lift = angle.abs() * 24;
                                                                                                                                          return Positioned(
                                                                                                                                                      left: i * spacing,
                                                                                                                                                                  bottom: lift,
                                                                                                                                                                              child: GestureDetector(
                                                                                                                                                                                            onTap: () => onCardTap?.call(cards[i]),
                                                                                                                                                                                                          child: Transform.rotate(
                                                                                                                                                                                                                          angle: angle,
                                                                                                                                                                                                                                          child: PlayingCardWidget(rank: cards[i].rank, suitSymbol: cards[i].suitSymbol, isRed: cards[i].isRed, width: cardWidth),
                                                                                                                                                                                                                                                        ),
                                                                                                                                                                                                                                                                    ),
                                                                                                                                                                                                                                                                              );
                                                                                                                                                                                                                                                                                      })),
                                                                                                                                                                                                                                                                                            );
                                                                                                                                                                                                                                                                                                });
                                                                                                                                                                                                                                                                                                  }
                                                                                                                                                                                                                                                                                                  }