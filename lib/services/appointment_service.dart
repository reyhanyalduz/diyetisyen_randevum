import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appointment.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'appointments';

  // Randevu oluşturma
  Future<void> bookAppointment(
      DateTime dateTime, String clientId, String dietitianId) async {
    try {
      final appointment = Appointment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        clientId: clientId,
        dietitianId: dietitianId,
        dateTime: dateTime,
        status: 'pending',
      );

      await _firestore
          .collection(_collection)
          .doc(appointment.id)
          .set(appointment.toMap());
    } catch (e) {
      print('Error booking appointment: $e');
      throw e;
    }
  }

  // Belirli bir kullanıcının randevularını getirme
  Stream<List<Appointment>> getUserAppointments(String userId) {
    return _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Appointment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Randevu saatinin müsait olup olmadığını kontrol etme
  Future<bool> isTimeAvailable(DateTime dateTime) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('dateTime', isEqualTo: dateTime.toIso8601String())
        .get();

    return snapshot.docs.isEmpty;
  }

  // Randevu iptal etme
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _firestore.collection(_collection).doc(appointmentId).update({
        'status': 'cancelled',
      });
    } catch (e) {
      print('Error cancelling appointment: $e');
      throw e;
    }
  }

  // Randevu onaylama (diyetisyen için)
  Future<void> confirmAppointment(String appointmentId) async {
    try {
      await _firestore.collection(_collection).doc(appointmentId).update({
        'status': 'confirmed',
      });
    } catch (e) {
      print('Error confirming appointment: $e');
      throw e;
    }
  }

  Stream<List<Appointment>> getDietitianAppointments(String dietitianId) {
    return _firestore
        .collection('appointments')
        .where('dietitianId', isEqualTo: dietitianId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Appointment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
