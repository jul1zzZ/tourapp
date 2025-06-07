import 'package:cloud_firestore/cloud_firestore.dart';

class Hotel {
  final String name;
  final String meals;
  final double rating;
  final int stars;
  final double? lat; // добавлено
  final double? lng; // добавлено

  Hotel({
    required this.name,
    required this.meals,
    required this.rating,
    required this.stars,
    this.lat,
    this.lng,
  });

  factory Hotel.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return Hotel(name: '', meals: '', rating: 0, stars: 0);
    }
    final location = map['location'] as Map<String, dynamic>?;

    return Hotel(
      name: map['name'] ?? '',
      meals: map['meals'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      stars: map['stars'] ?? 0,
      lat: location != null ? (location['lat']?.toDouble()) : null,
      lng: location != null ? (location['lng']?.toDouble()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'meals': meals,
      'rating': rating,
      'stars': stars,
      'location': lat != null && lng != null ? {'lat': lat, 'lng': lng} : null,
    };
  }
}

class Tour {
  final String id;
  final String title;
  final String city;
  final String category;
  final double basePrice;
  final Hotel hotel; // Объект Hotel
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

  // Новые поля
  final int minNights;
  final int maxNights;

  Tour({
    required this.id,
    required this.title,
    required this.city,
    required this.category,
    required this.basePrice,
    required this.hotel,
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
      hotel: Hotel.fromMap(data['hotel']),
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
      minNights: data['minNights'] ?? 0,
      maxNights: data['maxNights'] ?? 0,
    );
  }

  Tour copyWith({
    String? id,
    String? title,
    String? city,
    String? category,
    double? basePrice,
    Hotel? hotel,
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
      hotel: hotel ?? this.hotel,
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
