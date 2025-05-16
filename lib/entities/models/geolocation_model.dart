import 'package:booknest/entities/models/book_model.dart';

class Geolocation {
  final String userId;
  final String userName;
  final double latitude;
  final double longitude;
  final List<Book> books;
  final bool geolocationEnabled;

  Geolocation({
    required this.userId,
    required this.userName,
    required this.latitude,
    required this.longitude,
    required this.books,
    required this.geolocationEnabled,
  });

  factory Geolocation.fromJson(Map<String, dynamic> json) {
    return Geolocation(
      userId: json['userId'],
      userName: json['userName'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      books: (json['books'] as List? ?? [])
        .map((bookJson) => Book.fromJson(bookJson))
        .toList(),
      geolocationEnabled: json['geolocationEnabled'] ?? false
    );
  }
}
