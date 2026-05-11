import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthResult {
  final UserCredential credential;
  final String role;

  AuthResult({
    required this.credential,
    required this.role,
  });
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  Stream<User?> get user => _auth.authStateChanges();

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

    final role = await _resolveUserRole(
      user: credential.user,
      selectedRole: selectedRole,
    );

    return AuthResult(credential: credential, role: role);
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

    return AuthResult(credential: result, role: role);
  }

  Future<AuthResult?> signInWithGoogle(String selectedRole) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);

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

      return AuthResult(credential: result, role: role);
    } catch (e) {
      debugPrint("TechCare Google Auth Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<String> _resolveUserRole({
    required User? user,
    required String selectedRole,
  }) async {
    if (user == null) {
      throw Exception('Unable to resolve authenticated user.');
    }

    final storedRole = await getStoredRole(user);
    final normalizedRole = selectedRole.trim().toLowerCase();

    if (storedRole != normalizedRole) {
      throw Exception(
        'This account is registered as $storedRole. Please choose the correct role to continue.',
      );
    }

    return storedRole;
  }
}
