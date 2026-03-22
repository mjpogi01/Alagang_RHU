import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'supabase_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be initialized in the background isolate too.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // ignore: avoid_catches_without_on_clauses
  }
}

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static bool _firebaseReady = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(settings: initSettings);

    if (kIsWeb) return;

    // Firebase config files are required for Android/iOS; if missing, keep app running.
    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (_) {
      _firebaseReady = false;
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;

    // Request permissions (iOS and Android 13+).
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // When a push is received while app is foreground, show it as a local notif.
    FirebaseMessaging.onMessage.listen((message) async {
      final n = message.notification;
      if (n == null) return;
      await showInstant(
        title: n.title ?? 'Alagang RHU',
        body: n.body ?? '',
      );
    });
  }

  static Future<void> syncTokenIfLoggedIn() async {
    if (!_firebaseReady || kIsWeb) return;
    final uid = SupabaseService.client.auth.currentUser?.id;
    if (uid == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.trim().isEmpty) return;

    final platform =
        Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'other');

    try {
      // idempotent via unique(user_id, token)
      await SupabaseService.client.from('user_push_tokens').insert({
        'user_id': uid,
        'token': token.trim(),
        'platform': platform,
      });
    } catch (_) {
      // ignore duplicates / transient errors
    }
  }

  static Future<void> showInstant({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'announcements',
      'Announcements',
      channelDescription: 'New events and announcements',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _local.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  static int _notifIdFromKey(String appointmentId, String key) {
    final s = '$appointmentId|$key';
    var hash = 0;
    for (final codeUnit in s.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash;
  }

  static Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required DateTime scheduledAt,
    required String title,
    required String body,
    required String reminderKey,
  }) async {
    final when = tz.TZDateTime.from(scheduledAt, tz.local);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) return;

    const androidDetails = AndroidNotificationDetails(
      'appointment_reminders',
      'Appointment reminders',
      channelDescription: 'Reminders for your booked appointments',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _local.zonedSchedule(
      id: _notifIdFromKey(appointmentId, reminderKey),
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}

