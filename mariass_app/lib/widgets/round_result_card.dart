import 'package:flutter/material.dart';

class RoundResultCard extends StatelessWidget {
  final bool isCapot;
  final bool isSuccess;
  final int points;
  final int total;

  const RoundResultCard({super.key, required this.isCapot, required this.isSuccess, required this.points, required this.total});

  @override
  Widget build(BuildContext context) {
    final color = isCapot ? Colors.amber.shade700 : (isSuccess ? Colors.green.shade700 : Colors.red.shade700);
    final title = isCapot ? '🎉 كبّوت!' : (isSuccess ? '✅ نجحت الجولة' : '❌ فشلت الجولة');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('$points / $total نقطة', style: const TextStyle(color: Colors.white, fontSize: 15)),
      ]),
    );
  }
}
