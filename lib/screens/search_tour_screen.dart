import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/models/tour.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/tour_detail_screen.dart';

class SearchToursScreen extends StatefulWidget {
  const SearchToursScreen({super.key});

  @override
  _SearchToursScreenState createState() => _SearchToursScreenState();
}

class _SearchToursScreenState extends State<SearchToursScreen> {
  List<Tour> tours = [], filteredTours = [];
  List<String> tourTypes = ['Все'];

  final _destinationController = TextEditingController();
  String selectedType = 'Все';
  DateTime? selectedStartDate;

  double minPrice = 0, maxPrice = 10000;
  double selectedMinPrice = 0, selectedMaxPrice = 10000;
  double selectedMinRating = 0;

  @override
  void initState() {
    super.initState();
    _fetchTours();
  }

  Future<void> _fetchTours() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('Tours').get();
      final loadedTours = snapshot.docs.map(Tour.fromFirestore).toList();

      final tourIds = snapshot.docs.map((doc) => doc.id).toList();
      final reviewsSnapshot =
          await FirebaseFirestore.instance
              .collection('reviews')
              .where('tourId', whereIn: tourIds)
              .get();

      final ratingsMap = <String, List<double>>{};
      for (var review in reviewsSnapshot.docs) {
        final data = review.data();
        final id = data['tourId'];
        ratingsMap
            .putIfAbsent(id, () => [])
            .add((data['rating'] ?? 0).toDouble());
      }

      final avgRatings = ratingsMap.map(
        (k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length),
      );
      final updatedTours =
          loadedTours
              .map((t) => t.copyWith(rating: avgRatings[t.id] ?? 0))
              .toList();

      final types =
          {'Все', ...updatedTours.map((t) => t.tourType)}.toList()..sort();
      final prices = updatedTours.map((t) => t.price);
      final minP = prices.reduce((a, b) => a < b ? a : b);
      final maxP = prices.reduce((a, b) => a > b ? a : b);

      setState(() {
        tours = updatedTours;
        tourTypes = types;
        minPrice = selectedMinPrice = minP;
        maxPrice = selectedMaxPrice = maxP;
        filteredTours = updatedTours;
      });
    } catch (e) {
      print('Ошибка загрузки: $e');
    }
  }

  void _filterTours() {
    setState(() {
      filteredTours =
          tours.where((tour) {
            final matchesDestination =
                _destinationController.text.isEmpty ||
                tour.destination.toLowerCase().contains(
                  _destinationController.text.toLowerCase(),
                );

            return matchesDestination &&
                (selectedType == 'Все' || tour.tourType == selectedType) &&
                (selectedStartDate == null ||
                    tour.startDate.isAfter(selectedStartDate!)) &&
                tour.price >= selectedMinPrice &&
                tour.price <= selectedMaxPrice &&
                tour.rating >= selectedMinRating;
          }).toList();
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedStartDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedStartDate = picked);
      _filterTours();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colortheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск туров'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTextField(),
          const SizedBox(height: 12),
          _buildDropdown(),
          const SizedBox(height: 12),
          _buildDateButton(),
          const SizedBox(height: 20),
          _buildPriceSlider(),
          _buildRatingSlider(),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Найдено: ${filteredTours.length} туров',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ..._buildTourCards(),
        ],
      ),
    );
  }

  Widget _buildTextField() => TextFormField(
    controller: _destinationController,
    decoration: InputDecoration(
      prefixIcon: const Icon(Icons.search),
      labelText: 'Направление',
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
    onChanged: (_) => _filterTours(),
  );

  Widget _buildDropdown() => DropdownButtonFormField<String>(
    value: selectedType,
    decoration: InputDecoration(
      labelText: 'Тип тура',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
    items:
        tourTypes
            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
            .toList(),
    onChanged: (value) {
      setState(() => selectedType = value ?? 'Все');
      _filterTours();
    },
  );

  Widget _buildDateButton() => FilledButton.icon(
    icon: const Icon(Icons.date_range),
    label: Text(
      selectedStartDate == null
          ? 'Выбрать дату'
          : 'С: ${selectedStartDate!.toLocal().toString().split(' ')[0]}',
    ),
    onPressed: _selectDate,
  );

  Widget _buildPriceSlider() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Цена: от ${selectedMinPrice.toInt()} до ${selectedMaxPrice.toInt()} ₽',
      ),
      RangeSlider(
        values: RangeValues(selectedMinPrice, selectedMaxPrice),
        min: minPrice,
        max: maxPrice,
        divisions: 20,
        onChanged: (values) {
          setState(() {
            selectedMinPrice = values.start;
            selectedMaxPrice = values.end;
          });
          _filterTours();
        },
      ),
    ],
  );

  Widget _buildRatingSlider() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Минимальный рейтинг: ${selectedMinRating.toStringAsFixed(1)} ★'),
      Slider(
        min: 0,
        max: 5,
        divisions: 10,
        value: selectedMinRating,
        label: selectedMinRating.toStringAsFixed(1),
        onChanged: (value) {
          setState(() => selectedMinRating = value);
          _filterTours();
        },
      ),
    ],
  );

  List<Widget> _buildTourCards() =>
      filteredTours.isEmpty
          ? [const Center(child: Text('Нет туров по заданным параметрам'))]
          : filteredTours
              .map(
                (tour) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.travel_explore,
                      color: Colors.blue,
                    ),
                    title: Text(tour.destination),
                    subtitle: Text(
                      '${tour.price} ₽\nРейтинг: ${tour.rating.toStringAsFixed(1)} ★',
                    ),
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
                ),
              )
              .toList();
}
