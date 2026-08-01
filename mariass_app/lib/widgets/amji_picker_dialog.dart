import 'package:flutter/material.dart';
import '../widgets/playing_card_widget.dart';
import '../game_engine/trick_record.dart';

class AmjiPickerDialog extends StatelessWidget {
  final List<TrickRecord> completedTricks;
  final TrickRecord? currentTrick;
  final void Function(PlayedCard) onPick;

  const AmjiPickerDialog({super.key, required this.completedTricks, this.currentTrick, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final allTricks = [...completedTricks, if (currentTrick != null) currentTrick!];
    return Dialog(
      backgroundColor: const Color(0xFF0B3D0B),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('اختر الورقة التي تعتقد أنها مخالفة', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 400,
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: allTricks.length,
              itemBuilder: (context, trickIndex) {
                final trick = allTricks[trickIndex];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('الدورة ${trickIndex + 1}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 4),
                    Row(children: trick.plays.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: GestureDetector(
                          onTap: () => onPick(p),
                          child: Column(children: [
                            PlayingCardWidget(rank: p.card.rank, suitSymbol: p.card.suitSymbol, isRed: p.card.isRed, width: 48),
                            Text(p.playerName, style: const TextStyle(color: Colors.white54, fontSize: 9)),
                          ]),
                        ),
                      );
                    }).toList()),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
