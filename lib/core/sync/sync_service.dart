import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../connectivity/connectivity_service.dart';
import '../db/app_database.dart';

/// Push pending local rows to Firestore, pull remote changes into local DB.
/// Single source of truth = local drift DB; UI reads from local.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  AppDatabase? _db;
  StreamSubscription<bool>? _connSub;
  final _firestore = FirebaseFirestore.instance;

  void attachDb(AppDatabase db) => _db = db;

  Future<void> init() async {
    _connSub?.cancel();
    _connSub = ConnectivityService.instance.onChange().listen((online) {
      if (online) unawaited(syncNow());
    });
  }

  Future<void> syncNow() async {
    final db = _db;
    final user = FirebaseAuth.instance.currentUser;
    if (db == null || user == null) return;

    await _pushPending(db);
    await _pullRecent(db, user.uid);
  }

  Future<void> _pushPending(AppDatabase db) async {
    final pendingExpenses = await (db.select(db.expenses)
          ..where((e) => e.syncStatus.equals(SyncStatusConst.pending)))
        .get();
    for (final e in pendingExpenses) {
      await _firestore
          .collection('trips').doc(e.tripId)
          .collection('expenses').doc(e.id)
          .set(_expenseToMap(e));
      await (db.update(db.expenses)..where((t) => t.id.equals(e.id)))
          .write(const ExpensesCompanion(syncStatus: Value(SyncStatusConst.synced)));
    }

    final pendingDeposits = await (db.select(db.deposits)
          ..where((d) => d.syncStatus.equals(SyncStatusConst.pending)))
        .get();
    for (final d in pendingDeposits) {
      await _firestore
          .collection('trips').doc(d.tripId)
          .collection('deposits').doc(d.id)
          .set(_depositToMap(d));
      await (db.update(db.deposits)..where((t) => t.id.equals(d.id)))
          .write(const DepositsCompanion(syncStatus: Value(SyncStatusConst.synced)));
    }
  }

  Future<void> _pullRecent(AppDatabase db, String userId) async {
    final tripSnap = await _firestore
        .collection('trips')
        .where('memberIds', arrayContains: userId)
        .get();
    for (final doc in tripSnap.docs) {
      await db.into(db.trips).insertOnConflictUpdate(_tripFromMap(doc));
      // expenses
      final exSnap = await doc.reference.collection('expenses').get();
      for (final ex in exSnap.docs) {
        await db.into(db.expenses).insertOnConflictUpdate(_expenseFromMap(ex));
      }
      final dpSnap = await doc.reference.collection('deposits').get();
      for (final dp in dpSnap.docs) {
        await db.into(db.deposits).insertOnConflictUpdate(_depositFromMap(dp));
      }
    }
  }

  Map<String, dynamic> _expenseToMap(ExpenseRow e) => {
        'type': e.type,
        'paidBy': e.paidBy,
        'fromPool': e.fromPool,
        'participants': jsonDecode(e.participantsJson),
        'witnesses': jsonDecode(e.witnessesJson),
        'amount': e.amount,
        'perHeadAmount': e.perHeadAmount,
        'category': e.category,
        'note': e.note,
        'location': e.lat == null
            ? null
            : {'lat': e.lat, 'lng': e.lng, 'placeName': e.placeName},
        'receiptUrl': e.receiptUrl,
        'loanStatus': e.loanStatus,
        'repaidAt': e.repaidAt?.toIso8601String(),
        'repaidBy': e.repaidByJson == null ? null : jsonDecode(e.repaidByJson!),
        'createdAt': e.createdAt.toIso8601String(),
      };

  ExpensesCompanion _expenseFromMap(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data();
    final loc = m['location'] as Map<String, dynamic>?;
    return ExpensesCompanion.insert(
      id: doc.id,
      tripId: doc.reference.parent.parent!.id,
      type: m['type'] as String,
      paidBy: m['paidBy'] as String,
      fromPool: Value(m['fromPool'] as bool? ?? true),
      participantsJson: jsonEncode(m['participants'] ?? []),
      witnessesJson: Value(jsonEncode(m['witnesses'] ?? [])),
      amount: (m['amount'] as num).toDouble(),
      perHeadAmount: (m['perHeadAmount'] as num).toDouble(),
      category: Value(m['category'] as String?),
      note: Value(m['note'] as String?),
      lat: Value(loc?['lat'] as double?),
      lng: Value(loc?['lng'] as double?),
      placeName: Value(loc?['placeName'] as String?),
      receiptUrl: Value(m['receiptUrl'] as String?),
      loanStatus: Value(m['loanStatus'] as String?),
      repaidAt: Value(m['repaidAt'] == null ? null : DateTime.parse(m['repaidAt'] as String)),
      repaidByJson: Value(m['repaidBy'] == null ? null : jsonEncode(m['repaidBy'])),
      createdAt: DateTime.parse(m['createdAt'] as String),
      syncStatus: const Value(SyncStatusConst.synced),
    );
  }

  Map<String, dynamic> _depositToMap(DepositRow d) => {
        'userId': d.userId,
        'amount': d.amount,
        'date': d.date.toIso8601String(),
        'note': d.note,
        'confirmedByAdmin': d.confirmedByAdmin,
      };

  DepositsCompanion _depositFromMap(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data();
    return DepositsCompanion.insert(
      id: doc.id,
      tripId: doc.reference.parent.parent!.id,
      userId: m['userId'] as String,
      amount: (m['amount'] as num).toDouble(),
      date: DateTime.parse(m['date'] as String),
      note: Value(m['note'] as String?),
      confirmedByAdmin: Value(m['confirmedByAdmin'] as bool? ?? false),
      syncStatus: const Value(SyncStatusConst.synced),
    );
  }

  TripsCompanion _tripFromMap(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data();
    return TripsCompanion.insert(
      id: doc.id,
      name: m['name'] as String,
      adminId: m['adminId'] as String,
      memberIdsJson: jsonEncode(m['memberIds'] ?? []),
      status: Value(m['status'] as String? ?? 'active'),
      startDate: DateTime.parse(m['startDate'] as String),
      endDate: Value(m['endDate'] == null ? null : DateTime.parse(m['endDate'] as String)),
      currency: Value(m['currency'] as String? ?? 'BDT'),
      totalCash: Value((m['totalCash'] as num?)?.toDouble() ?? 0),
      totalSpent: Value((m['totalSpent'] as num?)?.toDouble() ?? 0),
      syncStatus: const Value(SyncStatusConst.synced),
    );
  }
}
