import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/trip.dart';

class TripRepository {
  TripRepository(this._firestore);
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _trips => _firestore.collection('trips');

  Stream<List<Trip>> watchMyTrips(String userId) {
    return _trips
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((s) => s.docs.map((d) => d.toTrip()).toList());
  }

  Stream<Trip> watchTrip(String tripId) =>
      _trips.doc(tripId).snapshots().map((d) => Trip.fromMap(d.id, d.data()!));

  Future<String> createTrip({
    required String name,
    required String adminId,
    required List<String> memberIds,
    required DateTime startDate,
  }) async {
    final id = _uuid.v4();
    final trip = Trip(
      id: id,
      name: name,
      adminId: adminId,
      memberIds: memberIds,
      startDate: startDate,
    );
    await _trips.doc(id).set(trip.toMap());
    return id;
  }

  Future<void> setBudget(String tripId, String userId, double amount) {
    return _trips.doc(tripId).collection('budgets').doc(userId).set({
      'budgetAmount': amount,
      'spent': 0,
    }, SetOptions(merge: true));
  }

  Future<void> handoverAdmin(String tripId, String newAdminId) {
    return _trips.doc(tripId).update({'adminId': newAdminId});
  }

  Future<void> closeTrip(String tripId) =>
      _trips.doc(tripId).update({'status': 'closed', 'endDate': DateTime.now().toIso8601String()});
}

final tripRepositoryProvider = Provider<TripRepository>(
  (_) => TripRepository(FirebaseFirestore.instance),
);

final myTripsProvider = StreamProvider<List<Trip>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return ref.watch(tripRepositoryProvider).watchMyTrips(user.uid);
});

final tripProvider = StreamProvider.family<Trip, String>((ref, tripId) {
  return ref.watch(tripRepositoryProvider).watchTrip(tripId);
});
