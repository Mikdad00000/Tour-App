import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/expense.dart';

class ExpenseRepository {
  ExpenseRepository(this._firestore);
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _coll(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('expenses');

  Stream<List<Expense>> watch(String tripId) =>
      _coll(tripId).orderBy('createdAt', descending: true).snapshots().map(
            (s) => s.docs.map((d) => d.toExpense(tripId)).toList(),
          );

  Future<String> add({
    required String tripId,
    required ExpenseType type,
    required String paidBy,
    required bool fromPool,
    required List<String> participants,
    required double amount,
    List<String> witnesses = const [],
    String? category,
    String? note,
    GeoPoint2? location,
    String? receiptUrl,
  }) async {
    final id = _uuid.v4();
    final perHead = participants.isEmpty ? 0.0 : amount / participants.length;
    final exp = Expense(
      id: id,
      tripId: tripId,
      type: type,
      paidBy: paidBy,
      fromPool: fromPool,
      participants: participants,
      witnesses: witnesses,
      amount: amount,
      perHeadAmount: perHead,
      category: category,
      note: note,
      location: location,
      receiptUrl: receiptUrl,
      loanStatus: type == ExpenseType.peerLoan ? 'pending' : null,
      createdAt: DateTime.now(),
    );
    await _coll(tripId).doc(id).set(exp.toMap());

    if (type != ExpenseType.individual) {
      await _firestore.collection('trips').doc(tripId).update({
        if (fromPool) 'totalSpent': FieldValue.increment(amount),
      });
    }
    return id;
  }

  Future<void> markLoanRepaid(String tripId, String expenseId) {
    return _coll(tripId).doc(expenseId).update({
      'loanStatus': 'repaid',
      'repaidAt': DateTime.now().toIso8601String(),
    });
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (_) => ExpenseRepository(FirebaseFirestore.instance),
);

final expensesProvider = StreamProvider.family<List<Expense>, String>(
  (ref, tripId) => ref.watch(expenseRepositoryProvider).watch(tripId),
);
