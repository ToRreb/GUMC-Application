import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

interface Announcement {
  title: string;
  content: string;
  churchId: string;
}

interface Event {
  title: string;
  description: string;
  churchId: string;
  startTime: string;
  location: string;
}

interface NotificationSettings {
  enableReminders: boolean;
  reminderIntervals: number[]; // Hours before event
  batchNotifications: boolean;
  batchInterval: number; // Minutes
  quietHoursStart?: number; // Hour of day (0-23)
  quietHoursEnd?: number;
}

interface BatchedNotification {
  churchId: string;
  notifications: {
    title: string;
    body: string;
    type: 'announcement' | 'event' | 'reminder';
  }[];
  timestamp: Date;
}

// Send notification when a new announcement is created
exports.onAnnouncementCreated = functions.firestore
  .document('churches/{churchId}/announcements/{announcementId}')
  .onCreate(async (snap, context) => {
    const announcement = snap.data() as Announcement;
    const { churchId } = context.params;

    await queueNotification(
      churchId,
      announcement.title,
      announcement.content,
      'announcement'
    );
  });

// Send notification when a new event is created
exports.onEventCreated = functions.firestore
  .document('churches/{churchId}/events/{eventId}')
  .onCreate(async (snap, context) => {
    const event = snap.data() as Event;
    const { churchId } = context.params;

    const message = {
      notification: {
        title: `New Event: ${event.title}`,
        body: `${event.description}\nWhen: ${event.startTime}\nWhere: ${event.location}`,
      },
      topic: `church_${churchId}`,
      android: {
        notification: {
          channelId: 'church_app_channel',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    };

    try {
      await admin.messaging().send(message);
      console.log('Event notification sent successfully');
    } catch (error) {
      console.error('Error sending event notification:', error);
    }
  });

// Send notification when an event is updated
exports.onEventUpdated = functions.firestore
  .document('churches/{churchId}/events/{eventId}')
  .onUpdate(async (change, context) => {
    const newEvent = change.after.data() as Event;
    const { churchId } = context.params;

    const message = {
      notification: {
        title: `Event Updated: ${newEvent.title}`,
        body: `${newEvent.description}\nWhen: ${newEvent.startTime}\nWhere: ${newEvent.location}`,
      },
      topic: `church_${churchId}`,
      android: {
        notification: {
          channelId: 'church_app_channel',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    };

    try {
      await admin.messaging().send(message);
      console.log('Event update notification sent successfully');
    } catch (error) {
      console.error('Error sending event update notification:', error);
    }
  });

// Send notification when an announcement is updated
exports.onAnnouncementUpdated = functions.firestore
  .document('churches/{churchId}/announcements/{announcementId}')
  .onUpdate(async (change, context) => {
    const newAnnouncement = change.after.data() as Announcement;
    const { churchId } = context.params;

    const message = {
      notification: {
        title: `Announcement Updated: ${newAnnouncement.title}`,
        body: newAnnouncement.content,
      },
      topic: `church_${churchId}`,
      android: {
        notification: {
          channelId: 'church_app_channel',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    };

    try {
      await admin.messaging().send(message);
      console.log('Announcement update notification sent successfully');
    } catch (error) {
      console.error('Error sending announcement update notification:', error);
    }
  });

// Send reminders for upcoming events (runs every hour)
exports.sendEventReminders = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const oneHourFromNow = new admin.firestore.Timestamp(
      now.seconds + 3600,
      now.nanoseconds
    );
    const oneDayFromNow = new admin.firestore.Timestamp(
      now.seconds + 86400,
      now.nanoseconds
    );

    try {
      // Get all churches
      const churchesSnapshot = await admin.firestore().collection('churches').get();

      for (const churchDoc of churchesSnapshot.docs) {
        const churchId = churchDoc.id;

        // Get upcoming events
        const eventsSnapshot = await churchDoc
          .ref
          .collection('events')
          .where('startTime', '>', now.toDate())
          .where('startTime', '<=', oneDayFromNow.toDate())
          .get();

        for (const eventDoc of eventsSnapshot.docs) {
          const event = eventDoc.data() as Event;
          const eventTime = new Date(event.startTime);
          const timeDiff = eventTime.getTime() - now.toDate().getTime();
          const hoursUntilEvent = Math.floor(timeDiff / (1000 * 60 * 60));

          // Send 1-hour reminder
          if (eventTime > now.toDate() && eventTime <= oneHourFromNow.toDate()) {
            await sendEventReminder(event, churchId, '1 hour');
          }
          // Send 24-hour reminder
          else if (hoursUntilEvent === 24) {
            await sendEventReminder(event, churchId, '24 hours');
          }
        }
      }

      console.log('Event reminders check completed');
    } catch (error) {
      console.error('Error sending event reminders:', error);
    }
  });

async function sendEventReminder(event: Event, churchId: string, timeUntil: string) {
  const message = {
    notification: {
      title: `Upcoming Event Reminder: ${event.title}`,
      body: `This event starts in ${timeUntil}.\n${event.description}\nWhere: ${event.location}`,
    },
    topic: `church_${churchId}`,
    android: {
      notification: {
        channelId: 'church_app_channel',
        priority: 'high',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
        },
      },
    },
  };

  try {
    await admin.messaging().send(message);
    console.log(`${timeUntil} reminder sent for event: ${event.title}`);
  } catch (error) {
    console.error(`Error sending ${timeUntil} reminder:`, error);
  }
}

// Cleanup past events (runs daily at midnight)
exports.cleanupPastEvents = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const thirtyDaysAgo = new admin.firestore.Timestamp(
      now.seconds - (30 * 24 * 60 * 60),
      now.nanoseconds
    );

    try {
      const churchesSnapshot = await admin.firestore().collection('churches').get();

      for (const churchDoc of churchesSnapshot.docs) {
        const batch = admin.firestore().batch();
        let count = 0;

        const pastEventsSnapshot = await churchDoc
          .ref
          .collection('events')
          .where('startTime', '<', thirtyDaysAgo.toDate())
          .get();

        pastEventsSnapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
          count++;
        });

        if (count > 0) {
          await batch.commit();
          console.log(`Deleted ${count} past events from church ${churchDoc.id}`);
        }
      }

      console.log('Past events cleanup completed');
    } catch (error) {
      console.error('Error cleaning up past events:', error);
    }
  });

