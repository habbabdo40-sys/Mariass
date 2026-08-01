import 'package:flutter/material.dart';

class PlayingCardWidget extends StatelessWidget {
  final String rank;
  final String suitSymbol;
  final bool isRed;
  final double width;

  const PlayingCardWidget({super.key, required this.rank, required this.suitSymbol, this.isRed = false, this.width = 60});

  @override
  Widget build(BuildContext context) {
    final color = isRed ? Colors.red.shade700 : Colors.black87;
    return Container(
      width: width,
      height: width * 1.4,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 2))]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(rank, style: TextStyle(fontSize: width * 0.28, fontWeight: FontWeight.bold, color: color)),
        Text(suitSymbol, style: TextStyle(fontSize: width * 0.32, color: color)),
      ]),
    );
  }
}

class CardBackWidget extends StatelessWidget {
  final double width;
  const CardBackWidget({super.key, this.width = 60});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 1.4,
      decoration: BoxDecoration(color: Colors.red.shade900, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.amber.shade200, width: 1.2)),
    );
  }
}
