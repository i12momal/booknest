import 'package:booknest/entities/models/book_model.dart';

class Geolocation {
  final String userId;
  final String userName;
  final double latitude;
  final double longitude;
  final List<Book> books;

  Geolocation({
    required this.userId,
    required this.userName,
    required this.latitude,
    required this.longitude,
    required this.books,
  });

  factory Geolocation.fromJson(Map<String, dynamic> json) {
    return Geolocation(
      userId: json['userId'],
      userName: json['userName'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      books: (json['books'] as List? ?? [])
        .map((bookJson) => Book.fromJson(bookJson))
        .toList(),
    );
  }
}
