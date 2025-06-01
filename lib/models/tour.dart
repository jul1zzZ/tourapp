import 'package:cloud_firestore/cloud_firestore.dart';

class Tour {
  final String id;
  final String title;
  final String city;
  final String category;
  final double basePrice;
  final int hotelStars;
  final String hotelMeals;
  final double hotelRating;
  final String flightAirline;
  final String flightFrom;
  final String flightTo;
  final String imageUrl;

  Tour({
    required this.id,
    required this.title,
    required this.city,
    required this.category,
    required this.basePrice,
    required this.hotelStars,
    required this.hotelMeals,
    required this.hotelRating,
    required this.flightAirline,
    required this.flightFrom,
    required this.flightTo,
    required this.imageUrl,
  });

  factory Tour.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Tour(
      id: doc.id,
      title: data['title'] ?? '',
      city: data['city'] ?? '',
      category: data['category'] ?? '',
      basePrice: (data['basePrice'] ?? 0).toDouble(),
      hotelStars: (data['hotelStars'] ?? 0),
      hotelMeals: data['hotelMeals'] ?? '',
      hotelRating: (data['hotelRating'] ?? 0).toDouble(),
      flightAirline: data['flightAirline'] ?? '',
      flightFrom: data['flightFrom'] ?? '',
      flightTo: data['flightTo'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  Tour copyWith({
    String? id,
    String? title,
    String? city,
    String? category,
    double? basePrice,
    int? hotelStars,
    String? hotelMeals,
    double? hotelRating,
    String? flightAirline,
    String? flightFrom,
    String? flightTo,
    String? imageUrl,
  }) {
    return Tour(
      id: id ?? this.id,
      title: title ?? this.title,
      city: city ?? this.city,
      category: category ?? this.category,
      basePrice: basePrice ?? this.basePrice,
      hotelStars: hotelStars ?? this.hotelStars,
      hotelMeals: hotelMeals ?? this.hotelMeals,
      hotelRating: hotelRating ?? this.hotelRating,
      flightAirline: flightAirline ?? this.flightAirline,
      flightFrom: flightFrom ?? this.flightFrom,
      flightTo: flightTo ?? this.flightTo,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
