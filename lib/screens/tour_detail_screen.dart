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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalPrice = tour.basePrice * touristsCount;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        elevation: 1,
        title: Text(
          tour.title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  tour.imageUrl,
                  height: 240,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),

              // Заголовок + рейтинг
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tour.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  TourRatingWidget(tourId: tour.id),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                '${tour.city}, ${tour.destination}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tour.category,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                tour.description.isNotEmpty
                    ? tour.description
                    : 'Описание отсутствует',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),

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
                icon: Icons.star,
                label: 'Отель',
                value: '${tour.hotel.stars} ★, питание: ${tour.hotel.meals}',
              ),
              const SizedBox(height: 24),

              if (tour.hotel.lat != null && tour.hotel.lng != null) ...[
                Text(
                  'Отель: ${tour.hotel.name}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 200,
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
                const SizedBox(height: 28),
              ],

              Center(
                child: Text(
                  'Цена за $touristsCount туристов: ${totalPrice.toStringAsFixed(0)} ₽',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              FilledButton.icon(
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Забронировать'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                            userEmail: userEmail,
                          ),
                    ),
                  );
                },
              ),
            ],
          ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 28),
          const SizedBox(width: 16),
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
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
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<double>(
      future: _fetchAverageRating(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('...');
        }
        if (snapshot.hasError) {
          return Text(
            'Ошибка',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
          );
        }

        final avg = snapshot.data ?? 0;

        if (avg == 0) {
          return Text(
            'Нет оценок',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          );
        }

        return Row(
          children: [
            const Icon(Icons.star, size: 20, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              avg.toStringAsFixed(1),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.amber,
              ),
            ),
          ],
        );
      },
    );
  }
}
