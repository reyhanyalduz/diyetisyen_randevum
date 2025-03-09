import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../services/appointment_service.dart';
import '../utils/constants.dart';

class AppointmentTable extends StatelessWidget {
  final List<Appointment> appointments;
  final DateTime selectedDate;
  final bool isDietitian;

  const AppointmentTable({
    Key? key,
    required this.appointments,
    required this.selectedDate,
    this.isDietitian = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appointmentService = AppointmentService();

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
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment.status),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${appointment.dateTime.hour}:${appointment.dateTime.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Durum: ${_getStatusText(appointment.status)}",
                            style: TextStyle(fontSize: 14),
                          ),
                          if (isDietitian)
                            Text(
                              "Hasta ID: ${appointment.clientId}",
                              style: TextStyle(fontSize: 14),
                            ),
                        ],
                      ),
                    ),
                    if (isDietitian)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (appointment.status == 'pending')
                            IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                try {
                                  await appointmentService
                                      .confirmAppointment(appointment.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Randevu onaylandı')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Randevu onaylanırken bir hata oluştu')),
                                  );
                                }
                              },
                            ),
                          if (appointment.status != 'cancelled')
                            IconButton(
                              icon: Icon(Icons.cancel, color: Colors.red),
                              onPressed: () async {
                                try {
                                  await appointmentService
                                      .cancelAppointment(appointment.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Randevu iptal edildi')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Randevu iptal edilirken bir hata oluştu')),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.color3.withOpacity(0.7);
      case 'confirmed':
        return Colors.green.withOpacity(0.2);
      case 'cancelled':
        return Colors.red.withOpacity(0.2);
      default:
        return AppColors.color3;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Beklemede';
      case 'confirmed':
        return 'Onaylandı';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return status;
    }
  }
}
