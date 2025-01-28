import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  Future<void> logTeamEvent({
    required String action,
    required String teamId,
    required String teamName,
    String? eventId,
    String? eventName,
  }) async {
    await logEvent(
      name: 'team_event',
      parameters: {
        'action': action,
        'team_id': teamId,
        'team_name': teamName,
        if (eventId != null) 'event_id': eventId,
        if (eventName != null) 'event_name': eventName,
      },
    );
  }

  Future<void> setUserProperties({
    required String userId,
    required String churchId,
    List<String>? teamIds,
  }) async {
    await _analytics.setUserId(id: userId);
    await _analytics.setUserProperty(name: 'church_id', value: churchId);
    if (teamIds != null) {
      await _analytics.setUserProperty(
        name: 'team_ids',
        value: teamIds.join(','),
      );
    }
  }

  Future<void> logTeamMemberAction({
    required String action,
    required String teamId,
    required String teamName,
    required String memberId,
    required String memberName,
    String? role,
  }) async {
    await logEvent(
      name: 'team_member_action',
      parameters: {
        'action': action,
        'team_id': teamId,
        'team_name': teamName,
        'member_id': memberId,
        'member_name': memberName,
        if (role != null) 'role': role,
      },
    );
  }

  Future<void> logTeamChatAction({
    required String action,
    required String teamId,
    required String teamName,
    String? messageId,
    bool isAnnouncement = false,
  }) async {
    await logEvent(
      name: 'team_chat_action',
      parameters: {
        'action': action,
        'team_id': teamId,
        'team_name': teamName,
        if (messageId != null) 'message_id': messageId,
        'is_announcement': isAnnouncement,
      },
    );
  }
} 