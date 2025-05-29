import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_ui/login.dart'; // Adjust the path if different

void main() {
  testWidgets('Login screen UI loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    // Verify presence of Login title
    expect(find.text('Login'), findsOneWidget);

    // Verify presence of Username and Password fields
    expect(find.widgetWithText(TextField, 'Username'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);

    // Verify presence of Login button
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });
}
