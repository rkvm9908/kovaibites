import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authChanges => _auth.authStateChanges();

  /// Creates the auth account and the matching profile document.
  Future<void> signUp(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _db.collection('users').doc(cred.user!.uid).set(
          AppUser(uid: cred.user!.uid, name: name, email: email).toMap(),
        );
  }

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> updateName(String uid, String name) =>
      _db.collection('users').doc(uid).update({'name': name});

  /// Saves the profile picture URL. Pass an empty string to remove it.
  Future<void> updatePhoto(String uid, String url) =>
      _db.collection('users').doc(uid).update({'photoUrl': url});
}