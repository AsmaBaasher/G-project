import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save user data
  Future<void> saveUserData(String uid, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(uid).set(userData);
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Create ride request
  Future<void> createRideRequest(Map<String, dynamic> requestData) async {
    try {
      await _firestore.collection('ride_requests').add(requestData);
    } catch (e) {
      print('Error creating ride request: $e');
    }
  }

  // Get ride requests
  Stream<QuerySnapshot> getRideRequests() {
    return _firestore
        .collection('ride_requests')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Update ride request status
  Future<void> updateRideRequestStatus(
      String requestId, String status) async {
    try {
      await _firestore
          .collection('ride_requests')
          .doc(requestId)
          .update({'status': status});
    } catch (e) {
      print('Error updating ride request status: $e');
    }
  }
} 