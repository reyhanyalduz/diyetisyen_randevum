import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/appointment.dart';
import '../models/user.dart';
import '../services/appointment_service.dart';
import '../utils/constants.dart';

class DietitianAppointmentPage extends StatefulWidget {
  final AppUser currentUser;

  DietitianAppointmentPage({required this.currentUser});

  @override
  _DietitianAppointmentPageState createState() =>
      _DietitianAppointmentPageState();
}

class _DietitianAppointmentPageState extends State<DietitianAppointmentPage> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  final AppointmentService _appointmentService = AppointmentService();
  Stream<List<Appointment>>? _appointmentsStream;
  Map<DateTime, List<Appointment>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _loadAppointments();
  }

  void _loadAppointments() {
    _appointmentsStream =
        _appointmentService.getDietitianAppointments(widget.currentUser.uid);
    _appointmentsStream?.listen((appointments) {
      setState(() {
        _events = {};
        for (var appointment in appointments) {
          final date = DateTime(
            appointment.dateTime.year,
            appointment.dateTime.month,
            appointment.dateTime.day,
          );
          _events[date] = [...(_events[date] ?? []), appointment];
        }
      });
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  Future<void> _confirmAppointment(String appointmentId) async {
    try {
      await _appointmentService.confirmAppointment(appointmentId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Randevu onaylandı')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Randevu onaylanırken bir hata oluştu')),
      );
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      await _appointmentService.cancelAppointment(appointmentId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Randevu iptal edildi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Randevu iptal edilirken bir hata oluştu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Randevu Takvimi")),
      body: StreamBuilder<List<Appointment>>(
        stream: _appointmentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }

          List<Appointment> todaysAppointments = [];
          if (snapshot.hasData) {
            todaysAppointments = snapshot.data!.where((appointment) {
              return appointment.dateTime.year == _selectedDay.year &&
                  appointment.dateTime.month == _selectedDay.month &&
                  appointment.dateTime.day == _selectedDay.day;
            }).toList();

            // Randevuları saate göre sırala
            todaysAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          }

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: _onDaySelected,
                eventLoader: (day) =>
                    _events[DateTime(day.year, day.month, day.day)] ?? [],
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: AppColors.color1,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: todaysAppointments.isEmpty
                    ? Center(child: Text('Bu tarihte randevu bulunmamaktadır'))
                    : ListView.builder(
                        itemCount: todaysAppointments.length,
                        itemBuilder: (context, index) {
                          final appointment = todaysAppointments[index];
                          return Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(
                                '${DateFormat('HH:mm').format(appointment.dateTime)}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Hasta ID: ${appointment.clientId}'),
                                  Text(
                                      'Durum: ${_getStatusText(appointment.status)}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (appointment.status == 'pending')
                                    IconButton(
                                      icon: Icon(Icons.check,
                                          color: Colors.green),
                                      onPressed: () =>
                                          _confirmAppointment(appointment.id),
                                    ),
                                  if (appointment.status != 'cancelled')
                                    IconButton(
                                      icon:
                                          Icon(Icons.cancel, color: Colors.red),
                                      onPressed: () =>
                                          _cancelAppointment(appointment.id),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
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
