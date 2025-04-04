import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';

class DietitianService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Dietitian>> getAllDietitians() async {
    final snapshot = await _firestore
        .collection('users')
        .where('userType', isEqualTo: 'dietitian')
        .get();

    return snapshot.docs
        .map((doc) => AppUser.fromMap(doc.data()) as Dietitian)
        .toList();
  }

  Future<Dietitian?> getDietitianById(String uid) async {
    final doc = await _firestore.collection('dietitians').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!) as Dietitian;
  }
}
