import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Register ────────────────────────────────────────────────────────────────
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: password,
    );
    await cred.user!.updateDisplayName(displayName);

    final user = UserModel(
      uid:           cred.user!.uid,
      displayName:   displayName,
      email:         email,
      age:           0,
      weightKg:      0,
      heightCm:      0,
      fitnessGoal:   '',
      activityLevel: '',
      isOnboarded:   false,
      createdAt:     DateTime.now(),
    );

    await _db.collection('users').doc(user.uid).set(user.toMap());
    return user;
  }

  // ── Login ───────────────────────────────────────────────────────────────────
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // ── Sign out ─────────────────────────────────────────────────────────────────
  Future<void> signOut() async => _auth.signOut();

  // ── Fetch user profile ───────────────────────────────────────────────────────
  Future<UserModel?> fetchUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // ── Update profile ───────────────────────────────────────────────────────────
  Future<void> updateUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
  }

  // ── Password reset ───────────────────────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}