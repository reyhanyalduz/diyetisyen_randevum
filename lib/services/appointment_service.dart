import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appointment.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

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
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Appointment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Randevu saatinin müsait olup olmadığını kontrol etme
  Future<bool> isTimeAvailable(DateTime dateTime, String dietitianId) async {
    try {
      // Seçilen günün başlangıcı ve sonu
      final startOfDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      // Diyetisyenin o günkü tüm randevularını kontrol et
      final snapshot = await _firestore
          .collection(_collection)
          .where('dietitianId', isEqualTo: dietitianId)
          .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
          .where('dateTime', isLessThan: endOfDay)
          .where('isCancelled', isEqualTo: false)
          .get();

      // Aynı saatte randevu var mı kontrol et
      for (var doc in snapshot.docs) {
        final appointmentTime = (doc.data()['dateTime'] as Timestamp).toDate();
        if (appointmentTime.hour == dateTime.hour &&
            appointmentTime.minute == dateTime.minute) {
          return false; // Bu saatte randevu var
        }
      }

      return true; // Bu saatte randevu yok
    } catch (e) {
      print('Error checking time availability: $e');
      return false;
    }
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

  Future<void> addAppointment(
      Appointment appointment, String dietitianName) async {
    try {
      print('Adding appointment for date: ${appointment.dateTime}');
      final docRef =
          await _firestore.collection('appointments').add(appointment.toMap());
      print('Appointment added with ID: ${docRef.id}');

      // Sadece client'lar için bildirim ayarla
      final currentUser = await AuthService().getCurrentUser();
      if (currentUser?.userType == UserType.client) {
        print('Setting up notifications for client');
        await NotificationService().scheduleAppointmentReminder(
          appointmentId: docRef.id.hashCode,
          appointmentTime: appointment.dateTime,
          dietitianName: dietitianName,
        );
        print('Notifications scheduled successfully');
      } else {
        print('Skipping notifications - user is not a client');
      }
    } catch (e) {
      print('Error in addAppointment: $e');
      throw e;
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).delete();
      // Bildirimi iptal et
      await NotificationService().cancelNotification(appointmentId.hashCode);
    } catch (e) {
      print('Error deleting appointment: $e');
      throw e;
    }
  }
}