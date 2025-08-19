// models/event_model.dart
class EventCard {
  final String title;
  final String description;
  final String imagePath;

  const EventCard({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

// New Event class for the widget
class Event {
  final String title;
  final String description;
  final String date;
  final String location;
  final String imageUrl;

  const Event({
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.imageUrl,
  });
}