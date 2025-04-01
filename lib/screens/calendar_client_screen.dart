import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import '../screens/calendar_dietitian_screen.dart';
import '../services/appointment_service.dart';
import '../services/dietitian_service.dart';
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
  final DietitianService _dietitianService = DietitianService();
  final Map<String, String> _dietitianNameCache = {};
  Set<String> _bookedTimeSlots = {};

  @override
  void initState() {
    super.initState();
    _events = {};
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();

    // İlk yükleme işlemlerini başlat
    _initializeData();
    // Seçili gün için dolu randevuları yükle
    _loadBookedTimeSlots(_selectedDay);
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
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);

        // Bugün ve sonrasındaki randevuları filtrele ve tarihe göre sırala
        final filteredAndSortedAppointments = appointments
            .where((appointment) => appointment.dateTime
                .isAfter(startOfToday.subtract(Duration(seconds: 1))))
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

        setState(() {
          _appointments = filteredAndSortedAppointments;
          _events = {};
          for (var appointment in _appointments) {
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

    // Seçili gün için dolu randevuları getir
    _loadBookedTimeSlots(selectedDay);
  }

  Future<void> _loadBookedTimeSlots(DateTime selectedDay) async {
    if (_updatedClient?.dietitianUid == null) {
      print('No dietitian assigned to client');
      return;
    }

    try {
      final startOfDay =
          DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      print(
          'Loading booked slots for dietitian: ${_updatedClient!.dietitianUid}');
      print('Date range: ${startOfDay} to ${endOfDay}');

      // Diyetisyenin tüm randevularını al
      final querySnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('dietitianId', isEqualTo: _updatedClient!.dietitianUid)
          .where('isCancelled', isEqualTo: false)
          .get();

      print('Total appointments for dietitian: ${querySnapshot.docs.length}');

      setState(() {
        _bookedTimeSlots = querySnapshot.docs
            .map((doc) {
              final DateTime dateTime =
                  (doc.data()['dateTime'] as Timestamp).toDate();
              // Sadece seçili güne ait randevuları al
              if (dateTime.year == selectedDay.year &&
                  dateTime.month == selectedDay.month &&
                  dateTime.day == selectedDay.day) {
                final timeString =
                    '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                print(
                    'Found booked slot: $timeString for date: ${dateTime.toString()}');
                return timeString;
              }
              return null;
            })
            .where((timeString) => timeString != null)
            .cast<String>()
            .toSet();
      });

      print('Total booked slots for selected day: ${_bookedTimeSlots.length}');
      print('Booked slots: $_bookedTimeSlots');
    } catch (e) {
      print('Error loading booked time slots: $e');
    }
  }

  Future<void> _bookAppointment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Client client = _updatedClient ?? (widget.currentUser as Client);

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

      bool isAvailable = await _appointmentService.isTimeAvailable(
          appointmentTime, dietitianId);
      print(
          'Time availability check for ${appointmentTime.toString()}: $isAvailable');
      if (isAvailable) {
        // Diyetisyen adını al
        String dietitianName = await _getDietitianName(dietitianId);

        // Yeni randevu oluştur
        final appointment = Appointment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          clientId: client.uid,
          dietitianId: dietitianId,
          dateTime: appointmentTime,
        );

        // addAppointment metodunu kullan (bu metod bildirimleri de ayarlayacak)
        await _appointmentService.addAppointment(appointment, dietitianName);

        // Sayfayı yenile
        await _initializeData();
        // Dolu randevuları güncelle
        await _loadBookedTimeSlots(_selectedDay);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Randevu başarıyla oluşturuldu')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bu zaman dilimi uygun değil.')),
        );
      }
    } catch (e) {
      print('Randevu oluşturma hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Randevu oluşturulurken bir hata oluştu: $e')),
      );
    } finally {
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

  // Diyetisyen adını getiren yardımcı metod
  Future<String> _getDietitianName(String? dietitianId) async {
    if (dietitianId == null) {
      return 'Diyetisyen atanmamış';
    }

    // Önbellekte varsa oradan döndür
    if (_dietitianNameCache.containsKey(dietitianId)) {
      return _dietitianNameCache[dietitianId]!;
    }

    try {
      final dietitian = await _dietitianService.getDietitianById(dietitianId);
      final name = dietitian?.name ?? 'Bilinmeyen Diyetisyen';

      // Önbelleğe ekle
      _dietitianNameCache[dietitianId] = name;
      return name;
    } catch (e) {
      print('Error fetching dietitian name: $e');
      return 'Bilinmeyen Diyetisyen';
    }
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
                      _buildTimeDropdown(),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton(
                          onPressed: _isLoading || !hasDietitian
                              ? () => _showNoDietitianDialog()
                              : _bookAppointment,
                          child: Text('Randevu Al',
                              style: TextStyle(color: Colors.white)),
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              hasDietitian ? AppColors.color1 : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hasDietitian)
                    FutureBuilder<String>(
                        future: _getDietitianName(_updatedClient?.dietitianUid),
                        builder: (context, snapshot) {
                          final dietitianName =
                              snapshot.connectionState == ConnectionState.done
                                  ? snapshot.data ?? 'Yükleniyor...'
                                  : 'Yükleniyor...';

                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Diyetisyen: $dietitianName',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        }),
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
                        return _buildAppointmentCard(appointment);
                      },
                    ),
                  ],
                  SizedBox(height: 50),
                ],
              ),
            ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final isTextFaded = appointment.isCancelled;
    final textColor = isTextFaded ? Colors.grey : Colors.black;

    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMMM yyyy, HH:mm')
                      .format(appointment.dateTime),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                if (!appointment.isCancelled)
                  TextButton(
                    onPressed: () => _cancelAppointment(appointment),
                    child: Text(
                      'İptal Et',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: Size(80, 36),
                    ),
                  ),
              ],
            ),
            if (appointment.isCancelled) ...[
              SizedBox(height: 8),
              Text(
                appointment.cancelledBy == 'client'
                    ? 'Bu randevuyu iptal ettiniz'
                    : 'Diyetisyeniniz bu randevuyu iptal etti',
                style: TextStyle(
                  color: Colors.red[300],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Randevu İptali'),
        content: Text('Randevuyu iptal etmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('İptal Et'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(appointment.id)
            .update({
          'isCancelled': true,
          'cancelledBy': 'client',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Randevu başarıyla iptal edildi')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Randevu iptal edilirken bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTimeDropdown() {
    List<DropdownMenuItem<String>> items = [];

    print('Building dropdown with booked slots: $_bookedTimeSlots');

    for (int hour = 10; hour <= 17; hour++) {
      if (hour != 12) {
        for (var minute in [0, 20, 40]) {
          final timeString =
              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          final isBooked = _bookedTimeSlots.contains(timeString);
          final now = DateTime.now();
          final selectedDateTime = DateTime(
            _selectedDay.year,
            _selectedDay.month,
            _selectedDay.day,
            hour,
            minute,
          );
          final isPast = selectedDateTime.isBefore(now);

          print('Checking time slot: $timeString');
          print('isBooked: $isBooked');
          print('isPast: $isPast');
          print('selectedDateTime: $selectedDateTime');
          print('now: $now');

          items.add(DropdownMenuItem<String>(
            value: timeString,
            enabled: !isBooked && !isPast,
            child: Text(
              timeString,
              style: TextStyle(
                color: isBooked || isPast ? Colors.grey[400] : Colors.black,
                fontWeight: isBooked ? FontWeight.bold : FontWeight.normal,
                decoration:
                    isBooked ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
          ));
        }
      }
    }

    return DropdownButton<String>(
      value:
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
      items: items,
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
    );
  }

  @override
  void dispose() {
    // Bellek sızıntılarını önlemek için stream'leri kapat
    super.dispose();
  }
}
