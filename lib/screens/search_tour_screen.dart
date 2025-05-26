import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/models/tour.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/tour_detail_screen.dart';

class SearchToursScreen extends StatefulWidget {
  @override
  _SearchToursScreenState createState() => _SearchToursScreenState();
}

class _SearchToursScreenState extends State<SearchToursScreen> {
  List<Tour> tours = [];
  List<Tour> filteredTours = [];
  List<String> tourTypes = [];

  final TextEditingController _destinationController = TextEditingController();
  String selectedType = 'Все';
  DateTime? selectedStartDate;

  double minPrice = 0;
  double maxPrice = 10000;
  double selectedMinPrice = 0;
  double selectedMaxPrice = 10000;

  double selectedMinRating = 0;

  @override
  void initState() {
    super.initState();
    _fetchTours();
  }

  Future<void> _fetchTours() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('Tours').get();

      final loadedTours = snapshot.docs.map((doc) => Tour.fromFirestore(doc)).toList();
      final tourIds = snapshot.docs.map((doc) => doc.id).toList();

      var reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('tourId', whereIn: tourIds)
          .get();

      Map<String, List<double>> ratingsMap = {};
      for (var review in reviewsSnapshot.docs) {
        final data = review.data();
        final tourId = data['tourId'];
        final rating = (data['rating'] ?? 0).toDouble();

        ratingsMap.putIfAbsent(tourId, () => []);
        ratingsMap[tourId]!.add(rating);
      }

      Map<String, double> toursAvgRatings = {};
      ratingsMap.forEach((key, ratings) {
        double avg = ratings.reduce((a, b) => a + b) / ratings.length;
        toursAvgRatings[key] = avg;
      });

      List<Tour> updatedTours = loadedTours.map((tour) {
        double? avgRating = toursAvgRatings[tour.id];
        return tour.copyWith(rating: avgRating ?? tour.rating);
      }).toList();

      final types = updatedTours.map((t) => t.tourType).toSet().toList();
      types.sort();
      types.insert(0, 'Все');

      final prices = updatedTours.map((t) => t.price);
      final minP = prices.reduce((a, b) => a < b ? a : b);
      final maxP = prices.reduce((a, b) => a > b ? a : b);

      setState(() {
        tours = updatedTours;
        filteredTours = updatedTours;
        tourTypes = types;
        minPrice = selectedMinPrice = minP;
        maxPrice = selectedMaxPrice = maxP;
      });
    } catch (e) {
      print('Ошибка загрузки: $e');
    }
  }

  void _filterTours() {
    setState(() {
      filteredTours = tours.where((tour) {
        final matchesDestination = _destinationController.text.isEmpty ||
            tour.destination.toLowerCase().contains(_destinationController.text.toLowerCase());

        final matchesType = selectedType == 'Все' || tour.tourType == selectedType;
        final matchesDate = selectedStartDate == null || tour.startDate.isAfter(selectedStartDate!);
        final matchesPrice = tour.price >= selectedMinPrice && tour.price <= selectedMaxPrice;
        final matchesRating = tour.rating >= selectedMinRating;

        return matchesDestination && matchesType && matchesDate && matchesPrice && matchesRating;
      }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedStartDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedStartDate = picked;
      });
      _filterTours();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск туров'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _destinationController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: 'Направление',
                filled: true,
                fillColor: colorScheme.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onChanged: (_) => _filterTours(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: InputDecoration(
                labelText: 'Тип тура',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
              ),
              items: tourTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value ?? 'Все';
                });
                _filterTours();
              },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(selectedStartDate == null
                  ? 'Выбрать дату'
                  : 'Дата с: ${selectedStartDate!.toLocal().toString().split(' ')[0]}'),
              onPressed: () => _selectDate(context),
            ),
            const SizedBox(height: 20),
            Text('Цена: от ${selectedMinPrice.toInt()} до ${selectedMaxPrice.toInt()} ₽'),
            RangeSlider(
              values: RangeValues(selectedMinPrice, selectedMaxPrice),
              min: minPrice,
              max: maxPrice,
              divisions: 20,
              labels: RangeLabels(
                selectedMinPrice.toStringAsFixed(0),
                selectedMaxPrice.toStringAsFixed(0),
              ),
              onChanged: (values) {
                setState(() {
                  selectedMinPrice = values.start;
                  selectedMaxPrice = values.end;
                });
                _filterTours();
              },
            ),
            const SizedBox(height: 8),
            Text('Минимальный рейтинг: ${selectedMinRating.toStringAsFixed(1)} ★'),
            Slider(
              min: 0,
              max: 5,
              divisions: 10,
              label: selectedMinRating.toStringAsFixed(1),
              value: selectedMinRating,
              onChanged: (value) {
                setState(() {
                  selectedMinRating = value;
                });
                _filterTours();
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text('Найдено: ${filteredTours.length} туров',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (filteredTours.isEmpty)
              const Center(child: Text('Нет туров по заданным параметрам')),
            ...filteredTours.map((tour) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    title: Text(tour.destination),
                    subtitle: Text(
                        '${tour.price} ₽\nРейтинг: ${tour.rating.toStringAsFixed(1)} ★'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TourDetailsScreen(tour: tour),
                        ),
                      );
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
