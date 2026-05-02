import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class Deposit {
  Deposit({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
    this.note,
    this.confirmedByAdmin = false,
  });
  final String id;
  final String userId;
  final double amount;
  final DateTime date;
  final String? note;
  final bool confirmedByAdmin;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
        'confirmedByAdmin': confirmedByAdmin,
      };

  factory Deposit.fromMap(String id, Map<String, dynamic> m) => Deposit(
        id: id,
        userId: m['userId'] as String,
        amount: (m['amount'] as num).toDouble(),
        date: DateTime.parse(m['date'] as String),
        note: m['note'] as String?,
        confirmedByAdmin: m['confirmedByAdmin'] as bool? ?? false,
      );
}

class DepositRepository {
  DepositRepository(this._firestore);
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _coll(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('deposits');

  Stream<List<Deposit>> watch(String tripId) =>
      _coll(tripId).orderBy('date', descending: true).snapshots().map(
            (s) => s.docs.map((d) => Deposit.fromMap(d.id, d.data())).toList(),
          );

  Future<String> add({
    required String tripId,
    required String userId,
    required double amount,
    String? note,
  }) async {
    final id = _uuid.v4();
    final d = Deposit(
      id: id,
      userId: userId,
      amount: amount,
      date: DateTime.now(),
      note: note,
    );
    await _coll(tripId).doc(id).set(d.toMap());
    return id;
  }

  Future<void> confirm(String tripId, String depositId, double amount) async {
    await _coll(tripId).doc(depositId).update({'confirmedByAdmin': true});
    await _firestore.collection('trips').doc(tripId).update({
      'totalCash': FieldValue.increment(amount),
    });
  }
}

final depositRepositoryProvider = Provider<DepositRepository>(
  (_) => DepositRepository(FirebaseFirestore.instance),
);

final depositsProvider = StreamProvider.family<List<Deposit>, String>(
  (ref, tripId) => ref.watch(depositRepositoryProvider).watch(tripId),
);
