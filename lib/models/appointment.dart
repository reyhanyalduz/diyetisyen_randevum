class Appointment {
  final String id;
  final String clientId;
  final String dietitianId;
  final DateTime dateTime;
  final String status; // 'pending', 'confirmed', 'cancelled'

  Appointment({
    required this.id,
    required this.clientId,
    required this.dietitianId,
    required this.dateTime,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'dietitianId': dietitianId,
      'dateTime': dateTime.toIso8601String(),
      'status': status,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map, String id) {
    return Appointment(
      id: id,
      clientId: map['clientId'] as String,
      dietitianId: map['dietitianId'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      status: map['status'] as String,
    );
  }

  @override
  String toString() {
    return 'Appointment{id: $id, clientId: $clientId, dietitianId: $dietitianId, dateTime: $dateTime, status: $status}';
  }
}
