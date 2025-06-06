import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/tour.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/book_tour_screen.dart';

class TourDetailScreen extends StatelessWidget {
  final Tour tour;
  final int touristsCount; // добавляем количество туристов

  const TourDetailScreen({
    super.key,
    required this.tour,
    required this.touristsCount,
  });

  @override
  Widget build(BuildContext context) {
    final totalPrice = tour.basePrice * touristsCount; // считаем итоговую цену

    return Scaffold(
      appBar: AppBar(title: Text(tour.title), backgroundColor: Colors.teal),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 250,
              child: Image.network(tour.imageUrl, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Название и рейтинг
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tour.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(tour.rating.toString()),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Город и страна
                  Text(
                    '${tour.city}, ${tour.destination}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),

                  const SizedBox(height: 16),

                  // Категория тура
                  Chip(
                    label: Text(
                      tour.category,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.teal,
                  ),

                  const SizedBox(height: 16),

                  // Описание
                  Text(
                    tour.description.isNotEmpty
                        ? tour.description
                        : 'Описание отсутствует',
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 24),

                  // Информация о ночах
                  Row(
                    children: [
                      const Icon(Icons.hotel, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        'Ночи: от ${tour.minNights} до ${tour.maxNights}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Информация о перелёте
                  Row(
                    children: [
                      const Icon(Icons.flight, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Рейс: ${tour.flightAirline} (${tour.flightFrom} → ${tour.flightTo})',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Информация о гостинице
                  Row(
                    children: [
                      const Icon(Icons.star_rate, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        'Отель: ${tour.hotelStars} звезд, питание: ${tour.hotelMeals}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Итоговая цена с учетом количества туристов
                  Center(
                    child: Text(
                      'Цена за $touristsCount туристов: ${totalPrice.toStringAsFixed(0)} ₽',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Кнопка бронирования
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        final userEmail =
                            FirebaseAuth.instance.currentUser?.email ?? '';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => BookingScreen(
                                  tour: tour,
                                  touristsCount: touristsCount,
                                  userEmail:
                                      userEmail, // теперь userEmail определён
                                ),
                          ),
                        );
                      },

                      child: const Text(
                        'Забронировать',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
