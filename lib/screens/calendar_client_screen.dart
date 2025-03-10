import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TimeOfDay _selectedTime = TimeOfDay(hour: 10, minute: 0);
  Stream<List<Appointment>>? _appointmentsStream;
  Client? _updatedClient;
  bool _isLoading = true;
  List<Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    _events = {};
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();

    // İlk yükleme işlemlerini başlat
    _initializeData();
  }

  // Tüm veri yükleme işlemlerini tek bir yerde topla
  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Önce client verilerini yükle
      await _loadUpdatedClientData();

      // Sonra randevuları yükle
      _initializeAppointmentsStream();

      // Diyetisyen kontrolünü yap
      await _checkDietitianAssignment();
    } catch (e) {
      print('Veri yükleme hatası: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Initialize the appointments stream
  void _initializeAppointmentsStream() {
    _appointmentsStream =
        _appointmentService.getUserAppointments(widget.currentUser.uid);
    _loadAppointments();
  }

  // Load the latest client data from Firestore
  Future<void> _loadUpdatedClientData() async {
    if (widget.currentUser is Client) {
      try {
        DocumentSnapshot clientDoc = await _firestore
            .collection('clients')
            .doc(widget.currentUser.uid)
            .get();

        if (clientDoc.exists && mounted) {
          setState(() {
            _updatedClient =
                AppUser.fromMap(clientDoc.data() as Map<String, dynamic>)
                    as Client;
          });
          print('Updated client data loaded: ${_updatedClient?.dietitianUid}');
        }
      } catch (e) {
        print('Error loading updated client data: $e');
      }
    }
  }

  void _loadAppointments() {
    _appointmentsStream?.listen((appointments) {
      if (mounted) {
        setState(() {
          _appointments = appointments;
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
      }
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
    // Yükleme göstergesi göster
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the updated client data if available, otherwise fall back to the original
      Client client = _updatedClient ?? (widget.currentUser as Client);

      // Verify client has a dietitian assigned
      if (client.dietitianUid == null) {
        _showNoDietitianDialog();
        return;
      }

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

      // Get the client's assigned dietitian ID
      String dietitianId = client.dietitianUid!;
      print('Using dietitianId for appointment: $dietitianId');

      bool isAvailable =
          await _appointmentService.isTimeAvailable(appointmentTime);
      if (isAvailable) {
        await _appointmentService.bookAppointment(
          appointmentTime,
          client.uid,
          dietitianId,
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
        SnackBar(content: Text('Randevu oluşturulurken bir hata oluştu: $e')),
      );
    } finally {
      // Yükleme göstergesini kapat
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onDateSelected(DateTime date) {
    // Seçilen tarih ile ilgili işlemler
    print('Selected date: $date');
  }

  // Check if the client has a dietitian assigned
  Future<void> _checkDietitianAssignment() async {
    // Use the updated client data if available, otherwise fall back to the original
    Client client = _updatedClient ?? (widget.currentUser as Client);

    if (client.dietitianUid == null) {
      _showNoDietitianDialog();
    }
  }

  // Show dialog if no dietitian is assigned
  void _showNoDietitianDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Diyetisyen Seçilmedi'),
        content: Text(
            'Randevu oluşturabilmek için önce bir diyetisyen seçmelisiniz.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile').then((_) {
                // When returning from profile page, reload client data
                _initializeData();
              });
            },
            child: Text('Profil Sayfasına Git'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Diyetisyen kullanıcısı için farklı ekran göster
    if (widget.currentUser.userType == UserType.dietitian) {
      return DietitianAppointmentPage(currentUser: widget.currentUser);
    }

    // Client kullanıcısı için takvim ekranını göster
    bool hasDietitian = _updatedClient?.dietitianUid != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Takvim'),
        actions: [
          // Add a refresh button to manually reload client data
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading
                ? null
                : () {
                    _initializeData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bilgiler güncelleniyor...')),
                    );
                  },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Yükleniyor...'),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
                                value: '${hour.toString().padLeft(2, '0')}:00',
                                child: Text(
                                    '${hour.toString().padLeft(2, '0')}:00'),
                              ),
                              DropdownMenuItem<String>(
                                value: '${hour.toString().padLeft(2, '0')}:20',
                                child: Text(
                                    '${hour.toString().padLeft(2, '0')}:20'),
                              ),
                              DropdownMenuItem<String>(
                                value: '${hour.toString().padLeft(2, '0')}:40',
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
                          onPressed: _isLoading || !hasDietitian
                              ? () => _showNoDietitianDialog()
                              : _bookAppointment,
                          child: Text('Randevu Al',
                              style: TextStyle(color: Colors.white)),
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                              hasDietitian ? AppColors.color1 : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hasDietitian)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Diyetisyen: ${_updatedClient?.dietitianUid}',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  if (_appointments.isNotEmpty) ...[
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
                      itemCount: _appointments.length,
                      itemBuilder: (context, index) {
                        final appointment = _appointments[index];
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${appointment.dateTime.day}/${appointment.dateTime.month}/${appointment.dateTime.year} ${appointment.dateTime.hour}:${appointment.dateTime.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                _getStatusText(appointment.status),
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
            ),
    );
  }

  // Helper method to convert status to Turkish
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

  @override
  void dispose() {
    // Bellek sızıntılarını önlemek için stream'leri kapat
    super.dispose();
  }
}
