import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/tour.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/book_tour_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TourDetailScreen extends StatelessWidget {
  final Tour tour;
  final int touristsCount;

  const TourDetailScreen({
    super.key,
    required this.tour,
    required this.touristsCount,
  });

  @override
  Widget build(BuildContext context) {
    final totalPrice = tour.basePrice * touristsCount;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        title: Text(
          tour.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Картинка с плавными скруглениями
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                tour.imageUrl,
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),

            // Заголовок и рейтинг
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    tour.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
                TourRatingWidget(tourId: tour.id),
              ],
            ),
            const SizedBox(height: 6),

            // Город и направление
            Text(
              '${tour.city}, ${tour.destination}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Категория в виде яркой метки
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tour.category,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),

            // Описание
            Text(
              tour.description.isNotEmpty
                  ? tour.description
                  : 'Описание отсутствует',
              style: const TextStyle(
                fontSize: 17,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 28),

            // Информация по ночам, рейсам и отелю в карточках
            _InfoCard(
              icon: Icons.hotel,
              label: 'Ночи',
              value: 'от ${tour.minNights} до ${tour.maxNights}',
            ),
            const SizedBox(height: 14),
            _InfoCard(
              icon: Icons.flight,
              label: 'Рейс',
              value:
                  '${tour.flightAirline} (${tour.flightFrom} → ${tour.flightTo})',
            ),
            const SizedBox(height: 14),
            _InfoCard(
              icon: Icons.star_rate,
              label: 'Отель',
              value: '${tour.hotel.stars} ⭐, питание: ${tour.hotel.meals}',
            ),

            if (tour.hotel.lat != null && tour.hotel.lng != null) ...[
              const SizedBox(height: 24),
              Text(
                'Отель: ${tour.hotel.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(tour.hotel.lat!, tour.hotel.lng!),
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName:
                            'com.example.flutter_application_1',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(tour.hotel.lat!, tour.hotel.lng!),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.redAccent,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Цена и кнопка бронирования
            Center(
              child: Text(
                'Цена за $touristsCount туристов: ${totalPrice.toStringAsFixed(0)} ₽',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.teal[700],
                ),
              ),
            ),

            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: Colors.tealAccent.withOpacity(0.4),
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
                            userEmail: userEmail,
                          ),
                    ),
                  );
                },
                child: const Text(
                  'Забронировать',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 28),
          const SizedBox(width: 16),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.teal,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class TourRatingWidget extends StatelessWidget {
  final String tourId;

  const TourRatingWidget({required this.tourId, super.key});

  Future<double> _fetchAverageRating() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('Reviews')
            .where('tourId', isEqualTo: tourId)
            .get();

    if (snapshot.docs.isEmpty) return 0;

    final ratings =
        snapshot.docs.map((doc) => (doc.data()['rating'] ?? 0) as int).toList();

    final average = ratings.reduce((a, b) => a + b) / ratings.length;
    return average;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: _fetchAverageRating(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: const [
              Icon(Icons.star, color: Colors.grey, size: 20),
              SizedBox(width: 6),
              Text(
                'Загрузка...',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          );
        }
        if (snapshot.hasError) {
          return const Text(
            'Ошибка загрузки рейтинга',
            style: TextStyle(color: Colors.redAccent),
          );
        }

        final averageRating = snapshot.data ?? 0;

        if (averageRating == 0) {
          return const Text(
            'Рейтинг отсутствует',
            style: TextStyle(color: Colors.grey),
          );
        }

        return Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 6),
            Text(
              '${averageRating.toStringAsFixed(1)} ★',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.amber,
                fontSize: 16,
              ),
            ),
          ],
        );
      },
    );
  }
}
