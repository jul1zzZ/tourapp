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

    // Подсчёт количества бронирований по каждому tourId
    for (var booking in widget.tourBookings) {
      final tourId = booking['tourId'];
      if (tourId != null) {
        tourCount[tourId] = (tourCount[tourId] ?? 0) + 1;
      }
    }

    // Сортировка по количеству
    final sortedTourIds = tourCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Загрузка информации о турах
    List<Map<String, dynamic>> tours = [];

    for (var entry in sortedTourIds) {
      final tourId = entry.key;
      final count = entry.value;

      final tourDoc = await FirebaseFirestore.instance
          .collection('Tours')
          .doc(tourId)
          .get();

      if (tourDoc.exists) {
        final tourData = tourDoc.data()!;
        tourData['bookedCount'] = count;
        tourData['id'] = tourId;
        tours.add(tourData);
      }
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
                        Text('Рейтинг: ${tour['rating']} ⭐'),
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
