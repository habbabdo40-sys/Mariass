import 'package:flutter/material.dart';

class AuctionSummaryBar extends StatelessWidget {
  final String? bidLabel;
  final String? trumpSuit;
  final bool isQuens;

  const AuctionSummaryBar({super.key, this.bidLabel, this.trumpSuit, this.isQuens = false});

  @override
  Widget build(BuildContext context) {
    if (bidLabel == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber.shade700, width: 1)),
      child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.gavel, color: Colors.amber, size: 16),
        const SizedBox(width: 6),
        Text('الحاكم: $bidLabel${trumpSuit != null ? " $trumpSuit" : ""}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        if (isQuens) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(10)), child: const Text('×2', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))],
      ]),
    );
  }
}
