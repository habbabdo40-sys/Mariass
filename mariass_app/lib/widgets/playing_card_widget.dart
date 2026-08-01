import 'package:flutter/material.dart';

class PlayingCardWidget extends StatelessWidget {
  final String rank;
  final String suitSymbol;
  final bool isRed;
  final double width;

  const PlayingCardWidget({super.key, required this.rank, required this.suitSymbol, this.isRed = false, this.width = 62});

  @override
  Widget build(BuildContext context) {
    final color = isRed ? const Color(0xFFC8102E) : const Color(0xFF111111);
    return Container(
      width: width,
      height: width * 1.42,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(width * 0.09), border: Border.all(color: const Color(0xFFCCCCCC), width: 0.7), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 5, offset: Offset(1, 2))]),
      child: Padding(
        padding: EdgeInsets.all(width * 0.07),
        child: Stack(children: [
          _corner(color, false),
          Center(child: Text(suitSymbol, style: TextStyle(fontSize: width * 0.42, color: color))),
          Positioned(bottom: 0, right: 0, child: Transform.rotate(angle: 3.14159, child: _corner(color, true))),
        ]),
      ),
    );
  }

  Widget _corner(Color color, bool isBottom) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(rank, style: TextStyle(fontSize: width * 0.19, fontWeight: FontWeight.w900, color: color, height: 1.0)),
      Text(suitSymbol, style: TextStyle(fontSize: width * 0.15, color: color, height: 1.0)),
    ]);
  }
}

class CardBackWidget extends StatelessWidget {
  final double width;
  const CardBackWidget({super.key, this.width = 62});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 1.42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.09),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8B0000), Color(0xFF5C0000)]),
        border: Border.all(color: Colors.amber.shade200, width: 1.2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 2))],
      ),
      child: Center(child: Container(width: width * 0.55, height: width * 0.9, decoration: BoxDecoration(borderRadius: BorderRadius.circular(width * 0.06), border: Border.all(color: Colors.amber.shade200.withOpacity(0.6), width: 1)))),
    );
  }
}