function isInQuietHours(settings: NotificationSettings): boolean {
  if (!settings.quietHoursStart || !settings.quietHoursEnd) return false;

  const now = new Date();
  const hour = now.getHours();
  
  if (settings.quietHoursStart < settings.quietHoursEnd) {
    return hour >= settings.quietHoursStart && hour < settings.quietHoursEnd;
  } else {
    // Handle case where quiet hours span midnight
    return hour >= settings.quietHoursStart || hour < settings.quietHoursEnd;
  }
}

async function getChurchNotificationSettings(churchId: string): Promise<NotificationSettings> {
  const doc = await admin.firestore()
    .collection('churches')
    .doc(churchId)
    .collection('settings')
    .doc('notifications')
    .get();

  // Default settings if none exist
  const defaultSettings: NotificationSettings = {
    enableReminders: true,
    reminderIntervals: [1, 24], // 1 hour and 24 hours before
    batchNotifications: false,
    batchInterval: 15, // 15 minutes
  };

  return doc.exists ? { ...defaultSettings, ...doc.data() } : defaultSettings;
}

// Batch notifications collection
const batchedNotifications = new Map<string, BatchedNotification>();

async function queueNotification(
  churchId: string,
  title: string,
  body: string,
  type: 'announcement' | 'event' | 'reminder'
) {
  const settings = await getChurchNotificationSettings(churchId);
  
  if (isInQuietHours(settings)) {
    console.log(`Skipping notification during quiet hours for church ${churchId}`);
    return;
  }

  if (!settings.batchNotifications) {
    // Send immediately if batching is disabled
    await sendNotification(churchId, title, body);
    return;
  }

  const existing = batchedNotifications.get(churchId);
  const notification = {
    title,
    body,
    type,
  };

  if (existing) {
    existing.notifications.push(notification);
  } else {
    batchedNotifications.set(churchId, {
      churchId,
      notifications: [notification],
      timestamp: new Date(),
    });

    // Schedule processing after batch interval
    setTimeout(
      () => processBatchedNotifications(churchId),
      settings.batchInterval * 60 * 1000
    );
  }
}

