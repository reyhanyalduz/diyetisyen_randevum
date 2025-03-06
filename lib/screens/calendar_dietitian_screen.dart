import 'package:flutter/material.dart';
import '../widgets/appointment_table_widget.dart';
import '../widgets/date_selector_widget.dart';

class DietitianAppointmentPage extends StatefulWidget {
  @override
  _DietitianAppointmentPageState createState() => _DietitianAppointmentPageState();
}

class _DietitianAppointmentPageState extends State<DietitianAppointmentPage> {
  DateTime selectedDate = DateTime.now(); // Varsayılan olarak bugünü seç
  List<Map<String, dynamic>> appointments = [
    {"date": DateTime(2024, 2, 28), "time": "10:00", "name": "User1"},
    {"date": DateTime(2024, 2, 28), "time": "10:20", "name": "User2"},
    {"date": DateTime(2024, 2, 25), "time": "10:40", "name": "User3"},
    {"date": DateTime(2024, 2, 28), "time": "11:20", "name": "User4"},
    {"date": DateTime(2024, 2, 29), "time": "11:40", "name": "User5"},
    {"date": DateTime(2024, 2, 28), "time": "14:20", "name": "User6"},
    {"date": DateTime(2024, 2, 29), "time": "14:40", "name": "User7"},
    {"date": DateTime(2024, 2, 25), "time": "17:00", "name": "User8"},
  ];

  void _onDateSelected(DateTime date) {
    setState(() {
      selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Randevu Takvimi"),),
      body: Column(
        children: [
          DateSelector(selectedDate: selectedDate,
        onDateSelected: _onDateSelected, ),
          Expanded(child: AppointmentTable(appointments: appointments,selectedDate: selectedDate,)), // Randevu tablosu
        ],
      ),
    );
  }

  // Üstteki tarih seçim bileşeni

}
