import 'package:flutter/material.dart';

const List<Map<String, dynamic>> bidLadder = [
  {'code': 'TREFF', 'label': 'Treff ♣', 'level': 2},
  {'code': 'CARRO', 'label': 'Carro ♦', 'level': 3},
  {'code': 'COEUR', 'label': 'Cœur ♥', 'level': 4},
  {'code': 'PICK', 'label': 'Pick ♠', 'level': 5},
  {'code': 'SUN', 'label': 'Sun', 'level': 6},
  {'code': 'TOUS', 'label': 'Tous', 'level': 7},
];

class AuctionPanel extends StatelessWidget {
  final bool isFirstBidder;
  final int currentHighestLevel;
  final bool isQuensAvailable;
  final void Function(String actionCode) onDecision;

  const AuctionPanel({super.key, required this.isFirstBidder, required this.currentHighestLevel, required this.isQuensAvailable, required this.onDecision});

  @override
  Widget build(BuildContext context) {
    final available = bidLadder.where((b) => (b['level'] as int) > currentHighestLevel).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: available.map((b) => _bidButton(b['label'] as String, () => onDecision(b['code'] as String))).toList()),
        if (!isFirstBidder) ...[
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _bidButton('Bass', () => onDecision('BASS'), color: Colors.grey.shade700),
            if (isQuensAvailable) ...[const SizedBox(width: 10), _bidButton('Quens ×2', () => onDecision('QUENS'), color: Colors.red.shade700)],
          ]),
        ],
      ]),
    );
  }

  Widget _bidButton(String label, VoidCallback onTap, {Color color = const Color(0xFFB8860B)}) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
    );
  }
}
