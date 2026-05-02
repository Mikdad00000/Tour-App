import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepository {
  AuthRepository(this._auth, this._firestore);
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<String> sendOtp(String phone) async {
    final completer = Completer<String>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (_) {},
      verificationFailed: (e) => completer.completeError(e),
      codeSent: (verId, _) => completer.complete(verId),
      codeAutoRetrievalTimeout: (_) {},
    );
    return completer.future;
  }

  Future<UserCredential> verifyOtp(String verificationId, String code) {
    final cred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );
    return _auth.signInWithCredential(cred);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> upsertProfile({required String name}) async {
    final user = _auth.currentUser!;
    await _firestore.collection('users').doc(user.uid).set({
      'name': name,
      'phone': user.phoneNumber,
      'createdAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);
