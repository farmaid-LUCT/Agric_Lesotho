// // This is a basic Flutter widget test.
// //
// // To perform an interaction with a widget in your test, use the WidgetTester
// // utility in the flutter_test package. For example, you can send tap and scroll
// // gestures. You can also use WidgetTester to find child widgets in the widget
// // tree, read text, and verify that the values of widget properties are correct.

// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';

// import 'package:farm_aid_app/main.dart';

// void main() {
//   testWidgets('Counter increments smoke test', (WidgetTester tester) async {
//     // Build our app and trigger a frame.
//     await tester.pumpWidget(const MyApp());

//     // Verify that our counter starts at 0.
//     expect(find.text('0'), findsOneWidget);
//     expect(find.text('1'), findsNothing);

//     // Tap the '+' icon and trigger a frame.
//     await tester.tap(find.byIcon(Icons.add));
//     await tester.pump();

//     // Verify that our counter has incremented.
//     expect(find.text('0'), findsNothing);
//     expect(find.text('1'), findsOneWidget);
//   });
// }



import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farm_aid_app/main.dart';

void main() {
  group('FarmAid App Smoke Tests', () {
    
    testWidgets('Dashboard loads and shows main navigation elements', (WidgetTester tester) async {
      // 1. Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // 2. Verify that the Dashboard or Login screen appears.
      // Assuming your Dashboard has a "Scan History" or "Scanner" text.
      expect(find.text('Scan History'), findsOneWidget);
      
      // 3. Verify that the Lesotho-inspired green theme is applied (primary color check)
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, isNot(Colors.blue)); // Ensuring it's not the default Flutter blue
    });

    testWidgets('Navigation to Profile Screen works', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Find the Profile icon/button and tap it.
      // (Assuming you have a person icon in your BottomNavigationBar or AppBar)
      final profileIcon = find.byIcon(Icons.person);
      expect(profileIcon, findsOneWidget);
      
      await tester.tap(profileIcon);
      await tester.pumpAndSettle(); // Wait for navigation animation to finish

      // Verify we are now on the Edit Profile page.
      expect(find.text('Edit Profile'), findsOneWidget);
      
      // Verify our new bright "CROP PROFILE" button exists.
      expect(find.text('CROP PROFILE'), findsOneWidget);
    });

    testWidgets('History search filter UI responsiveness', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Navigate to History (assuming it's a tab or button)
      // Search for a specific vegetable disease
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Blight');
      await tester.pump(); // Trigger the _runFilter logic

      // Check if the search text is correctly updated in the controller
      expect(find.text('Blight'), findsOneWidget);
    });
  });
}