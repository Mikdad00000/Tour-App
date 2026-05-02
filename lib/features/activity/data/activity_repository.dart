import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityItem {
  ActivityItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.recipients,
    required this.readBy,
    required this.createdAt,
  });
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final List<String> recipients;
  final List<String> readBy;
  final DateTime createdAt;

  factory ActivityItem.fromMap(String id, Map<String, dynamic> m) => ActivityItem(
        id: id,
        type: m['type'] as String,
        payload: Map<String, dynamic>.from(m['payload'] as Map),
        recipients: List<String>.from((m['recipients'] as List?) ?? const []),
        readBy: List<String>.from((m['readBy'] as List?) ?? const []),
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}

class ActivityRepository {
  ActivityRepository(this._firestore);
  final FirebaseFirestore _firestore;

  Stream<List<ActivityItem>> watch(String tripId) => _firestore
      .collection('trips')
      .doc(tripId)
      .collection('activity')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map((d) => ActivityItem.fromMap(d.id, d.data())).toList());

  Future<void> markRead(String tripId, String activityId, String userId) {
    return _firestore
        .collection('trips').doc(tripId)
        .collection('activity').doc(activityId)
        .update({'readBy': FieldValue.arrayUnion([userId])});
  }
}

final activityRepositoryProvider = Provider<ActivityRepository>(
  (_) => ActivityRepository(FirebaseFirestore.instance),
);

final activityProvider = StreamProvider.family<List<ActivityItem>, String>(
  (ref, tripId) => ref.watch(activityRepositoryProvider).watch(tripId),
);
