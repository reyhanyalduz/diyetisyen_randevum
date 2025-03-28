import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/diet_plan.dart';

class DietPlanService {
  static final DietPlanService _instance = DietPlanService._internal();
  factory DietPlanService() => _instance;
  DietPlanService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<DietPlan>> getDietPlansForClient(String clientId) async {
    final snapshot = await _firestore
        .collection('dietplans')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => DietPlan.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<String> addDietPlan(DietPlan dietPlan) async {
    final docRef =
        await _firestore.collection('dietplans').add(dietPlan.toMap());
    return docRef.id;
  }

  Future<void> updateDietPlan(DietPlan dietPlan) async {
    if (dietPlan.id == null) {
      throw Exception('Diet plan ID cannot be null for update operation');
    }

    await _firestore.collection('dietplans').doc(dietPlan.id).update({
      'title': dietPlan.title,
      'breakfast': dietPlan.breakfast,
      'lunch': dietPlan.lunch,
      'snack': dietPlan.snack,
      'dinner': dietPlan.dinner,
      'breakfastTime': dietPlan.breakfastTime,
      'lunchTime': dietPlan.lunchTime,
      'snackTime': dietPlan.snackTime,
      'dinnerTime': dietPlan.dinnerTime,
      'notes': dietPlan.notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDietPlan(String dietPlanId) async {
    await _firestore.collection('dietplans').doc(dietPlanId).delete();
  }

  Future<DocumentSnapshot> getDietPlan(String clientId) async {
    final querySnapshot = await _firestore
        .collection('dietplans')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Diet plan not found');
    }

    return querySnapshot.docs.first;
  }
}
