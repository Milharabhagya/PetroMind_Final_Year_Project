import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _role = 'customer';

  String get firstName => _firstName;
  String get lastName => _lastName;
  String get email => _email;
  String get role => _role;

  Future<void> loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _firstName = data['firstName'] ?? '';
        _lastName = data['lastName'] ?? '';
        _email = data['email'] ?? user.email ?? '';
        _role = 'customer';
        notifyListeners();
      }
    } catch (e) {}
  }

  Future<void> loadStationData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final doc = await _db
          .collection('stations')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _firstName = data['firstName'] ?? '';
        _lastName = data['lastName'] ?? '';
        _email = data['email'] ?? user.email ?? '';
        _role = 'station';
        notifyListeners();
      }
    } catch (e) {}
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      final collection = _role == 'station' ? 'stations' : 'users';
      await _db.collection(collection).doc(user.uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
      });
      if (email != user.email) {
        await user.updateEmail(email);
      }
      _firstName = firstName;
      _lastName = lastName;
      _email = email;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _firstName = '';
    _lastName = '';
    _email = '';
    _role = 'customer';
    notifyListeners();
  }
}