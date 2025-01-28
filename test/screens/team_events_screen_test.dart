import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:your_app/screens/team_events_screen.dart';

class MockFirebaseService extends Mock implements FirebaseService {}
class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockFirebaseService mockFirebaseService;
  late MockAuthService mockAuthService;

  setUp(() {
    mockFirebaseService = MockFirebaseService();
    mockAuthService = MockAuthService();
  });

  testWidgets('shows loading indicator when loading events',
      (WidgetTester tester) async {
    when(mockFirebaseService.getTeamEvents(any, any))
        .thenAnswer((_) => Stream.empty());

    await tester.pumpWidget(MaterialApp(
      home: TeamEventsScreen(
        team: MinistryTeam(/* ... */),
        isAdmin: false,
      ),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  // Add more widget tests...
} 