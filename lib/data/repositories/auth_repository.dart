import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static String? get currentUid => _auth.currentUser?.uid;

  // Register customer
  static Future<Map<String, dynamic>> registerCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await _db.collection('users').doc(cred.user!.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return {'success': true, 'uid': cred.user!.uid};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _authError(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'Something went wrong.'};
    }
  }

  // Register station
  static Future<Map<String, dynamic>> registerStation({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await _db.collection('stations').doc(cred.user!.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': 'station',
        'createdAt': FieldValue.serverTimestamp(),
        'fuelPrices': {},
        'stock': {
          'petrol': 0.0,
          'diesel': 0.0,
          'superDiesel': 0.0,
          'kerosene': 0.0,
        },
        'totalRevenue': 0.0,
        'totalRatings': 0,
        'ratingSum': 0.0,
        'averageRating': 0.0,
        'isOpen': true,
      });
      return {'success': true, 'uid': cred.user!.uid};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _authError(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'Something went wrong.'};
    }
  }

  // Login customer
  static Future<Map<String, dynamic>> loginCustomer({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      final doc =
          await _db.collection('users').doc(cred.user!.uid).get();
      if (!doc.exists || doc.data()?['role'] != 'customer') {
        await _auth.signOut();
        return {
          'success': false,
          'error': 'This account is not a customer account.'
        };
      }
      return {
        'success': true,
        'uid': cred.user!.uid,
        'data': doc.data()
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _authError(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'Something went wrong.'};
    }
  }

  // Login station
  static Future<Map<String, dynamic>> loginStation({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      final doc =
          await _db.collection('stations').doc(cred.user!.uid).get();
      if (!doc.exists || doc.data()?['role'] != 'station') {
        await _auth.signOut();
        return {
          'success': false,
          'error': 'This account is not a station account.'
        };
      }
      return {
        'success': true,
        'uid': cred.user!.uid,
        'data': doc.data()
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _authError(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'Something went wrong.'};
    }
  }

  // Send password reset
  static Future<Map<String, dynamic>> sendPasswordReset(
      String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _authError(e.code)};
    }
  }

  // Sign out
  static Future<void> signOut() async => await _auth.signOut();

  static String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}