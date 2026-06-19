import 'package:artemis_business_os/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ArtemisApp boots and shows the splash gate', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ArtemisApp()));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
