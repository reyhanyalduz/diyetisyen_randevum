import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/appointment.dart';
import '../models/user.dart';
import '../screens/calendar_dietitian_screen.dart';
import '../services/appointment_service.dart';
import '../utils/constants.dart';

class CalendarScreen extends StatefulWidget {
  final AppUser currentUser;

  CalendarScreen({required this.currentUser});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Map<DateTime, List<Appointment>> _events;
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  final AppointmentService _appointmentService = AppointmentService();
  TimeOfDay _selectedTime = TimeOfDay(hour: 10, minute: 0);
  Stream<List<Appointment>>? _appointmentsStream;

  @override
  void initState() {
    super.initState();
    _events = {};
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _appointmentsStream =
        _appointmentService.getUserAppointments(widget.currentUser.uid);
    _loadAppointments();
  }

  void _loadAppointments() {
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
    if (selectedDay.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
      return;
    }

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  Future<void> _bookAppointment() async {
    DateTime appointmentTime = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    DateTime now = DateTime.now();

    // Eğer seçilen gün bugünse ve seçilen saat geçmişteyse randevuyu engelle
    if (_selectedDay.year == now.year &&
        _selectedDay.month == now.month &&
        _selectedDay.day == now.day &&
        appointmentTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Geçmiş bir saate randevu alınamaz.')),
      );
      return;
    }

    try {
      bool isAvailable =
          await _appointmentService.isTimeAvailable(appointmentTime);
      if (isAvailable) {
        await _appointmentService.bookAppointment(
          appointmentTime,
          widget.currentUser.uid,
          'default_dietitian_uid', // Burayı gerçek diyetisyen UID'si ile değiştirin
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Randevu başarıyla oluşturuldu')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bu zaman dilimi uygun değil.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Randevu oluşturulurken bir hata oluştu')),
      );
    }
  }

  void _onDateSelected(DateTime date) {
    // Seçilen tarih ile ilgili işlemler
    print('Selected date: $date');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Takvim')),
      body: (widget.currentUser.userType == UserType.client)
          ? StreamBuilder<List<Appointment>>(
              stream: _appointmentsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Bir hata oluştu'));
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        onDaySelected: _onDaySelected,
                        eventLoader: (day) => _events[day] ?? [],
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            if (day.isBefore(DateTime.now())) {
                              return Container(
                                child: Center(
                                  child: Text(
                                    day.day.toString(),
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DropdownButton<String>(
                            value:
                                '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                            items: [
                              for (int hour = 10; hour <= 17; hour++)
                                if (hour != 12) ...[
                                  DropdownMenuItem<String>(
                                    value:
                                        '${hour.toString().padLeft(2, '0')}:00',
                                    child: Text(
                                        '${hour.toString().padLeft(2, '0')}:00'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value:
                                        '${hour.toString().padLeft(2, '0')}:20',
                                    child: Text(
                                        '${hour.toString().padLeft(2, '0')}:20'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value:
                                        '${hour.toString().padLeft(2, '0')}:40',
                                    child: Text(
                                        '${hour.toString().padLeft(2, '0')}:40'),
                                  ),
                                ],
                            ],
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                List<String> parts = newValue.split(':');
                                setState(() {
                                  _selectedTime = TimeOfDay(
                                    hour: int.parse(parts[0]),
                                    minute: int.parse(parts[1]),
                                  );
                                });
                              }
                            },
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: ElevatedButton(
                              onPressed: _bookAppointment,
                              child: Text('Randevu Al',
                                  style: TextStyle(color: Colors.white)),
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(AppColors.color1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Randevularım',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final appointment = snapshot.data![index];
                            return Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: 4.0, horizontal: 8.0),
                              padding: EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.color1),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${appointment.dateTime.day}/${appointment.dateTime.month}/${appointment.dateTime.year} ${appointment.dateTime.hour}:${appointment.dateTime.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    appointment.status,
                                    style: TextStyle(
                                      color: appointment.status == 'confirmed'
                                          ? Colors.green
                                          : appointment.status == 'cancelled'
                                              ? Colors.red
                                              : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            )
          : DietitianAppointmentPage(currentUser: widget.currentUser),
    );
  }
}