async function processBatchedNotifications(churchId: string) {
  const batch = batchedNotifications.get(churchId);
  if (!batch || batch.notifications.length === 0) return;

  batchedNotifications.delete(churchId);

  if (batch.notifications.length === 1) {
    const notification = batch.notifications[0];
    await sendNotification(churchId, notification.title, notification.body);
    return;
  }

  // Group notifications by type
  const grouped = batch.notifications.reduce((acc, notification) => {
    if (!acc[notification.type]) {
      acc[notification.type] = [];
    }
    acc[notification.type].push(notification);
    return acc;
  }, {} as Record<string, typeof batch.notifications>);

  // Create summary message
  let title = 'New Updates';
  let body = Object.entries(grouped)
    .map(([type, notifications]) => {
      const count = notifications.length;
      switch (type) {
        case 'announcement':
          return `${count} new announcement${count > 1 ? 's' : ''}`;
        case 'event':
          return `${count} event update${count > 1 ? 's' : ''}`;
        case 'reminder':
          return `${count} event reminder${count > 1 ? 's' : ''}`;
        default:
          return '';
      }
    })
    .filter(Boolean)
    .join('\n');

  await sendNotification(churchId, title, body);
}

async function sendNotification(churchId: string, title: string, body: string, type: string) {
  const message = {
    notification: { title, body },
    topic: `church_${churchId}`,
    android: {
      notification: {
        channelId: 'church_app_channel',
        priority: 'high',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
        },
      },
    },
  };

  try {
    await admin.messaging().send(message);
    await logNotification(churchId, title, body, type);
    console.log('Notification sent successfully:', title);
  } catch (error) {
    console.error('Error sending notification:', error);
  }
}

exports.onNotificationSettingsUpdated = functions.firestore
  .document('churches/{churchId}/settings/notifications')
  .onWrite(async (change, context) => {
    const { churchId } = context.params;
    const newSettings = change.after.exists ? change.after.data() as NotificationSettings : null;
    const oldSettings = change.before.exists ? change.before.data() as NotificationSettings : null;

    if (!newSettings) {
      console.log(`Notification settings deleted for church ${churchId}`);
      return;
    }

    if (!oldSettings || oldSettings.batchInterval !== newSettings.batchInterval) {
      // Clear any pending batched notifications if batch interval changed
      batchedNotifications.delete(churchId);
    }

    console.log(`Notification settings updated for church ${churchId}:`, newSettings);
  });

async function logNotification(
  churchId: string,
  title: string,
  body: string,
  type: string,
  isBatched = false,
  batchSize?: number
) {
  await admin.firestore()
    .collection('churches')
    .doc(churchId)
    .collection('notification_history')
    .add({
      churchId,
      title,
      body,
      type,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      isBatched,
      batchSize,
    });
}

// Add this new function to clean up old notifications
exports.cleanupOldNotifications = functions.pubsub
  .schedule('0 0 * * *')  // Run daily at midnight
  .timeZone('UTC')
  .onRun(async (context) => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    try {
      const churchesSnapshot = await admin.firestore().collection('churches').get();

      for (const churchDoc of churchesSnapshot.docs) {
        const batch = admin.firestore().batch();
        let count = 0;

        const oldNotificationsSnapshot = await churchDoc
          .ref
          .collection('notification_history')
          .where('timestamp', '<', thirtyDaysAgo)
          .get();

        oldNotificationsSnapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
          count++;
        });

        if (count > 0) {
          await batch.commit();
          console.log(`Deleted ${count} old notifications from church ${churchDoc.id}`);
        }
      }

      console.log('Old notifications cleanup completed');
    } catch (error) {
      console.error('Error cleaning up old notifications:', error);
    }
  });

