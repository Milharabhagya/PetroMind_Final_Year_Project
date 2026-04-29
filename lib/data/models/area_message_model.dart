class AreaMessage {
  final String id;
  final String senderId;
  final String senderName; // always 'Nearby Driver #X'
  final String message;
  final DateTime sentAt;
  final double senderLat;
  final double senderLng;
  final String? replyToId;
  final String? replyToMessage;

  AreaMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.sentAt,
    required this.senderLat,
    required this.senderLng,
    this.replyToId,
    this.replyToMessage,
  });

  factory AreaMessage.fromMap(
      Map<String, dynamic> map, String id) {
    return AreaMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Nearby Driver',
      message: map['message'] ?? '',
      sentAt: DateTime.fromMillisecondsSinceEpoch(
          map['sentAt'] ?? 0),
      senderLat:
          (map['senderLat'] as num?)?.toDouble() ?? 0,
      senderLng:
          (map['senderLng'] as num?)?.toDouble() ?? 0,
      replyToId: map['replyToId'],
      replyToMessage: map['replyToMessage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'sentAt': sentAt.millisecondsSinceEpoch,
      'senderLat': senderLat,
      'senderLng': senderLng,
      'replyToId': replyToId,
      'replyToMessage': replyToMessage,
    };
  }
}