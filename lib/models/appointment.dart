import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String? id;
  final String clientId;
  final String dietitianId;
  final DateTime dateTime;
  final bool isCompleted;
  final bool isCancelled;
  final String? cancelledBy; // 'client' veya 'dietitian'

  Appointment({
    this.id,
    required this.clientId,
    required this.dietitianId,
    required this.dateTime,
    this.isCompleted = false,
    this.isCancelled = false,
    this.cancelledBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'dietitianId': dietitianId,
      'dateTime': dateTime,
      'isCompleted': isCompleted,
      'isCancelled': isCancelled,
      'cancelledBy': cancelledBy,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map, String id) {
    return Appointment(
      id: id,
      clientId: map['clientId'] ?? '',
      dietitianId: map['dietitianId'] ?? '',
      dateTime: map['dateTime'] is Timestamp
          ? (map['dateTime'] as Timestamp).toDate()
          : DateTime.parse(map['dateTime']),
      isCompleted: map['isCompleted'] ?? false,
      isCancelled: map['isCancelled'] ?? false,
      cancelledBy: map['cancelledBy'],
    );
  }

  @override
  String toString() {
    return 'Appointment{id: $id, clientId: $clientId, dietitianId: $dietitianId, dateTime: $dateTime, isCompleted: $isCompleted, isCancelled: $isCancelled, cancelledBy: $cancelledBy}';
  }
}
