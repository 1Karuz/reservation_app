// models/user_session.dart
class UserSession {
  static String _username = '';
  static final List<ReservationData> _reservations = [];

  static String get username => _username;
  static List<ReservationData> get reservations => List.unmodifiable(_reservations);

  static void setUsername(String username) {
    _username = username;
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
    _username = '';
    _reservations.clear();
  }
}

class ReservationData {
  final String eventType;
  final String name;
  final String email;
  final String date;
  final String contact;
  final String comments;
  final DateTime timestamp;

  ReservationData({
    required this.eventType,
    required this.name,
    required this.email,
    required this.date,
    required this.contact,
    required this.comments,
  }) : timestamp = DateTime.now();
}