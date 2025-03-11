import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import '../services/appointment_service.dart';
import '../utils/constants.dart';
import '../widgets/appointment_table_widget.dart';

class DietitianAppointmentPage extends StatefulWidget {
  final AppUser currentUser;

  DietitianAppointmentPage({required this.currentUser});

  @override
  _DietitianAppointmentPageState createState() =>
      _DietitianAppointmentPageState();
}

class _DietitianAppointmentPageState extends State<DietitianAppointmentPage> {
  late DateTime _selectedDay;
  final AppointmentService _appointmentService = AppointmentService();
  Stream<List<Appointment>>? _appointmentsStream;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadAppointments();
  }

  void _loadAppointments() {
    _appointmentsStream =
        _appointmentService.getDietitianAppointments(widget.currentUser.uid);
  }

  Widget _buildDayButton(int dayOffset) {
    final day = DateTime.now().add(Duration(days: dayOffset));
    final isSelected = day.year == _selectedDay.year &&
        day.month == _selectedDay.month &&
        day.day == _selectedDay.day;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDay = day;
        });
        _loadAppointments();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              day.day.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            Text(
              _getShortDayName(day),
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getDayName(DateTime date) {
    List<String> days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];
    // DateTime'da haftanın günü 1-7 arasında (1=Pazartesi, 7=Pazar)
    return days[date.weekday - 1];
  }

  String _getShortDayName(DateTime date) {
    List<String> days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[date.weekday - 1];
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.color1,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDay) {
      setState(() {
        _selectedDay = picked;
      });
      _loadAppointments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Randevu Takvimi")),
      body: Column(
        children: [
          // Date Picker Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDay),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: Icon(Icons.calendar_today),
                  label: Text('Tarih Seç'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.color1,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Appointment Table Section
          Expanded(
            child: StreamBuilder<List<Appointment>>(
              stream: _appointmentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text('Bir hata oluştu: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Randevu bulunmamaktadır'));
                }

                List<Appointment> appointments = snapshot.data!;

                // Filter appointments for the selected day
                List<Appointment> todaysAppointments =
                    appointments.where((appointment) {
                  return appointment.dateTime.year == _selectedDay.year &&
                      appointment.dateTime.month == _selectedDay.month &&
                      appointment.dateTime.day == _selectedDay.day;
                }).toList();

                if (todaysAppointments.isEmpty) {
                  return Center(
                      child: Text('Bu tarihte randevu bulunmamaktadır'));
                }

                // Sort appointments by time
                todaysAppointments
                    .sort((a, b) => a.dateTime.compareTo(b.dateTime));

                return AppointmentTable(
                  appointments: todaysAppointments,
                  selectedDate: _selectedDay,
                  isDietitian: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