// Add these handlers for prayer request notifications
exports.onPrayerRequestCreated = functions.firestore
  .document('churches/{churchId}/prayer_requests/{requestId}')
  .onCreate(async (snap, context) => {
    const request = snap.data();
    const { churchId } = context.params;

    await queueNotification(
      churchId,
      'New Prayer Request',
      `${request.authorName} has submitted a prayer request: ${request.title}`,
      'prayer_request'
    );
  });

exports.onPrayerRequestAnswered = functions.firestore
  .document('churches/{churchId}/prayer_requests/{requestId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    const { churchId } = context.params;

    if (newData.isAnswered && !oldData.isAnswered) {
      await queueNotification(
        churchId,
        'Prayer Request Answered',
        `A prayer request has been marked as answered: ${newData.title}`,
        'prayer_request'
      );
    }
  });

// Add these handlers for Bible Study Group notifications
exports.onBibleStudyGroupCreated = functions.firestore
  .document('churches/{churchId}/bible_study_groups/{groupId}')
  .onCreate(async (snap, context) => {
    const group = snap.data();
    const { churchId } = context.params;

    await queueNotification(
      churchId,
      'New Bible Study Group',
      `A new Bible study group has been created: ${group.name}\nMeets: ${group.meetingTime} at ${group.location}`,
      'bible_study'
    );
  });

exports.onBibleStudyGroupUpdated = functions.firestore
  .document('churches/{churchId}/bible_study_groups/{groupId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    const { churchId } = context.params;

    // Only send notification if active status changes or meeting details change
    if (newData.isActive !== oldData.isActive ||
        newData.meetingTime !== oldData.meetingTime ||
        newData.location !== oldData.location) {
      
      let message = `Bible study group "${newData.name}" has been updated.`;
      if (newData.isActive !== oldData.isActive) {
        message = `Bible study group "${newData.name}" has been ${newData.isActive ? 'activated' : 'deactivated'}.`;
      }

      await queueNotification(
        churchId,
        'Bible Study Group Updated',
        message,
        'bible_study'
      );
    }
  });

exports.onBibleStudyGroupDeleted = functions.firestore
  .document('churches/{churchId}/bible_study_groups/{groupId}')
  .onDelete(async (snap, context) => {
    const group = snap.data();
    const { churchId } = context.params;

    await queueNotification(
      churchId,
      'Bible Study Group Removed',
      `The Bible study group "${group.name}" has been removed.`,
      'bible_study'
    );
  });

// Add these handlers for Ministry Team notifications
exports.onMinistryTeamCreated = functions.firestore
  .document('churches/{churchId}/ministry_teams/{teamId}')
  .onCreate(async (snap, context) => {
    const team = snap.data();
    const { churchId } = context.params;

    await queueNotification(
      churchId,
      'New Ministry Team',
      `A new ministry team has been created: ${team.name}\nLed by: ${team.leaderName}`,
      'ministry_team'
    );
  });

exports.onMinistryTeamUpdated = functions.firestore
  .document('churches/{churchId}/ministry_teams/{teamId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    const { churchId } = context.params;

    // Only send notification if active status changes or leadership changes
    if (newData.isActive !== oldData.isActive ||
        newData.leaderName !== oldData.leaderName) {
      
      let message = `Ministry team "${newData.name}" has been updated.`;
      if (newData.isActive !== oldData.isActive) {
        message = `Ministry team "${newData.name}" has been ${newData.isActive ? 'activated' : 'deactivated'}.`;
      } else if (newData.leaderName !== oldData.leaderName) {
        message = `${newData.leaderName} is now leading the "${newData.name}" ministry team.`;
      }

      await queueNotification(
        churchId,
        'Ministry Team Updated',
        message,
        'ministry_team'
      );
    }
  });

