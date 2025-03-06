import '../models/appointment.dart';

class AppointmentService {
  List<Appointment> appointments = [];

  bool isTimeAvailable(DateTime dateTime) {
    Duration appointmentDuration = Duration(minutes: 20);
    DateTime endTime = dateTime.add(appointmentDuration);

    DateTime startOfDay =
        DateTime(dateTime.year, dateTime.month, dateTime.day, 10);
    DateTime endOfDay =
        DateTime(dateTime.year, dateTime.month, dateTime.day, 18);

    DateTime lunchStart =
        DateTime(dateTime.year, dateTime.month, dateTime.day, 12);
    DateTime lunchEnd =
        DateTime(dateTime.year, dateTime.month, dateTime.day, 13);

    // Geçmiş tarihler kontrolü
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    if (dateTime.isBefore(today)) {
      return false;
    }

    // Saat kontrolü
    if (dateTime.isBefore(startOfDay) ||
        endTime.isAfter(endOfDay) ||
        (dateTime.isAfter(lunchStart) && dateTime.isBefore(lunchEnd))) {
      return false;
    }

    // Çakışma kontrolü
    for (var appointment in appointments) {
      DateTime existingStart = appointment.dateTime;
      DateTime existingEnd = existingStart.add(appointmentDuration);

      if (!(endTime.isBefore(existingStart) || dateTime.isAfter(existingEnd))) {
        return false;
      }
    }

    return true;
  }

  void bookAppointment(DateTime dateTime) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    if (dateTime.isBefore(today)) {
      print('Geçmişteki günlere randevu alınamaz');
      return;
    }

    if (isTimeAvailable(dateTime)) {
      appointments.add(Appointment(dateTime));
      print('Randevu alındı: $dateTime');
    } else {
      print('Bu zaman dilimi uygun değil');
    }
  }
}
