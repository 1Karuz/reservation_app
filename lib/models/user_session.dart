// models/user_session.dart (Updated with payment fields)

import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/app_logger.dart';

class UserSession {
  static String _email = '';
  static final List<ReservationData> _reservations = [];
  static bool _isCleared = false;

  static String get email => _email;
  static List<ReservationData> get reservations =>
      List.unmodifiable(_reservations);
  static bool get isCleared => _isCleared;

  static void setemail(String email) {
    AppLogger.debug('Setting user email in session: $email', 'SESSION');
    _email = email;
    _isCleared = false;
  }

  static void addReservation(ReservationData reservation) {
    if (!_isCleared) {
      AppLogger.debug('Adding reservation to session: ${reservation.reservationId}', 'SESSION');
      _reservations.add(reservation);
    } else {
      AppLogger.warning('Attempted to add reservation to cleared session', 'SESSION');
    }
  }

  static void removeReservation(int index) {
    if (!_isCleared && index >= 0 && index < _reservations.length) {
      final reservationId = _reservations[index].reservationId;
      AppLogger.debug('Removing reservation from session at index $index: $reservationId', 'SESSION');
      _reservations.removeAt(index);
    } else {
      AppLogger.warning('Invalid attempt to remove reservation at index $index', 'SESSION');
    }
  }

  static void clearSession() {
    AppLogger.info('Clearing user session', 'SESSION');
    _isCleared = true;
    _email = '';
    _reservations.clear();
  }

  // Method to check if session is valid
  static bool isValidSession() {
    final isValid = !_isCleared && _email.isNotEmpty;
    AppLogger.debug('Session validity check: $isValid (cleared: $_isCleared, email: ${_email.isNotEmpty ? "present" : "empty"})', 'SESSION');
    return isValid;
  }
}

class ReservationData {
  String reservationId;
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
  final List<DocumentImage> documents;
  
  // Payment fields
  final String? paymentStatus;
  final double? paymentAmount;
  final DateTime? paymentSubmittedAt;
  final List<DocumentImage>? paymentReceipts;

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
    this.documents = const [],
    this.paymentStatus,
    this.paymentAmount,
    this.paymentSubmittedAt,
    this.paymentReceipts,
  });

  factory ReservationData.fromFirestore(Map<String, dynamic> data, String id) {
    List<DocumentImage> documentsList = [];
    if (data['documents'] != null && data['documents'] is List) {
      documentsList = (data['documents'] as List)
          .map((doc) => DocumentImage.fromMap(doc as Map<String, dynamic>))
          .toList();
    }

    List<DocumentImage> receiptsList = [];
    if (data['paymentReceipts'] != null && data['paymentReceipts'] is List) {
      receiptsList = (data['paymentReceipts'] as List)
          .map((doc) => DocumentImage.fromMap(doc as Map<String, dynamic>))
          .toList();
    }

    return ReservationData(
      reservationId: id,
      userId: data['userId'] ?? '',
      eventType: data['eventType'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      contact: data['contact'] ?? '',
      date: (data['date'] is Timestamp)
          ? (data['date'] as Timestamp).toDate()
          : DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now(),
      timeFrom: data['timeFrom'] ?? '',
      timeTo: data['timeTo'] ?? '',
      comments: data['comments'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      documents: documentsList,
      paymentStatus: data['paymentStatus'],
      paymentAmount: data['paymentAmount']?.toDouble(),
      paymentSubmittedAt: data['paymentSubmittedAt'] != null 
          ? (data['paymentSubmittedAt'] as Timestamp).toDate()
          : null,
      paymentReceipts: receiptsList.isEmpty ? null : receiptsList,
    );
  }

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
      'documents': documents.map((doc) => doc.toMap()).toList(),
      'paymentStatus': paymentStatus,
      'paymentAmount': paymentAmount,
      'paymentSubmittedAt': paymentSubmittedAt,
      'paymentReceipts': paymentReceipts?.map((doc) => doc.toMap()).toList(),
    };
  }
}

class DocumentImage {
  final String name;
  final String base64Data;
  final String type; // 'camera' or 'gallery'
  final DateTime uploadedAt;

  DocumentImage({
    required this.name,
    required this.base64Data,
    required this.type,
    required this.uploadedAt,
  });

  factory DocumentImage.fromMap(Map<String, dynamic> data) {
    return DocumentImage(
      name: data['name'] ?? '',
      base64Data: data['base64Data'] ?? '',
      type: data['type'] ?? 'gallery',
      uploadedAt: (data['uploadedAt'] is Timestamp)
          ? (data['uploadedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['uploadedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'base64Data': base64Data,
      'type': type,
      'uploadedAt': uploadedAt,
    };
  }
}