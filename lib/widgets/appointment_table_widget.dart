import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/client_service.dart';

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
    final clientService = ClientService();
    final Map<String, String> _clientNameCache = {};

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
              return FutureBuilder<String>(
                  future: _getClientName(
                      appointment.clientId, clientService, _clientNameCache),
                  builder: (context, snapshot) {
                    final clientName =
                        snapshot.connectionState == ConnectionState.done
                            ? snapshot.data ?? 'Yükleniyor...'
                            : 'Yükleniyor...';

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                                  "Danışan: $clientName",
                                  style: TextStyle(fontSize: 14),
                                ),
                                if (appointment.isCancelled) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    appointment.cancelledBy == 'dietitian'
                                        ? "Diyetisyen tarafından iptal edildi"
                                        : "Danışan tarafından iptal edildi",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.red,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isDietitian && !appointment.isCancelled)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Randevu İptali'),
                                        content: Text(
                                            'Bu randevuyu iptal etmek istediğinize emin misiniz?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text('Vazgeç'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text('İptal Et'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true) {
                                      try {
                                        if (appointment.id != null) {
                                          await FirebaseFirestore.instance
                                              .collection('appointments')
                                              .doc(appointment.id!)
                                              .update({
                                            'isCancelled': true,
                                            'cancelledBy': 'dietitian',
                                          });
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Randevu iptal edildi')),
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Randevu iptal edilirken bir hata oluştu')),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  });
            }).toList(),
          ],
        );
      },
    );
  }

  Future<String> _getClientName(String clientId, ClientService clientService,
      Map<String, String> _clientNameCache) async {
    if (_clientNameCache.containsKey(clientId)) {
      return _clientNameCache[clientId]!;
    }

    try {
      final client = await clientService.getClientById(clientId);
      final name = client?.name ?? 'Bilinmeyen Hasta';

      _clientNameCache[clientId] = name;
      return name;
    } catch (e) {
      print('Error fetching client name: $e');
      return 'Bilinmeyen Hasta';
    }
  }
}
