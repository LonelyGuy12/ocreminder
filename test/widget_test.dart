import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lonelyreminder/main.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
  });

  testWidgets('App displays bottom navigation bar', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });

  testWidgets('Reminders page has floating action buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(FloatingActionButton), findsWidgets);
  });
}
