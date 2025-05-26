import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteToursScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> tourBookings;

  const FavoriteToursScreen({super.key, required this.tourBookings});

  @override
  State<FavoriteToursScreen> createState() => _FavoriteToursScreenState();
}

class _FavoriteToursScreenState extends State<FavoriteToursScreen> {
  List<Map<String, dynamic>> favoriteTours = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteTours();
  }

  Future<void> _loadFavoriteTours() async {
    Map<String, int> tourCount = {};

    for (var booking in widget.tourBookings) {
      final tourId = booking['tourId'];
      if (tourId != null) {
        tourCount[tourId] = (tourCount[tourId] ?? 0) + 1;
      }
    }

    final sortedTourIds = tourCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<Map<String, dynamic>> tours = [];

    for (var entry in sortedTourIds) {
      final tourDestination = entry.key;
      final count = entry.value;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('Tours')
          .where('destination', isEqualTo: tourDestination)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) continue;

      final tourDoc = querySnapshot.docs.first;
      final tourData = tourDoc.data();
      tourData['bookedCount'] = count;
      tourData['id'] = tourDoc.id;

      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('tourId', isEqualTo: tourDoc.id)
          .get();

      double avgRating = 0;
      if (reviewsSnapshot.docs.isNotEmpty) {
        final ratings = reviewsSnapshot.docs
            .map((doc) => (doc.data()['rating'] ?? 0).toDouble())
            .toList();

        avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
      }

      tourData['avgRating'] = avgRating;

      tours.add(tourData);
    }

    setState(() {
      favoriteTours = tours;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Любимые туры'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteTours.isEmpty
              ? const Center(child: Text('Нет данных о любимых турах'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: favoriteTours.length,
                  itemBuilder: (context, index) {
                    final tour = favoriteTours[index];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.deepPurple),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${tour['city']} → ${tour['destination']}',
                                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    '${tour['avgRating']?.toStringAsFixed(1) ?? '—'} ★',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.deepPurple,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('🏨 Отель: ${tour['hotel']}', style: textTheme.bodyMedium),
                            Text('💰 Цена: ${tour['price']} ₽', style: textTheme.bodyMedium),
                            Text('📦 Бронирований: ${tour['bookedCount']}', style: textTheme.bodyMedium),
                            const SizedBox(height: 8),
                            Text(
                              tour['description'] ?? '',
                              style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
