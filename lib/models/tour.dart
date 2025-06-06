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
  final double rating;
  final String destination;
  final String tourType;
  final DateTime startDate;
  final DateTime endDate;
  final String description;

  // Добавляем новые поля
  final int minNights;
  final int maxNights;

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
    required this.rating,
    required this.destination,
    required this.tourType,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.minNights,
    required this.maxNights,
  });

  double get price => basePrice;

  factory Tour.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    Timestamp? startTimestamp = data['startDate'] as Timestamp?;
    Timestamp? endTimestamp = data['endDate'] as Timestamp?;

    return Tour(
      id: doc.id,
      title: data['title'] ?? '',
      city: data['city'] ?? '',
      category: data['category'] ?? '',
      basePrice: (data['basePrice'] ?? 0).toDouble(),
      hotelStars: (data['hotel']?['stars'] ?? 0),
      hotelMeals: data['hotel']?['meals'] ?? '',
      hotelRating: (data['hotel']?['rating'] ?? 0).toDouble(),
      flightAirline: data['flight']?['airline'] ?? '',
      flightFrom: data['flight']?['from'] ?? '',
      flightTo: data['flight']?['to'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      destination: data['destination'] ?? '',
      tourType: data['tourType'] ?? '',
      startDate:
          startTimestamp != null ? startTimestamp.toDate() : DateTime.now(),
      endDate: endTimestamp != null ? endTimestamp.toDate() : DateTime.now(),
      description: data['description'] ?? '',
      minNights: data['minNights'] ?? 0, // Новые поля
      maxNights: data['maxNights'] ?? 0,
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
    double? rating,
    String? destination,
    String? tourType,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    int? minNights,
    int? maxNights,
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
      rating: rating ?? this.rating,
      destination: destination ?? this.destination,
      tourType: tourType ?? this.tourType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      minNights: minNights ?? this.minNights,
      maxNights: maxNights ?? this.maxNights,
    );
  }
}
