import 'package:cloud_firestore/cloud_firestore.dart';

class DietPlan {
  final String? id;
  final String clientId;
  final String dietitianId;
  final String breakfast; // Kahvaltı
  final String lunch; // Öğle Yemeği
  final String snack; // Ara Öğün
  final String dinner; // Akşam Yemeği
  final String breakfastTime; // Kahvaltı Saati
  final String lunchTime; // Öğle Yemeği Saati
  final String snackTime; // Ara Öğün Saati
  final String dinnerTime; // Akşam Yemeği Saati
  final String notes; // Notlar alanı eklendi
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final String title;

  DietPlan({
    this.id,
    required this.clientId,
    required this.dietitianId,
    required this.breakfast,
    required this.lunch,
    required this.snack,
    required this.dinner,
    required this.breakfastTime,
    required this.lunchTime,
    required this.snackTime,
    required this.dinnerTime,
    this.notes = '', // Varsayılan boş string
    required this.createdAt,
    this.updatedAt,
    required this.title,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'dietitianId': dietitianId,
      'title':
          title.isEmpty ? 'Diyet Listesi' : title, // Boşsa varsayılan değer
      'breakfast': breakfast,
      'lunch': lunch,
      'snack': snack,
      'dinner': dinner,
      'breakfastTime': breakfastTime,
      'lunchTime': lunchTime,
      'snackTime': snackTime,
      'dinnerTime': dinnerTime,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory DietPlan.fromMap(Map<String, dynamic> map, String id) {
    return DietPlan(
      id: id,
      clientId: map['clientId'] ?? '',
      dietitianId: map['dietitianId'] ?? '',
      breakfast: map['breakfast'] ?? '',
      lunch: map['lunch'] ?? '',
      snack: map['snack'] ?? '',
      dinner: map['dinner'] ?? '',
      breakfastTime: map['breakfastTime'] ?? '',
      lunchTime: map['lunchTime'] ?? '',
      snackTime: map['snackTime'] ?? '',
      dinnerTime: map['dinnerTime'] ?? '',
      notes: map['notes'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'],
      title: map['title'] ?? 'Diyet Listesi',
    );
  }
}
