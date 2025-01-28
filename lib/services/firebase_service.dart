import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/church.dart';
import '../models/announcement.dart';
import '../models/event.dart';
import '../models/notification_history.dart';
import '../models/team_message.dart';
import '../models/team_event.dart';
import 'dart:math';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get_it/get_it.dart';
import '../services/cache_service.dart';

/// Service for handling all Firebase-related operations.
class FirebaseService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final _performanceService = PerformanceService();
  final _analytics = AnalyticsService();
  final _cacheService = GetIt.I<CacheService>();
  
  FirebaseService() : 
    _firestore = FirebaseFirestore.instance,
    _storage = FirebaseStorage.instance {
    _initializeOfflineSupport();
  }

  Future<void> _initializeOfflineSupport() async {
    await _firestore.enablePersistence(
      const PersistenceSettings(synchronizeTabs: true),
    );
    await _firestore.enableNetwork();
  }

  // Add error handling wrapper
  Future<T> handleFirebaseOperation<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FirebaseException catch (e) {
      throw FirebaseOperationException(
        message: e.message ?? 'Firebase operation failed',
        code: e.code,
      );
    } catch (e) {
      throw FirebaseOperationException(
        message: 'An unexpected error occurred',
        code: 'unknown',
      );
    }
  }

  // Get all churches
  Stream<List<Church>> getChurches() {
    return _firestore.collection('churches').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Church.fromMap(data);
      }).toList();
    });
  }

  // Add a new church
  Future<void> addChurch(Church church) async {
    await _firestore.collection('churches').add(church.toMap());
  }

  // Get church by ID
  Future<Church?> getChurchById(String id) async {
    final doc = await _firestore.collection('churches').doc(id).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return Church.fromMap(data);
    }
    return null;
  }

  // Verify admin PIN
  Future<bool> verifyAdminPin(String churchId, String pin) async {
    final church = await getChurchById(churchId);
    return church?.adminPin == pin;
  }

  // Announcements
  Stream<List<Announcement>> getAnnouncements(String churchId) {
    return _firestore
        .collection('churches')
        .doc(churchId)
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Announcement.fromMap(data);
          }).toList();
        });
  }

  Future<void> addAnnouncement(Announcement announcement) async {
    await _firestore
        .collection('churches')
        .doc(announcement.churchId)
        .collection('announcements')
        .add(announcement.toMap());
  }

  Future<void> updateAnnouncement(Announcement announcement) async {
    await _firestore
        .collection('churches')
        .doc(announcement.churchId)
        .collection('announcements')
        .doc(announcement.id)
        .update(announcement.toMap());
  }

  Future<void> deleteAnnouncement(String churchId, String announcementId) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('announcements')
        .doc(announcementId)
        .delete();
  }

  // Events
  Stream<List<Event>> getEvents(String churchId) {
    return _firestore
        .collection('churches')
        .doc(churchId)
        .collection('events')
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Event.fromMap(data);
          }).toList();
        });
  }

  Future<void> addEvent(Event event) async {
    await _firestore
        .collection('churches')
        .doc(event.churchId)
        .collection('events')
        .add(event.toMap());
  }

  Future<void> updateEvent(Event event) async {
    await _firestore
        .collection('churches')
        .doc(event.churchId)
        .collection('events')
        .doc(event.id)
        .update(event.toMap());
  }

  Future<void> deleteEvent(String churchId, String eventId) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('events')
        .doc(eventId)
        .delete();
  }

  Future<void> regenerateAdminPin(String churchId) async {
    // Generate a random 6-digit PIN
    final random = Random();
    final pin = List.generate(6, (_) => random.nextInt(10)).join();

    await _firestore
        .collection('churches')
        .doc(churchId)
        .update({'adminPin': pin});
  }

  // Get notification settings for a church
  Future<Map<String, dynamic>> getNotificationSettings(String churchId) async {
    final doc = await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('settings')
        .doc('notifications')
        .get();

    return doc.exists ? doc.data()! : {};
  }

  // Update notification settings for a church
  Future<void> updateNotificationSettings(
    String churchId,
    Map<String, dynamic> settings,
  ) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('settings')
        .doc('notifications')
        .set(settings, SetOptions(merge: true));
  }

  // Get notification history for a church
  Stream<List<NotificationHistory>> getNotificationHistory(String churchId) {
    return _firestore
        .collection('churches')
        .doc(churchId)
        .collection('notification_history')
        .orderBy('timestamp', descending: true)
        .limit(100) // Limit to last 100 notifications
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return NotificationHistory.fromMap(data);
          }).toList();
        });
  }

  // Add notification to history
  Future<void> addNotificationToHistory(NotificationHistory notification) async {
    await _firestore
        .collection('churches')
        .doc(notification.churchId)
        .collection('notification_history')
        .add(notification.toMap());
  }

  // Delete notification history older than 30 days
  Future<void> cleanupNotificationHistory(String churchId) async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    final snapshot = await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('notification_history')
        .where('timestamp', isLessThan: thirtyDaysAgo.toIso8601String())
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  // Prayer Requests
  Stream<List<PrayerRequest>> getPrayerRequests(String churchId) {
    return _firestore
        .collection('churches')
        .doc(churchId)
        .collection('prayer_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return PrayerRequest.fromMap(data);
          }).toList();
        });
  }

  Future<void> addPrayerRequest(PrayerRequest request) async {
    await _firestore
        .collection('churches')
        .doc(request.churchId)
        .collection('prayer_requests')
        .add(request.toMap());
  }

  Future<void> updatePrayerRequest(PrayerRequest request) async {
    await _firestore
        .collection('churches')
        .doc(request.churchId)
        .collection('prayer_requests')
        .doc(request.id)
        .update({
          ...request.toMap(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
  }

  Future<void> deletePrayerRequest(String churchId, String requestId) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('prayer_requests')
        .doc(requestId)
        .delete();
  }

  Future<void> markPrayerRequestAsAnswered(
    String churchId,
    String requestId,
    bool isAnswered,
  ) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('prayer_requests')
        .doc(requestId)
        .update({
          'isAnswered': isAnswered,
          'updatedAt': DateTime.now().toIso8601String(),
        });
  }

  // Bible Study Groups
  Stream<List<BibleStudyGroup>> getBibleStudyGroups(String churchId) {
    return _firestore
        .collection('churches')
        .doc(churchId)
        .collection('bible_study_groups')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return BibleStudyGroup.fromMap(data);
          }).toList();
        });
  }

  Future<void> addBibleStudyGroup(BibleStudyGroup group) async {
    await _firestore
        .collection('churches')
        .doc(group.churchId)
        .collection('bible_study_groups')
        .add(group.toMap());
  }

  Future<void> updateBibleStudyGroup(BibleStudyGroup group) async {
    await _firestore
        .collection('churches')
        .doc(group.churchId)
        .collection('bible_study_groups')
        .doc(group.id)
        .update({
          ...group.toMap(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
  }

  Future<void> deleteBibleStudyGroup(String churchId, String groupId) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('bible_study_groups')
        .doc(groupId)
        .delete();
  }

  Future<void> toggleBibleStudyGroupStatus(
    String churchId,
    String groupId,
    bool isActive,
  ) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('bible_study_groups')
        .doc(groupId)
        .update({
          'isActive': isActive,
          'updatedAt': DateTime.now().toIso8601String(),
        });
  }

  // Ministry Teams
  Stream<List<MinistryTeam>> getMinistryTeams(String churchId) {
    return _firestore
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return MinistryTeam.fromMap(data);
          }).toList();
        });
  }

  Future<void> addMinistryTeam(MinistryTeam team) async {
    await _firestore
        .collection('churches')
        .doc(team.churchId)
        .collection('ministry_teams')
        .add(team.toMap());
  }

  Future<void> updateMinistryTeam(MinistryTeam team) async {
    await _firestore
        .collection('churches')
        .doc(team.churchId)
        .collection('ministry_teams')
        .doc(team.id)
        .update({
          ...team.toMap(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
  }

  Future<void> deleteMinistryTeam(String churchId, String teamId) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .doc(teamId)
        .delete();
  }

  Future<void> toggleMinistryTeamStatus(
    String churchId,
    String teamId,
    bool isActive,
  ) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .doc(teamId)
        .update({
          'isActive': isActive,
          'updatedAt': DateTime.now().toIso8601String(),
        });
  }

  // Team Members
  Stream<List<TeamMember>> getTeamMembers(String churchId, String teamId) {
    return _firestore
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .doc(teamId)
        .collection('members')
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return TeamMember.fromMap(data);
          }).toList();
        });
  }

  Future<void> joinTeam(String churchId, String teamId, String role) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final member = TeamMember(
      id: '',
      teamId: teamId,
      userId: currentUser.uid,
      userName: currentUser.displayName ?? 'Anonymous',
      role: role,
      joinedAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    
    // Add member to team
    final memberRef = _firestore
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .doc(teamId)
        .collection('members')
        .doc(currentUser.uid);
    
    batch.set(memberRef, member.toMap());

    // Update team member count
    final teamRef = _firestore
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .doc(teamId);

    batch.update(teamRef, {
      'memberCount': FieldValue.increment(1),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await batch.commit();
  }

  Future<void> leaveTeam(String churchId, String teamId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final batch = _firestore.batch();
    
    // Remove member from team
    final memberRef = _firestore
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .doc(teamId)
        .collection('members')
        .doc(currentUser.uid);
    
    batch.delete(memberRef);

    // Update team member count
    final teamRef = _firestore
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .doc(teamId);

    batch.update(teamRef, {
      'memberCount': FieldValue.increment(-1),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await batch.commit();
  }

  Future<bool> isTeamMember(String churchId, String teamId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return false;

    final doc = await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .doc(teamId)
        .collection('members')
        .doc(currentUser.uid)
        .get();

    return doc.exists;
  }

  Future<void> updateTeamMemberRole(
    String churchId,
    String teamId,
    String memberId,
    String newRole,
  ) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .doc(teamId)
        .collection('members')
        .doc(memberId)
        .update({
          'role': newRole,
          'updatedAt': DateTime.now().toIso8601String(),
        });
  }

  Future<void> removeTeamMember(
    String churchId,
    String teamId,
    String memberId,
  ) async {
    final batch = _firestore.batch();
    
    // Remove member
    final memberRef = _firestore
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .doc(teamId)
        .collection('members')
        .doc(memberId);
    
    batch.delete(memberRef);

    // Update team member count
    final teamRef = _firestore
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .doc(teamId);

    batch.update(teamRef, {
      'memberCount': FieldValue.increment(-1),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await batch.commit();
  }

  Stream<List<TeamMessage>> getTeamMessages(String churchId, String teamId) {
    return _firestore
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .doc(teamId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return TeamMessage.fromMap(data);
          }).toList();
        });
  }

  Future<void> sendTeamMessage(
    String churchId,
    String teamId,
    String content,
    {bool isAnnouncement = false}
  ) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final message = TeamMessage(
      id: '',
      teamId: teamId,
      senderId: currentUser.uid,
      senderName: currentUser.displayName ?? 'Anonymous',
      content: content,
      timestamp: DateTime.now(),
      isAnnouncement: isAnnouncement,
    );

    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .doc(teamId)
        .collection('messages')
        .add(message.toMap());
  }

  Future<void> deleteTeamMessage(
    String churchId,
    String teamId,
    String messageId,
  ) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .doc(teamId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Future<void> editTeamMessage(
    String churchId,
    String teamId,
    String messageId,
    String newContent,
  ) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .doc(teamId)
        .collection('messages')
        .doc(messageId)
        .update({
          'content': newContent,
          'isEdited': true,
          'updatedAt': DateTime.now().toIso8601String(),
        });
  }

  Future<String> uploadTeamMessageAttachment(
    String churchId,
    String teamId,
    String fileName,
    Uint8List fileData,
  ) async {
    final ref = _storage
        .ref()
        .child('churches')
        .child(churchId)
        .child('ministry_teams')
        .child(teamId)
        .child('attachments')
        .child(fileName);

    await ref.putData(fileData);
    return await ref.getDownloadURL();
  }

  /// Returns a stream of team events for a specific team.
  /// 
  /// Parameters:
  /// - [churchId]: The ID of the church
  /// - [teamId]: The ID of the team
  /// - [startAfter]: Optional DateTime to start after (for pagination)
  /// - [limit]: Maximum number of events to return (default: 20)
  /// 
  /// Returns a [Stream] of [List<TeamEvent>].
  Stream<List<TeamEvent>> getTeamEvents(
    String churchId,
    String teamId, {
    DateTime? startAfter,
    int limit = 20,
  }) {
    // Try to get cached data first
    final cacheKey = 'team_events_${teamId}_${startAfter?.toIso8601String() ?? "latest"}';
    final cachedEvents = _cacheService.getCachedData<List<TeamEvent>>(
      cacheKey,
      (json) => (json['events'] as List)
          .map((e) => TeamEvent.fromMap(e))
          .toList(),
    );

    var query = _firestore
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .doc(teamId)
        .collection('events')
        .orderBy('startTime')
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfter([startAfter.toIso8601String()]);
    }

    return query.snapshots().map((snapshot) {
      final events = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TeamEvent.fromMap(data);
      }).toList();

      // Cache the new data
      _cacheService.cacheData(cacheKey, {'events': events.map((e) => e.toMap()).toList()});

      return events;
    });
  }

  /// Creates a new team event in Firestore.
  /// 
  /// Parameters:
  /// - [event]: The [TeamEvent] object containing event details
  /// 
  /// Throws [FirebaseOperationException] if the operation fails.
  Future<void> addTeamEvent(TeamEvent event) async {
    return _performanceService.trackOperation(
      name: 'add_team_event',
      attributes: {
        'team_id': event.teamId,
        'church_id': event.churchId,
      },
      operation: () async {
        await handleFirebaseOperation(() async {
          await _firestore
              .collection('churches')
              .doc(event.churchId)
              .collection('ministry_teams')
              .doc(event.teamId)
              .collection('events')
              .add(event.toMap());

          await _analytics.logTeamEvent(
            action: 'create_event',
            teamId: event.teamId,
            teamName: event.title,
            eventName: event.title,
          );
        });
      },
    );
  }

  Future<void> updateTeamEvent(TeamEvent event) async {
    await _firestore
        .collection('churches')
        .doc(event.churchId)
        .collection('ministry_teams')
        .doc(event.teamId)
        .collection('events')
        .doc(event.id)
        .update(event.toMap());
  }

  Future<void> deleteTeamEvent(
    String churchId,
    String teamId,
    String eventId,
  ) async {
    await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .doc(teamId)
        .collection('events')
        .doc(eventId)
        .delete();
  }

  Future<void> toggleTeamEventAttendance(
    String churchId,
    String teamId,
    String eventId,
  ) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final doc = await _firestore
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .doc(teamId)
        .collection('events')
        .doc(eventId)
        .get();

    final attendees = List<String>.from(doc.data()?['attendees'] ?? []);
    
    if (attendees.contains(currentUser.uid)) {
      attendees.remove(currentUser.uid);
    } else {
      attendees.add(currentUser.uid);
    }

    await doc.reference.update({'attendees': attendees});
  }

  Future<void> batchUpdateTeamEvents(
    List<TeamEvent> events,
    String churchId,
    String teamId,
  ) async {
    final batch = _firestore.batch();
    
    for (final event in events) {
      final docRef = _firestore
          .collection('churches')
          .doc(churchId)
          .collection('ministry_teams')
          .doc(teamId)
          .collection('events')
          .doc(event.id);
          
      batch.update(docRef, event.toMap());
    }

    await batch.commit();
  }
}

class FirebaseOperationException implements Exception {
  final String message;
  final String code;

  FirebaseOperationException({
    required this.message,
    required this.code,
  });

  @override
  String toString() => 'FirebaseOperationException: $message (code: $code)';
} 