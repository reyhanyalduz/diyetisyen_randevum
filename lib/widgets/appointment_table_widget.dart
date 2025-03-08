import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../utils/constants.dart';

class AppointmentTable extends StatelessWidget {
  final List<Appointment> appointments;
  final DateTime selectedDate;

  const AppointmentTable({
    Key? key,
    required this.appointments,
    required this.selectedDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 9,
      itemBuilder: (context, index) {
        final hour = 10 + index;
        List<Appointment> matchingAppointments = [];

        for (var appointment in appointments) {
          if (appointment.dateTime.day == selectedDate.day) {
            final appointmentHour = appointment.dateTime.hour;
            final appointmentMinutes = appointment.dateTime.minute;

            if (appointmentHour == hour ||
                (appointmentHour == hour - 1 && appointmentMinutes >= 59)) {
              matchingAppointments.add(appointment);
            }
          }
        }

        return Column(
          children: [
            // Saat başlığı
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color.fromARGB(255, 243, 243, 243),
              width: double.infinity,
              child: Text(
                "$hour:00",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // O saat aralığına ait randevular
            ...matchingAppointments.map((appointment) {
              return Container(
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.color3,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${appointment.dateTime.hour}:${appointment.dateTime.minute.toString().padLeft(2, '0')} - ${appointment.status}",
                  style: TextStyle(fontSize: 16),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
