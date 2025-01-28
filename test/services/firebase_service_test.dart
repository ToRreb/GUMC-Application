import 'package:flutter_test/flutter_test.dart';
import 'package:gumc_application/models/team_event.dart';
import 'package:gumc_application/services/firebase_service.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:your_app/services/firebase_service.dart';
import 'package:your_app/models/team_event.dart';

class MockPerformanceService extends Mock implements PerformanceService {}
class MockAnalyticsService extends Mock implements AnalyticsService {}
class MockCacheService extends Mock implements CacheService {}

void main() {
  late FirebaseService firebaseService;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseStorage mockStorage;
  late MockPerformanceService mockPerformance;
  late MockAnalyticsService mockAnalytics;
  late MockCacheService mockCache;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockStorage = MockFirebaseStorage();
    mockPerformance = MockPerformanceService();
    mockAnalytics = MockAnalyticsService();
    mockCache = MockCacheService();

    firebaseService = FirebaseService.withDependencies(
      firestore: fakeFirestore,
      storage: mockStorage,
      performance: mockPerformance,
      analytics: mockAnalytics,
      cache: mockCache,
    );
  });

  group('Team Events', () {
    test('addTeamEvent should add event to Firestore', () async {
      final event = TeamEvent(
        id: '1',
        teamId: 'team1',
        churchId: 'church1',
        title: 'Test Event',
        description: 'Test Description',
        startTime: DateTime.now(),
        location: 'Test Location',
        creatorId: 'user1',
        creatorName: 'Test User',
        createdAt: DateTime.now(),
      );

      await firebaseService.addTeamEvent(event);

      final snapshot = await fakeFirestore
          .collection('churches')
          .doc('church1')
          .collection('ministry_teams')
          .doc('team1')
          .collection('events')
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['title'], 'Test Event');
    });

    test('getTeamEvents should return stream of events', () async {
      final event = TeamEvent(
        id: '1',
        teamId: 'team1',
        churchId: 'church1',
        title: 'Test Event',
        description: 'Test Description',
        startTime: DateTime.now(),
        location: 'Test Location',
        creatorId: 'user1',
        creatorName: 'Test User',
        createdAt: DateTime.now(),
      );
      
      await fakeFirestore
          .collection('churches')
          .doc('church1')
          .collection('ministry_teams')
          .doc('team1')
          .collection('events')
          .add(event.toMap()); // Ensure `toMap` converts the event to Firestore-friendly format.

      final events = await firebaseService
          .getTeamEvents('church1', 'team1')
          .first;

      expect(events.length, 1);
      expect(events.first.title, 'Test Event');
    });

    // Add more tests...
  });
}
