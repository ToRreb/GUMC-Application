import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:your_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('tap on team event, verify event details',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to team events
      await tester.tap(find.byIcon(Icons.event));
      await tester.pumpAndSettle();

      // Verify events screen
      expect(find.text('Team Events'), findsOneWidget);

      // Add more integration tests...
    });
  });
} 