import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  Trip({
    required this.id,
    required this.name,
    required this.adminId,
    required this.memberIds,
    required this.startDate,
    this.endDate,
    this.status = 'active',
    this.currency = 'BDT',
    this.totalCash = 0,
    this.totalSpent = 0,
  });

  final String id;
  final String name;
  final String adminId;
  final List<String> memberIds;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final String currency;
  final double totalCash;
  final double totalSpent;

  factory Trip.fromMap(String id, Map<String, dynamic> m) => Trip(
        id: id,
        name: m['name'] as String,
        adminId: m['adminId'] as String,
        memberIds: List<String>.from(m['memberIds'] as List),
        startDate: DateTime.parse(m['startDate'] as String),
        endDate: m['endDate'] == null ? null : DateTime.parse(m['endDate'] as String),
        status: m['status'] as String? ?? 'active',
        currency: m['currency'] as String? ?? 'BDT',
        totalCash: (m['totalCash'] as num?)?.toDouble() ?? 0,
        totalSpent: (m['totalSpent'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'adminId': adminId,
        'memberIds': memberIds,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'status': status,
        'currency': currency,
        'totalCash': totalCash,
        'totalSpent': totalSpent,
      };

  bool isAdmin(String userId) => adminId == userId;
}

extension TripDoc on QueryDocumentSnapshot<Map<String, dynamic>> {
  Trip toTrip() => Trip.fromMap(id, data());
}
