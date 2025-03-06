import 'package:flutter/material.dart';
import '../utils/constants.dart';


class AppointmentTable extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final DateTime selectedDate;

  const AppointmentTable( {
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
      List<Map<String, dynamic>> matchingAppointments = [];

      for (var a in appointments) {
        if (a['date'].day == selectedDate.day) {
          final timeParts = a['time'].split(':');
          final appointmentHour = int.tryParse(timeParts[0]) ?? -1;
          final appointmentMinutes = int.tryParse(timeParts[1]) ?? -1;

          if (appointmentHour == hour ||
              (appointmentHour == hour - 1 && appointmentMinutes >= 59)) {
            matchingAppointments.add(a);
          }
        }
      }

      return Column(
        children: [
          //  Saat başlığı
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color.fromARGB(255, 243, 243, 243),
            width: double.infinity,
            child: Text("$hour:00",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              child: Text("${appointment['time']} - ${appointment['name']}",
                  style: TextStyle(fontSize: 16)),
            );
          }).toList(),
        ],
      );
    },
  );
}}
