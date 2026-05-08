// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ltdd_alovu/main.dart';

void main() {
  testWidgets('App renders correctly smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Lệnh này hiện tại có thể fail nghiệm trọng nếu chưa mock Firebase
    // nhưng sẽ giải quyết lỗi biên dịch "MyApp isn't a class" trước mắt.
    await tester.pumpWidget(const AloVuApp());

    // Verify that the app is built (bạn có thể thêm expect logic sau nhé)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
