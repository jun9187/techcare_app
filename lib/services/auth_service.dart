import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  Stream<User?> get user => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Trigger the sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null;

      // 2. Obtain auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create the credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("TechCare Google Auth Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
