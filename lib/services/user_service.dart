import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // ================================================================
  // GET USER PROFILE
  // ================================================================
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  // ================================================================
  // STREAM USER PROFILE
  // ================================================================
  Stream<UserModel?> streamUserProfile(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  // ================================================================
  // UPDATE USER PROFILE
  // ================================================================
  Future<String?> updateUserProfile(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).update(user.toMap());
      return null;
    } on FirebaseException catch (e) {
      return e.message ?? 'Failed to update profile';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // ================================================================
  // UPDATE SPECIFIC USER FIELDS
  // ================================================================
  Future<String?> updateFields(String uid, Map<String, dynamic> fields) async {
    try {
      fields['updatedAt'] = FieldValue.serverTimestamp();
      await _usersCollection.doc(uid).update(fields);
      return null;
    } on FirebaseException catch (e) {
      return e.message ?? 'Failed to update fields';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // ================================================================
  // STREAM USERS BY ROLE
  // ================================================================
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUsersByRole(String role) {
    return _usersCollection
        .where('role', isEqualTo: role)
        .snapshots();
  }

  // ================================================================
  // STREAM ALL USERS
  // ================================================================
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllUsers() {
    return _usersCollection.snapshots();
  }

  // ================================================================
  // DELETE USER (DOCUMENT)
  // ================================================================
  Future<String?> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
      return null;
    } on FirebaseException catch (e) {
      return e.message ?? 'Failed to delete user record';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
