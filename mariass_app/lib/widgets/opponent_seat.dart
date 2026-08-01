import 'package:flutter/material.dart';

class OpponentSeat extends StatelessWidget {
  final String name;
  final int cardsCount;
  const OpponentSeat({super.key, required this.name, this.cardsCount = 8});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade700, border: Border.all(color: Colors.amber, width: 2)), child: const Icon(Icons.person, color: Colors.white70)),
      const SizedBox(height: 4),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)), child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 11))),
    ]);
  }
}