exports.onMinistryTeamDeleted = functions.firestore
  .document('churches/{churchId}/ministry_teams/{teamId}')
  .onDelete(async (snap, context) => {
    const team = snap.data();
    const { churchId } = context.params;

    await queueNotification(
      churchId,
      'Ministry Team Removed',
      `The ministry team "${team.name}" has been removed.`,
      'ministry_team'
    );
  });

// Add these handlers for team membership notifications

exports.onTeamMemberJoined = functions.firestore
  .document('churches/{churchId}/ministry_teams/{teamId}/members/{memberId}')
  .onCreate(async (snap, context) => {
    const member = snap.data();
    const { churchId, teamId } = context.params;

    // Get team details
    const teamDoc = await admin.firestore()
      .collection('churches')
      .doc(churchId)
      .collection('ministry_teams')
      .doc(teamId)
      .get();

    const team = teamDoc.data();
    if (!team) return;

    await queueNotification(
      churchId,
      'New Team Member',
      `${member.userName} has joined the "${team.name}" team as ${member.role}`,
      'ministry_team'
    );
  });

exports.onTeamMemberLeft = functions.firestore
  .document('churches/{churchId}/ministry_teams/{teamId}/members/{memberId}')
  .onDelete(async (snap, context) => {
    const member = snap.data();
    const { churchId, teamId } = context.params;

    // Get team details
    const teamDoc = await admin.firestore()
      .collection('churches')
      .doc(churchId)
      .collection('ministry_teams')
      .doc(teamId)
      .get();

    const team = teamDoc.data();
    if (!team) return;

    await queueNotification(
      churchId,
      'Team Member Left',
      `${member.userName} has left the "${team.name}" team`,
      'ministry_team'
    );
  });

exports.onTeamMemberRoleChanged = functions.firestore
  .document('churches/{churchId}/ministry_teams/{teamId}/members/{memberId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    const { churchId, teamId } = context.params;

    if (newData.role !== oldData.role) {
      // Get team details
      const teamDoc = await admin.firestore()
        .collection('churches')
        .doc(churchId)
        .collection('ministry_teams')
        .doc(teamId)
        .get();

      const team = teamDoc.data();
      if (!team) return;

      await queueNotification(
        churchId,
        'Team Role Updated',
        `${newData.userName}'s role in "${team.name}" has been updated to ${newData.role}`,
        'ministry_team'
      );
    }
  });

// Add these handlers for team event notifications

exports.onTeamEventCreated = functions.firestore
  .document('churches/{churchId}/ministry_teams/{teamId}/events/{eventId}')
  .onCreate(async (snap, context) => {
    const event = snap.data();
    const { churchId, teamId } = context.params;

    // Get team details
    const teamDoc = await admin.firestore()
      .collection('churches')
      .doc(churchId)
      .collection('ministry_teams')
      .doc(teamId)
      .get();

    const team = teamDoc.data();
    if (!team) return;

    await queueNotification(
      churchId,
      'New Team Event',
      `${team.name} has a new event: ${event.title}\nWhen: ${event.startTime}\nWhere: ${event.location}`,
      'team_event'
    );
  });

