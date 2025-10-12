// models/user_session.dart

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
  
  // Wedding-specific fields
  final String? groomName;
  final String? groomFather;
  final String? groomMother;
  final String? brideName;
  final String? brideFather;
  final String? brideMother;
  
  // Baptism-specific fields
  final String? childName;
  final String? childBirthdate;
  final String? childBirthplace;
  final String? fatherName;
  final String? motherMaidenName;
  final String? parentMarriageType;
  final String? sponsors;
  
  // Funeral-specific fields
  final String? deceasedName;
  final String? deceasedAge;
  final String? deathDate;
  final String? burialDate;
  final String? residence;
  final String? causeOfDeath;
  final bool? wasBaptized;
  final bool? receivedLastSacrament;
  final String? guardianName;
  final String? burialPlace;
  
  // House Blessing-specific fields
  final String? homeownerName;
  final String? houseAddress;
  
  // Confession-specific fields
  final String? personName;
  final String? notes;

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
    // Wedding fields
    this.groomName,
    this.groomFather,
    this.groomMother,
    this.brideName,
    this.brideFather,
    this.brideMother,
    // Baptism fields
    this.childName,
    this.childBirthdate,
    this.childBirthplace,
    this.fatherName,
    this.motherMaidenName,
    this.parentMarriageType,
    this.sponsors,
    // Funeral fields
    this.deceasedName,
    this.deceasedAge,
    this.deathDate,
    this.burialDate,
    this.residence,
    this.causeOfDeath,
    this.wasBaptized,
    this.receivedLastSacrament,
    this.guardianName,
    this.burialPlace,
    // House Blessing fields
    this.homeownerName,
    this.houseAddress,
    // Confession fields
    this.personName,
    this.notes,
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
      // Wedding fields
      groomName: data['groomName'],
      groomFather: data['groomFather'],
      groomMother: data['groomMother'],
      brideName: data['brideName'],
      brideFather: data['brideFather'],
      brideMother: data['brideMother'],
      // Baptism fields
      childName: data['childName'],
      childBirthdate: data['childBirthdate'],
      childBirthplace: data['childBirthplace'],
      fatherName: data['fatherName'],
      motherMaidenName: data['motherMaidenName'],
      parentMarriageType: data['parentMarriageType'],
      sponsors: data['sponsors'],
      // Funeral fields
      deceasedName: data['deceasedName'],
      deceasedAge: data['deceasedAge'],
      deathDate: data['deathDate'],
      burialDate: data['burialDate'],
      residence: data['residence'],
      causeOfDeath: data['causeOfDeath'],
      wasBaptized: data['wasBaptized'],
      receivedLastSacrament: data['receivedLastSacrament'],
      guardianName: data['guardianName'],
      burialPlace: data['burialPlace'],
      // House Blessing fields
      homeownerName: data['homeownerName'],
      houseAddress: data['houseAddress'],
      // Confession fields
      personName: data['personName'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
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
    
    // Add event-specific fields only if they're not null
    if (groomName != null) map['groomName'] = groomName;
    if (groomFather != null) map['groomFather'] = groomFather;
    if (groomMother != null) map['groomMother'] = groomMother;
    if (brideName != null) map['brideName'] = brideName;
    if (brideFather != null) map['brideFather'] = brideFather;
    if (brideMother != null) map['brideMother'] = brideMother;
    
    if (childName != null) map['childName'] = childName;
    if (childBirthdate != null) map['childBirthdate'] = childBirthdate;
    if (childBirthplace != null) map['childBirthplace'] = childBirthplace;
    if (fatherName != null) map['fatherName'] = fatherName;
    if (motherMaidenName != null) map['motherMaidenName'] = motherMaidenName;
    if (parentMarriageType != null) map['parentMarriageType'] = parentMarriageType;
    if (sponsors != null) map['sponsors'] = sponsors;
    
    if (deceasedName != null) map['deceasedName'] = deceasedName;
    if (deceasedAge != null) map['deceasedAge'] = deceasedAge;
    if (deathDate != null) map['deathDate'] = deathDate;
    if (burialDate != null) map['burialDate'] = burialDate;
    if (residence != null) map['residence'] = residence;
    if (causeOfDeath != null) map['causeOfDeath'] = causeOfDeath;
    if (wasBaptized != null) map['wasBaptized'] = wasBaptized;
    if (receivedLastSacrament != null) map['receivedLastSacrament'] = receivedLastSacrament;
    if (guardianName != null) map['guardianName'] = guardianName;
    if (burialPlace != null) map['burialPlace'] = burialPlace;
    
    if (homeownerName != null) map['homeownerName'] = homeownerName;
    if (houseAddress != null) map['houseAddress'] = houseAddress;
    
    if (personName != null) map['personName'] = personName;
    if (notes != null) map['notes'] = notes;
    
    return map;
  }
}

class DocumentImage {
  final String name;
  final String base64Data;
  final String type;
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