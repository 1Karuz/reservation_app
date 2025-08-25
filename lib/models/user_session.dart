// models/user_session.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserSession {
  static String _email = '';
  static final List<ReservationData> _reservations = [];

  static String get email => _email;
  static List<ReservationData> get reservations =>
      List.unmodifiable(_reservations);

  static void setemail(String email) {
    _email = email;
  }

  static void addReservation(ReservationData reservation) {
    _reservations.add(reservation);
  }

  static void removeReservation(int index) {
    if (index >= 0 && index < _reservations.length) {
      _reservations.removeAt(index);
    }
  }

  static void clearSession() {
    _email = '';
    _reservations.clear();
  }
}

class ReservationData {
  String reservationId; // 🔹 not final
  final String userId;
  final String eventType;
  final String name;
  final String email;
  final String contact;
  final DateTime date;
  final String timeFrom;
  final String timeTo;
  final String comments;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReservationData({
    required this.reservationId,
    required this.userId,
    required this.eventType,
    required this.name,
    required this.email,
    required this.contact,
    required this.date,
    required this.timeFrom,
    required this.timeTo,
    required this.comments,
    this.status = "pending",
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReservationData.fromFirestore(Map<String, dynamic> data, String id) {
    return ReservationData(
      reservationId: id,
      userId: data['userId'] ?? '',
      eventType: data['eventType'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      contact: data['contact'] ?? '',
      date: (data['date'] is Timestamp)
          ? (data['date'] as Timestamp).toDate()
          : DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
      timeFrom: data['timeFrom'] ?? '',
      timeTo: data['timeTo'] ?? '',
      comments: data['comments'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // ✅ Convert ReservationData → Firestore map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventType': eventType,
      'name': name,
      'email': email,
      'contact': contact,
      'date': date,
      'timeFrom': timeFrom,
      'timeTo': timeTo,
      'comments': comments,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
