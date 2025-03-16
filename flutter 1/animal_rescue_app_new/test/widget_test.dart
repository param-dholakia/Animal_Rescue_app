import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test1/main.dart'; // Ensure this path is correct

void main() {
  testWidgets('Home screen displays the correct title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePageWidget(),  // Make sure this widget exists in main.dart
      ),
    );

    // Verify if the title "Paw Saviour" is found in the AppBar
    expect(find.text('Paw Saviour'), findsOneWidget);
  });
}
