import 'package:cloud_firestore/cloud_firestore.dart';

class Tour {
  final String id;          // <- Добавляем id
  final String destination;
  final double price;
  final String tourType;
  final DateTime startDate;
  final DateTime endDate;
  final double rating;
  final String description;

  Tour({
    required this.id,
    required this.destination,
    required this.price,
    required this.tourType,
    required this.startDate,
    required this.endDate,
    required this.rating,
    required this.description,
  });

  factory Tour.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Tour(
      id: doc.id,   // <- получаем id документа
      destination: data['destination'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      tourType: data['tourType'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      rating: (data['rating'] ?? 0).toDouble(),
      description: data['description'] ?? '',
    );
  }

  Tour copyWith({
    String? id,
    String? destination,
    double? price,
    String? tourType,
    DateTime? startDate,
    DateTime? endDate,
    double? rating,
    String? description,
  }) {
    return Tour(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      price: price ?? this.price,
      tourType: tourType ?? this.tourType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rating: rating ?? this.rating,
      description: description ?? this.description,
    );
  }
}
