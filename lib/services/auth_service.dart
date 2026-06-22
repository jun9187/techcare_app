import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class AuthResult {
  final UserCredential credential;
  final String role;

  AuthResult({required this.credential, required this.role});
}

class AuthRoleException implements Exception {
  const AuthRoleException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthRolePolicy {
  const AuthRolePolicy._();

  static String resolve({
    required String storedRole,
    required String selectedRole,
  }) {
    final accountRole = storedRole.trim().toLowerCase();
    final requestedRole = selectedRole.trim().toLowerCase();

    if (requestedRole != 'student' && requestedRole != 'admin') {
      throw const AuthRoleException('Please select a valid role to continue.');
    }

    if (accountRole == 'admin') {
      return requestedRole;
    }

    if (accountRole == 'student' && requestedRole == 'admin') {
      throw const AuthRoleException(
        'This student account does not have admin access. '
        'Please select Student to continue.',
      );
    }

    if (accountRole == requestedRole) {
      return requestedRole;
    }

    throw AuthRoleException(
      'This account is registered as $accountRole and cannot sign in as '
      '$requestedRole.',
    );
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  String? _activeRole;
  String? _activeRoleUid;

  Stream<User?> get user => _auth.authStateChanges();

  Future<String> getActiveRole(User user) async {
    if (_activeRoleUid == user.uid && _activeRole != null) {
      return _activeRole!;
    }

    return getStoredRole(user);
  }

  Future<String> getStoredRole(User user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data();
    final storedRole = (data?['role'] as String?)?.trim().toLowerCase();

    if (storedRole == null || storedRole.isEmpty) {
      await _firestore.collection('users').doc(user.uid).set({
        'role': 'student',
      }, SetOptions(merge: true));
      return 'student';
    }

    return storedRole;
  }

  Future<AuthResult> signInWithEmail(
    String email,
    String password,
    String selectedRole,
  ) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    try {
      final role = await _resolveUserRole(
        user: credential.user,
        selectedRole: selectedRole,
      );
      _rememberActiveRole(credential.user, role);

      return AuthResult(credential: credential, role: role);
    } on AuthRoleException {
      try {
        await _auth.signOut();
      } finally {
        _clearActiveRole();
      }
      rethrow;
    } catch (_) {
      try {
        await _auth.signOut();
      } finally {
        _clearActiveRole();
      }
      rethrow;
    }
  }

  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String matricNumber,
    String role = 'student',
  }) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Store user data in Firestore
    await _firestore.collection('users').doc(result.user!.uid).set({
      'uid': result.user!.uid,
      'email': email,
      'name': name,
      'matricNumber': matricNumber,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _rememberActiveRole(result.user, role);

    return AuthResult(credential: result, role: role);
  }

  Future<AuthResult?> signInWithGoogle(String selectedRole) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(
        credential,
      );

      // Check if user exists in Firestore, if not create entry
      final userRef = _firestore.collection('users').doc(result.user!.uid);
      final doc = await userRef.get();
      if (!doc.exists) {
        await userRef.set({
          'uid': result.user!.uid,
          'email': result.user!.email,
          'name': result.user!.displayName,
          'role': 'student',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final role = await _resolveUserRole(
        user: result.user,
        selectedRole: selectedRole,
      );
      _rememberActiveRole(result.user, role);

      return AuthResult(credential: result, role: role);
    } on AuthRoleException {
      await _signOutAfterFailedGoogleLogin();
      rethrow;
    } catch (e) {
      await _signOutAfterFailedGoogleLogin();
      debugPrint("TechCare Google Auth Error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } finally {
      _clearActiveRole();
    }
  }

  Future<void> createUserAsAdmin({
    required String email,
    required String password,
    required String name,
    required String matricNumber,
    required String role,
  }) async {
    final secondaryApp = await Firebase.initializeApp(
      name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
      options: DefaultFirebaseOptions.currentPlatform,
    );

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': email,
        'name': name,
        'matricNumber': matricNumber,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await secondaryAuth.signOut();
    } finally {
      await secondaryApp.delete();
    }
  }

  Future<void> updateUserRole({
    required String uid,
    required String newRole,
  }) async {
    await _firestore.collection('users').doc(uid).update({'role': newRole});
  }

  Stream<List<Map<String, dynamic>>> streamAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  Stream<Map<String, dynamic>?> streamUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) {
        return null;
      }

      return {'id': doc.id, ...data};
    });
  }

  Future<String> _resolveUserRole({
    required User? user,
    required String selectedRole,
  }) async {
    if (user == null) {
      throw Exception('Unable to resolve authenticated user.');
    }

    final storedRole = await getStoredRole(user);
    return AuthRolePolicy.resolve(
      storedRole: storedRole,
      selectedRole: selectedRole,
    );
  }

  void _rememberActiveRole(User? user, String role) {
    _activeRoleUid = user?.uid;
    _activeRole = user == null ? null : role;
  }

  void _clearActiveRole() {
    _activeRoleUid = null;
    _activeRole = null;
  }

  Future<void> _signOutAfterFailedGoogleLogin() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      debugPrint('TechCare Google sign-out cleanup error: $error');
    }

    try {
      await _auth.signOut();
    } finally {
      _clearActiveRole();
    }
  }
}
