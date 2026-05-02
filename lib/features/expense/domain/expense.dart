import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseType { shared, partial, individual, peerLoan }

extension ExpenseTypeX on ExpenseType {
  String get wire {
    switch (this) {
      case ExpenseType.shared:
        return 'shared';
      case ExpenseType.partial:
        return 'partial';
      case ExpenseType.individual:
        return 'individual';
      case ExpenseType.peerLoan:
        return 'peer_loan';
    }
  }

  static ExpenseType fromWire(String s) {
    switch (s) {
      case 'shared':
        return ExpenseType.shared;
      case 'partial':
        return ExpenseType.partial;
      case 'individual':
        return ExpenseType.individual;
      case 'peer_loan':
        return ExpenseType.peerLoan;
      default:
        throw ArgumentError('Unknown expense type: $s');
    }
  }
}

class GeoPoint2 {
  const GeoPoint2(this.lat, this.lng, this.placeName);
  final double lat;
  final double lng;
  final String? placeName;
}

class Expense {
  Expense({
    required this.id,
    required this.tripId,
    required this.type,
    required this.paidBy,
    required this.fromPool,
    required this.participants,
    required this.witnesses,
    required this.amount,
    required this.perHeadAmount,
    required this.createdAt,
    this.category,
    this.note,
    this.location,
    this.receiptUrl,
    this.loanStatus,
    this.repaidAt,
    this.repaidBy = const [],
  });

  final String id;
  final String tripId;
  final ExpenseType type;
  final String paidBy;
  final bool fromPool;
  final List<String> participants;
  final List<String> witnesses;
  final double amount;
  final double perHeadAmount;
  final String? category;
  final String? note;
  final GeoPoint2? location;
  final String? receiptUrl;
  final String? loanStatus; // 'pending' | 'repaid' | null
  final DateTime? repaidAt;
  final List<String> repaidBy;
  final DateTime createdAt;

  bool get isPeerLoan => type == ExpenseType.peerLoan;
  bool get isUnsettledLoan => isPeerLoan && loanStatus != 'repaid';

  Map<String, dynamic> toMap() => {
        'type': type.wire,
        'paidBy': paidBy,
        'fromPool': fromPool,
        'participants': participants,
        'witnesses': witnesses,
        'amount': amount,
        'perHeadAmount': perHeadAmount,
        'category': category,
        'note': note,
        'location': location == null
            ? null
            : {'lat': location!.lat, 'lng': location!.lng, 'placeName': location!.placeName},
        'receiptUrl': receiptUrl,
        'loanStatus': loanStatus,
        'repaidAt': repaidAt?.toIso8601String(),
        'repaidBy': repaidBy,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Expense.fromMap(String id, String tripId, Map<String, dynamic> m) {
    final loc = m['location'] as Map<String, dynamic>?;
    return Expense(
      id: id,
      tripId: tripId,
      type: ExpenseTypeX.fromWire(m['type'] as String),
      paidBy: m['paidBy'] as String,
      fromPool: m['fromPool'] as bool? ?? true,
      participants: List<String>.from(m['participants'] as List),
      witnesses: List<String>.from((m['witnesses'] as List?) ?? const []),
      amount: (m['amount'] as num).toDouble(),
      perHeadAmount: (m['perHeadAmount'] as num).toDouble(),
      category: m['category'] as String?,
      note: m['note'] as String?,
      location: loc == null
          ? null
          : GeoPoint2(
              (loc['lat'] as num).toDouble(),
              (loc['lng'] as num).toDouble(),
              loc['placeName'] as String?,
            ),
      receiptUrl: m['receiptUrl'] as String?,
      loanStatus: m['loanStatus'] as String?,
      repaidAt: m['repaidAt'] == null ? null : DateTime.parse(m['repaidAt'] as String),
      repaidBy: List<String>.from((m['repaidBy'] as List?) ?? const []),
      createdAt: DateTime.parse(m['createdAt'] as String),
    );
  }
}

extension ExpenseDoc on QueryDocumentSnapshot<Map<String, dynamic>> {
  Expense toExpense(String tripId) => Expense.fromMap(id, tripId, data());
}
