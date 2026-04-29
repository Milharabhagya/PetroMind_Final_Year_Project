import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/area_message_model.dart';

class AreaChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ Generate area key from lat/lng
  // Rounds to 2 decimal places (~1.1km grid)
  String _getAreaKey(double lat, double lng) {
    final latKey = (lat * 100).round();
    final lngKey = (lng * 100).round();
    return 'area_${latKey}_$lngKey';
  }

  // ✅ Generate anonymous display name
  // Same user always gets same number in same area
  String _getAnonymousName(String uid) {
    final hash = uid.codeUnits
        .fold(0, (prev, e) => prev + e) % 9000 + 1000;
    return 'Nearby Driver #$hash';
  }

  // ✅ Send a message to the area chat
  Future<void> sendMessage({
    required double userLat,
    required double userLng,
    required String message,
    String? replyToId,
    String? replyToMessage,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final areaKey = _getAreaKey(userLat, userLng);
    final senderName = _getAnonymousName(user.uid);

    final msg = AreaMessage(
      id: '',
      senderId: user.uid,
      senderName: senderName,
      message: message.trim(),
      sentAt: DateTime.now(),
      senderLat: userLat,
      senderLng: userLng,
      replyToId: replyToId,
      replyToMessage: replyToMessage,
    );

    await _db
        .collection('area_chats')
        .doc(areaKey)
        .collection('messages')
        .add(msg.toMap());

    // ✅ Subscribe to area topic for push notifications
    if (!kIsWeb) {
      await FirebaseMessaging.instance
          .subscribeToTopic(areaKey);
    }
  }

  // ✅ Stream messages from the area
  // Only shows last 24 hours
  Stream<List<AreaMessage>> getMessages({
    required double userLat,
    required double userLng,
  }) {
    final areaKey = _getAreaKey(userLat, userLng);
    final since = DateTime.now()
        .subtract(const Duration(hours: 24))
        .millisecondsSinceEpoch;

    return _db
        .collection('area_chats')
        .doc(areaKey)
        .collection('messages')
        .where('sentAt', isGreaterThan: since)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AreaMessage.fromMap(
                doc.data(), doc.id))
            .toList());
  }

  // ✅ Delete messages older than 24 hours
  Future<void> cleanOldMessages({
    required double userLat,
    required double userLng,
  }) async {
    final areaKey = _getAreaKey(userLat, userLng);
    final cutoff = DateTime.now()
        .subtract(const Duration(hours: 24))
        .millisecondsSinceEpoch;

    final old = await _db
        .collection('area_chats')
        .doc(areaKey)
        .collection('messages')
        .where('sentAt', isLessThan: cutoff)
        .get();

    for (final doc in old.docs) {
      await doc.reference.delete();
    }
  }

  String getAnonymousName(String uid) =>
      _getAnonymousName(uid);
}