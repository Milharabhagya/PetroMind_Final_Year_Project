class RoadAlert {
  final String id;
  final String type; // 'accident', 'police', 'roadblock', 'traffic'
  final double lat;
  final double lng;
  final String reportedBy;
  final DateTime reportedAt;
  final String? description;
  final int upvotes;

  RoadAlert({
    required this.id,
    required this.type,
    required this.lat,
    required this.lng,
    required this.reportedBy,
    required this.reportedAt,
    this.description,
    this.upvotes = 0,
  });

  factory RoadAlert.fromMap(Map<String, dynamic> map, String id) {
    return RoadAlert(
      id: id,
      type: map['type'] ?? '',
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      reportedBy: map['reportedBy'] ?? '',
      reportedAt: DateTime.fromMillisecondsSinceEpoch(map['reportedAt'] ?? 0),
      description: map['description'],
      upvotes: map['upvotes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'lat': lat,
      'lng': lng,
      'reportedBy': reportedBy,
      'reportedAt': reportedAt.millisecondsSinceEpoch,
      'description': description,
      'upvotes': upvotes,
    };
  }
}