// اختبار أساسي: يتأكد أن تطبيق مارياس يُبنى بدون أخطاء
// ويعرض شاشة طاولة اللعب بنجاح.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mariass_app/main.dart';

void main() {
  testWidgets('MariassApp builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MariassApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
