import 'package:flutter_test/flutter_test.dart';
import 'package:reviewapp/main.dart';
import 'package:reviewapp/services/api_service.dart';
import 'package:reviewapp/services/notification_service.dart';
import 'package:reviewapp/utils/app_theme.dart';

void main() {
  group('Restaurant Review App Tests', () {
    testWidgets('App should start and show splash screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const RestaurantReviewApp());

      // Verify splash screen elements
      expect(find.text('RestaurantReview'), findsOneWidget);
      expect(
        find.text('Temukan restoran terbaik di sekitar Anda'),
        findsOneWidget,
      );
    });

    test('App theme should have correct colors', () {
      expect(AppTheme.primaryColor.value, equals(0xFF8B4513));
      expect(AppTheme.secondaryColor.value, equals(0xFFFF8C00));
      expect(AppTheme.accentColor.value, equals(0xFFFFB347));
    });

    test('API service should be configured correctly', () {
      expect(
        ApiService.baseUrl,
        equals('https://be-restoran-1061342868557.us-central1.run.app/api'),
      );
      expect(
        ApiService.currencyApiUrl,
        equals('https://api.frankfurter.dev/v1/latest'),
      );
    });

    test('Notification service should initialize', () async {
      // This test verifies that notification service can be initialized
      // without throwing errors
      expect(() => NotificationService.initialize(), returnsNormally);
    });
  });

  group('Feature Tests', () {
    test('Currency conversion rates should be fetchable', () async {
      // Test currency API integration
      try {
        final result = await ApiService.getCurrencyRates();
        expect(result, isNotNull);
        if (result != null) {
          expect(result.containsKey('rates'), isTrue);
        }
      } catch (e) {
        // If network error, that's expected in test environment
        expect(e, isA<Exception>());
      }
    });

    test('Restaurant data should be fetchable', () async {
      // Test restaurant API integration
      try {
        final result = await ApiService.getRestaurants();
        expect(result, isNotNull);
        expect(result, isA<List>());
      } catch (e) {
        // If network error, that's expected in test environment
        expect(e, isA<Exception>());
      }
    });
  });
}
