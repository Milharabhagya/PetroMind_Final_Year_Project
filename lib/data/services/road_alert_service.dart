import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../models/road_alert_model.dart';

class RoadAlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ─── Init local notifications + FCM ─────────────────────────────────────────
  Future<void> init() async {
    // Skip on web
    if (kIsWeb) return;

    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await messaging.subscribeToTopic('road_alerts');

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);

    // Handle foreground FCM messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(
        title: message.notification?.title ?? 'Road Alert',
        body: message.notification?.body ?? 'There is an alert near you.',
      );
    });
  }

  // ─── Show local notification ─────────────────────────────────────────────────
  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'road_alerts_channel',
      'Road Alerts',
      channelDescription: 'Notifications for road alerts near you',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  // ─── Report a new alert ──────────────────────────────────────────────────────
  Future<void> reportAlert(RoadAlert alert) async {
    await _firestore.collection('road_alerts').add(alert.toMap());

    if (!kIsWeb) {
      _showLocalNotification(
        title: '${_alertLabel(alert.type)} Reported',
        body: 'Your report has been submitted. Stay safe!',
      );
    }
  }

  // ─── Listen to nearby alerts (within ~5km) ──────────────────────────────────
  Stream<List<RoadAlert>> getNearbyAlerts({
    required double userLat,
    required double userLng,
    double radiusDeg = 0.045,
  }) {
    return _firestore
        .collection('road_alerts')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RoadAlert.fromMap(doc.data(), doc.id))
          .where((alert) {
            final latDiff = (alert.lat - userLat).abs();
            final lngDiff = (alert.lng - userLng).abs();
            return latDiff <= radiusDeg && lngDiff <= radiusDeg;
          })
          .where((alert) =>
              DateTime.now().difference(alert.reportedAt).inHours < 2)
          .toList();
    });
  }

  // ─── Upvote an alert ─────────────────────────────────────────────────────────
  Future<void> upvoteAlert(String alertId) async {
    await _firestore.collection('road_alerts').doc(alertId).update({
      'upvotes': FieldValue.increment(1),
    });
  }

  // ─── Delete an alert ─────────────────────────────────────────────────────────
  Future<void> deleteAlert(String alertId) async {
    await _firestore.collection('road_alerts').doc(alertId).delete();
  }

  String _alertLabel(String type) {
    switch (type) {
      case 'accident':
        return '🚨 Accident';
      case 'police':
        return '🚔 Police Checkpoint';
      case 'roadblock':
        return '🚧 Road Block';
      case 'traffic':
        return '🚦 Heavy Traffic';
      default:
        return 'Alert';
    }
  }
}