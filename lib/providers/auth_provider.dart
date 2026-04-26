import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  // Singleton instance for the router to listen to
  static final AuthProvider instance = AuthProvider._();
  AuthProvider._() {
    _service.authStateChanges.listen(_onAuthStateChanged);
  }

  final _service = AuthService.instance;

  UserModel? _user;
  bool _loading = false;
  bool _isInitialized = false; 
  String? _error;

  UserModel? get user         => _user;
  bool get loading            => _loading;
  bool get isInitialized      => _isInitialized; 
  String? get error           => _error;
  bool get isLoggedIn         => _user != null;
  bool get isOnboarded        => _user?.isOnboarded ?? false;

  // ── Auth state listener ───────────────────────────────────────────────────────
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      // Background fetch of the profile
      final profile = await _service.fetchUser(firebaseUser.uid);
      
      // We only update if we found a profile. If it's null, we might be in the 
      // middle of a registration/sign-in process that will set the user manually.
      if (profile != null) {
        _user = profile;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching user profile in background: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    try {
      // This creates the Auth user AND the Firestore doc
      final newUser = await _service.register(
        email: email, password: password, displayName: displayName,
      );
      _user = newUser;
      _error = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _service.login(email: email, password: password);
      final firebaseUser = _service.currentUser;
      if (firebaseUser != null) {
        _user = await _service.fetchUser(firebaseUser.uid);
      }
      _error = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Google Sign In ──────────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final cred = await _service.signInWithGoogle();
      if (cred == null) {
        _setLoading(false);
        return false;
      }
      // Immediately fetch the profile we just ensured/created in the service
      final profile = await _service.fetchUser(cred.user!.uid);
      _user = profile;
      _error = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      return false;
    } catch (e) {
      _error = 'Google Sign In failed.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _service.signOut();
    _user = null;
    notifyListeners();
  }

  // ── Complete onboarding ───────────────────────────────────────────────────────
  Future<void> completeOnboarding({
    required int age,
    required double weightKg,
    required double heightCm,
    required String fitnessGoal,
    required String activityLevel,
  }) async {
    if (_user == null) return;
    final updated = _user!.copyWith(
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
      fitnessGoal: fitnessGoal,
      activityLevel: activityLevel,
      isOnboarded: true,
    );
    await _service.updateUser(updated);
    _user = updated;
    notifyListeners();
  }

  // ── Update profile ────────────────────────────────────────────────────────────
  Future<void> updateProfile(UserModel updated) async {
    await _service.updateUser(updated);
    _user = updated;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _friendlyError(String code) => switch (code) {
    'user-not-found'       => 'No account found with that email.',
    'wrong-password'       => 'Incorrect password.',
    'email-already-in-use' => 'An account with that email already exists.',
    'weak-password'        => 'Password must be at least 6 characters.',
    'invalid-email'        => 'Please enter a valid email address.',
    'network-request-failed' => 'Check your internet connection.',
    'account-exists-with-different-credential' => 'Account already exists with a different login method.',
    _                      => 'Something went wrong. Please try again.',
  };
}