exports.onTeamEventUpdated = functions.firestore
  .document('churches/{churchId}/ministry_teams/{teamId}/events/{eventId}')
  .onUpdate(async (change, context) => {
    const newEvent = change.after.data();
    const oldEvent = change.before.data();
    const { churchId, teamId } = context.params;

    // Get team details
    const teamDoc = await admin.firestore()
      .collection('churches')
      .doc(churchId)
      .collection('ministry_teams')
      .doc(teamId)
      .get();

    const team = teamDoc.data();
    if (!team) return;

    // Only notify if important details change
    if (newEvent.startTime !== oldEvent.startTime ||
        newEvent.location !== oldEvent.location ||
        newEvent.title !== oldEvent.title) {
      await queueNotification(
        churchId,
        'Team Event Updated',
        `${team.name}'s event "${newEvent.title}" has been updated.\nNew time: ${newEvent.startTime}\nNew location: ${newEvent.location}`,
        'team_event'
      );
    }
  });

exports.onTeamEventDeleted = functions.firestore
  .document('churches/{churchId}/ministry_teams/{teamId}/events/{eventId}')
  .onDelete(async (snap, context) => {
    const event = snap.data();
    const { churchId, teamId } = context.params;

    // Get team details
    const teamDoc = await admin.firestore()
      .collection('churches')
      .doc(churchId)
      .collection('ministry_teams')
      .doc(teamId)
      .get();

    const team = teamDoc.data();
    if (!team) return;

    await queueNotification(
      churchId,
      'Team Event Cancelled',
      `${team.name}'s event "${event.title}" has been cancelled.`,
      'team_event'
    );
  });

exports.onTeamEventAttendanceChanged = functions.firestore
  .document('churches/{churchId}/ministry_teams/{teamId}/events/{eventId}')
  .onUpdate(async (change, context) => {
    const newEvent = change.after.data();
    const oldEvent = change.before.data();
    const { churchId, teamId } = context.params;

    // Only process if attendees list has changed
    if (JSON.stringify(newEvent.attendees) === JSON.stringify(oldEvent.attendees)) {
      return;
    }

    // Get team details
    const teamDoc = await admin.firestore()
      .collection('churches')
      .doc(churchId)
      .collection('ministry_teams')
      .doc(teamId)
      .get();

    const team = teamDoc.data();
    if (!team) return;

    // Find new attendees
    const newAttendees = newEvent.attendees.filter(
      (id: string) => !oldEvent.attendees.includes(id)
    );

    // Find removed attendees
    const removedAttendees = oldEvent.attendees.filter(
      (id: string) => !newEvent.attendees.includes(id)
    );

    // Get user details for notifications
    const getUserName = async (userId: string) => {
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(userId)
        .get();
      return userDoc.data()?.displayName || 'Someone';
    };

    // Notify about new attendees
    for (const userId of newAttendees) {
      const userName = await getUserName(userId);
      await queueNotification(
        churchId,
        'New Event Attendee',
        `${userName} is attending "${newEvent.title}" (${team.name})`,
        'team_event'
      );
    }

    // Notify about removed attendees
    for (const userId of removedAttendees) {
      const userName = await getUserName(userId);
      await queueNotification(
        churchId,
        'Event Attendance Update',
        `${userName} is no longer attending "${newEvent.title}" (${team.name})`,
        'team_event'
      );
    }
  });

// Add event reminder notifications
exports.sendEventReminders = functions.pubsub
  .schedule('every 15 minutes')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const in24Hours = new Date(now.toMillis() + 24 * 60 * 60 * 1000);
    const in1Hour = new Date(now.toMillis() + 60 * 60 * 1000);

    const churches = await admin.firestore().collection('churches').get();

    for (const church of churches.docs) {
      const churchId = church.id;
      const teams = await church.ref.collection('ministry_teams').get();

      for (const team of teams.docs) {
        const events = await team
          .ref
          .collection('events')
          .where('startTime', '>', now.toDate().toISOString())
          .where('startTime', '<=', in24Hours.toISOString())
          .get();

        for (const event of events.docs) {
          const eventData = event.data();
          const startTime = new Date(eventData.startTime);
          const hoursUntilEvent = (startTime.getTime() - now.toMillis()) / (1000 * 60 * 60);

          // Send 24-hour reminder
          if (hoursUntilEvent <= 24 && hoursUntilEvent > 23) {
            await queueNotification(
              churchId,
              'Event Reminder',
              `${team.data().name}'s event "${eventData.title}" is tomorrow at ${startTime.toLocaleTimeString()}`,
              'reminder'
            );
          }

          // Send 1-hour reminder
          if (hoursUntilEvent <= 1 && hoursUntilEvent > 0) {
            await queueNotification(
              churchId,
              'Event Starting Soon',
              `${team.data().name}'s event "${eventData.title}" starts in 1 hour at ${eventData.location}`,
              'reminder'
            );
          }
        }
      }
    }
  });

