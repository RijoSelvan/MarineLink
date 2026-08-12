import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===========================
  // REGISTER USER
  // ===========================

  Future<void> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User user = userCredential.user!;

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Registration failed. Please try again.');
    }
  }

  // ===========================
  // LOGIN USER
  // ===========================

  Future<Map<String, dynamic>?> loginUser(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Unable to identify the user.');
      }

      final DocumentSnapshot<Map<String, dynamic>> document =
          await _firestore.collection('users').doc(user.uid).get();

      if (!document.exists || document.data() == null) {
        throw Exception(
          'User profile was not found. Please contact the administrator.',
        );
      }

      return document.data();
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception('Login failed. Please try again.');
    }
  }

  // ===========================
  // LOGOUT
  // ===========================

  Future<void> logout() async {
    await _auth.signOut();
  }

  // ===========================
  // CURRENT USER
  // ===========================

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // ===========================
  // RESET PASSWORD
  // ===========================

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    }
  }

  // ===========================
  // FIREBASE AUTH ERROR MESSAGE
  // ===========================

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-not-found':
        return 'No account found with this email.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'email-already-in-use':
        return 'An account already exists with this email.';

      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      default:
        return 'Authentication failed. Please try again.';
    }
  }
}