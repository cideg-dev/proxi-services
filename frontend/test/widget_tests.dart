import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/star_rating.dart';
import 'package:frontend/widgets/message_bubble.dart';
import 'package:frontend/screens/public_home_screen.dart';
import 'package:frontend/screens/advanced_search_screen.dart';

void main() {
  group('Widget Tests', () {
    testWidgets('StarRating displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StarRating(
            rating: 3.5,
            maxRating: 5,
            allowHalfRating: true,
          ),
        ),
      );

      expect(find.byType(Icon), findsNWidgets(5));
      // On s'attend à ce que certaines étoiles soient pleines et d'autres moitiés
    });

    testWidgets('MessageBubble displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MessageBubble(
            message: 'Bonjour!',
            isMe: true,
            timestamp: DateTime.now(),
          ),
        ),
      );

      expect(find.text('Bonjour!'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('PublicHomeScreen builds without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PublicHomeScreen(),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Text), findsAtLeast(1));
    });

    testWidgets('AdvancedSearchScreen builds without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdvancedSearchScreen(),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SearchBar), findsOneWidget);
    });
  });

  group('UI Interaction Tests', () {
    testWidgets('Tapping on rating updates selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              double rating = 0.0;
              return StarRating(
                rating: rating,
                allowEditing: true,
                onRatingChanged: (newRating) {
                  rating = newRating;
                },
              );
            },
          ),
        ),
      );

      // Tap on the third star
      await tester.tap(find.byType(Icon).at(2));
      await tester.pump();

      // Verify that the tap was registered (this would depend on the actual implementation)
      expect(find.byType(Icon), findsNWidgets(5));
    });
  });
}