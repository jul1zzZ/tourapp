import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/models/tour.dart';
import 'package:flutter_application_1/screens/tour_detail_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart'; // <-- Убедись, что путь правильный
import 'package:firebase_auth/firebase_auth.dart';

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

      final loadedTours = snapshot.docs
          .map((doc) => Tour.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();

      final types = loadedTours.map((t) => t.tourType).toSet().toList();
      types.sort();
      types.insert(0, 'Все');

      final prices = loadedTours.map((t) => t.price);
      final minP = prices.reduce((a, b) => a < b ? a : b);
      final maxP = prices.reduce((a, b) => a > b ? a : b);

      setState(() {
        tours = loadedTours;
        filteredTours = loadedTours;
        tourTypes = types;
        minPrice = selectedMinPrice = minP;
        maxPrice = selectedMaxPrice = maxP;
      });
    } catch (e) {
      print('Ошибка при загрузке туров: $e');
    }
  }

  void _filterTours() {
    setState(() {
      filteredTours = tours.where((tour) {
        final matchesDestination = _destinationController.text.isEmpty ||
            tour.destination
                .toLowerCase()
                .contains(_destinationController.text.toLowerCase());

        final matchesType = selectedType == 'Все' || tour.tourType == selectedType;

        final matchesDate = selectedStartDate == null ||
            tour.startDate.isAfter(selectedStartDate!);

        final matchesPrice = tour.price >= selectedMinPrice &&
            tour.price <= selectedMaxPrice;

        final matchesRating = tour.rating >= selectedMinRating;

        return matchesDestination &&
            matchesType &&
            matchesDate &&
            matchesPrice &&
            matchesRating;
      }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Поиск туров'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _destinationController,
              decoration: InputDecoration(labelText: 'Направление'),
              onChanged: (_) => _filterTours(),
            ),
            DropdownButton<String>(
              value: selectedType,
              isExpanded: true,
              items: tourTypes
                  .map((type) => DropdownMenuItem(
                        child: Text(type),
                        value: type,
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value ?? 'Все';
                });
                _filterTours();
              },
            ),
            Row(
              children: [
                Text(selectedStartDate == null
                    ? 'Выберите дату'
                    : 'Дата с: ${selectedStartDate!.toLocal().toString().split(' ')[0]}'),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text('Выбрать дату'),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Цена: от ${selectedMinPrice.toInt()} до ${selectedMaxPrice.toInt()} USD'),
                RangeSlider(
                  min: minPrice,
                  max: maxPrice,
                  values: RangeValues(selectedMinPrice, selectedMaxPrice),
                  onChanged: (values) {
                    setState(() {
                      selectedMinPrice = values.start;
                      selectedMaxPrice = values.end;
                    });
                    _filterTours();
                  },
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Минимальный рейтинг: ${selectedMinRating.toStringAsFixed(1)}'),
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
              ],
            ),
            Expanded(
              child: filteredTours.isEmpty
                  ? Center(child: Text('Нет туров по заданным параметрам'))
                  : ListView.builder(
                      itemCount: filteredTours.length,
                      itemBuilder: (context, index) {
                        final tour = filteredTours[index];
                        return ListTile(
                          title: Text(tour.destination),
                          subtitle: Text('${tour.price} USD • Рейтинг: ${tour.rating}'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TourDetailsScreen(tour: tour),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
