import 'package:flutter/material.dart';
import '../widgets/auction_panel.dart';

class AuctionDemoScreen extends StatefulWidget {
  const AuctionDemoScreen({super.key});
  @override
  State<AuctionDemoScreen> createState() => _AuctionDemoScreenState();
}

class _AuctionDemoScreenState extends State<AuctionDemoScreen> {
  bool isFirstBidder = true;
  int currentLevel = 0;
  String log = 'دور المزايد الأول: يجب الاختيار';
  bool quensAvailable = false;

  void handleDecision(String code) {
    setState(() {
      if (code == 'BASS') {
        log = 'تم التمرير (Bass)';
      } else if (code == 'QUENS') {
        log = 'تم اختيار Quens ×2 - انتهى المزاد!';
      } else {
        final bid = bidLadder.firstWhere((b) => b['code'] == code);
        currentLevel = bid['level'] as int;
        log = 'تم اختيار ${bid['label']}';
        isFirstBidder = false;
        quensAvailable = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Container(
          color: const Color(0xFF0B3D0B),
          child: SafeArea(
            child: Column(children: [
              const Padding(padding: EdgeInsets.all(16), child: Text('Mariass - المزاد', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
              const Spacer(),
              Text(log, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const Spacer(),
              AuctionPanel(isFirstBidder: isFirstBidder, currentHighestLevel: currentLevel, isQuensAvailable: quensAvailable, onDecision: handleDecision),
            ]),
          ),
        ),
      ),
    );
  }
}
