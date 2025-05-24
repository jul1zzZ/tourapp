import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteToursScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> tourBookings;

  const FavoriteToursScreen({required this.tourBookings});

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
    final tourDestination = entry.key; // Здесь tourId - это название направления
    final count = entry.value;

    // Ищем документ тура по полю destination
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

    // Получаем отзывы по реальному ID тура (doc.id)
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
    return Scaffold(
      appBar: AppBar(title: Text('Любимые туры')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: favoriteTours.length,
              itemBuilder: (context, index) {
                final tour = favoriteTours[index];
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    leading: Icon(Icons.location_city),
                    title: Text('${tour['city']} (${tour['destination']})'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Отель: ${tour['hotel']}'),
                        Text('Бронирований: ${tour['bookedCount']}'),
                        Text('Цена: \$${tour['price']}'),
                        Text('Рейтинг: ${tour['avgRating']?.toStringAsFixed(1) ?? 'нет'} ⭐'),
                        Text('Описание: ${tour['description']}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