// Add these helper functions for recurring events
function generateEventInstances(
  parentEvent: any,
  startDate: Date,
  endDate: Date
): any[] {
  const instances: any[] = [];
  let currentDate = new Date(startDate);
  const eventEndDate = parentEvent.recurrenceEndDate 
    ? new Date(parentEvent.recurrenceEndDate)
    : endDate;

  while (currentDate <= eventEndDate) {
    if (shouldCreateInstance(parentEvent, currentDate)) {
      instances.push({
        ...parentEvent,
        id: '', // Will be assigned by Firestore
        parentEventId: parentEvent.id,
        startTime: new Date(currentDate).toISOString(),
        endTime: parentEvent.endTime 
          ? new Date(currentDate.getTime() + (new Date(parentEvent.endTime).getTime() - new Date(parentEvent.startTime).getTime())).toISOString()
          : null,
        isRecurringInstance: true,
      });
    }
    currentDate = getNextDate(parentEvent, currentDate);
  }

  return instances;
}

function shouldCreateInstance(event: any, date: Date): boolean {
  switch (event.recurrenceType) {
    case 'RecurrenceType.weekly':
      return event.weeklyDays?.includes(date.getDay()) ?? true;
    case 'RecurrenceType.monthly':
      return event.monthlyDay ? date.getDate() === event.monthlyDay : true;
    default:
      return true;
  }
}

function getNextDate(event: any, currentDate: Date): Date {
  const interval = event.recurrenceInterval || 1;
  const nextDate = new Date(currentDate);

  switch (event.recurrenceType) {
    case 'RecurrenceType.daily':
      nextDate.setDate(nextDate.getDate() + interval);
      break;
    case 'RecurrenceType.weekly':
      nextDate.setDate(nextDate.getDate() + (7 * interval));
      break;
    case 'RecurrenceType.monthly':
      nextDate.setMonth(nextDate.getMonth() + interval);
      break;
    case 'RecurrenceType.yearly':
      nextDate.setFullYear(nextDate.getFullYear() + interval);
      break;
  }

  return nextDate;
}

// Add this Cloud Function to generate recurring event instances
exports.generateRecurringEvents = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    const now = new Date();
    const threeMonthsFromNow = new Date(now);
    threeMonthsFromNow.setMonth(threeMonthsFromNow.getMonth() + 3);

    const churches = await admin.firestore().collection('churches').get();

    for (const church of churches.docs) {
      const teams = await church.ref.collection('ministry_teams').get();

      for (const team of teams.docs) {
        const events = await team.ref
          .collection('events')
          .where('recurrenceType', '!=', 'RecurrenceType.none')
          .where('isRecurringInstance', '!=', true)
          .get();

        for (const event of events.docs) {
          const eventData = event.data();
          const instances = generateEventInstances(
            { ...eventData, id: event.id },
            now,
            threeMonthsFromNow
          );

          // Delete old instances
          const oldInstances = await team.ref
            .collection('events')
            .where('parentEventId', '==', event.id)
            .where('startTime', '<', now.toISOString())
            .get();

          const batch = admin.firestore().batch();
          oldInstances.docs.forEach(doc => batch.delete(doc.ref));

          // Create new instances
          for (const instance of instances) {
            const docRef = team.ref.collection('events').doc();
            batch.set(docRef, instance);
          }

          await batch.commit();
        }
      }
    }
  }); 