import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/tour.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/tour_detail_screen.dart';
import 'package:intl/intl.dart';

class SearchToursScreen extends StatefulWidget {
  const SearchToursScreen({super.key});

  @override
  State<SearchToursScreen> createState() => _SearchToursScreenState();
}

class _SearchToursScreenState extends State<SearchToursScreen> {
  final _departureController = TextEditingController(text: 'Москва');
  final _dateController = TextEditingController();

  String? selectedDestination;
  DateTime? selectedStartDate;
  int? selectedNights;
  int selectedTourists = 2;

  List<Tour> tours = [], filteredTours = [];
  List<String> destinations = [];

  @override
  void initState() {
    super.initState();
    _fetchTours();
  }

  Future<void> _fetchTours() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('tours').get();
      final loadedTours = snapshot.docs.map(Tour.fromFirestore).toList();

      final destinationSet = {
        for (var t in loadedTours)
          '${t.city}${t.destination.isNotEmpty ? ', ${t.destination}' : ''}',
      };

      setState(() {
        tours = loadedTours;
        filteredTours = loadedTours;
        destinations = destinationSet.toList()..sort();
      });
    } catch (e) {
      print('Ошибка загрузки туров: $e');
    }
  }

  void _filterTours() {
    setState(() {
      filteredTours =
          tours.where((tour) {
            final matchesDestination =
                selectedDestination == null ||
                '${tour.city}${tour.destination.isNotEmpty ? ', ${tour.destination}' : ''}' ==
                    selectedDestination;

            final matchesDate =
                selectedStartDate == null ||
                selectedStartDate!.isAfter(
                  DateTime.now().subtract(const Duration(days: 1)),
                );

            // Фильтрация по ночам с учетом minNights и maxNights
            final matchesNights =
                selectedNights == null ||
                (tour.minNights <= selectedNights! &&
                    selectedNights! <= tour.maxNights);

            return matchesDestination && matchesDate && matchesNights;
          }).toList();
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        selectedStartDate = picked.start;
        selectedNights = picked.end.difference(picked.start).inDays;
        _dateController.text = DateFormat('dd.MM.yyyy').format(picked.start);
      });
      _filterTours();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

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
          _buildInputFields(),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _filterTours, child: const Text('Поиск')),
          const Divider(height: 32),
          Text('Найдено: ${filteredTours.length} туров'),
          const SizedBox(height: 12),
          ..._buildTourCards(),
        ],
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField('Откуда', _departureController, enabled: false),
        const SizedBox(height: 12),
        _buildDestinationDropdown(),
        const SizedBox(height: 12),
        _buildDateField(),
        const SizedBox(height: 12),
        _buildNightsDropdown(),
        const SizedBox(height: 12),
        _buildTouristsDropdown(),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildDestinationDropdown() {
    if (destinations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return DropdownButtonFormField<String>(
      value:
          destinations.contains(selectedDestination)
              ? selectedDestination
              : null,
      decoration: InputDecoration(
        labelText: 'Куда',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      items:
          destinations
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
      onChanged: (value) {
        setState(() => selectedDestination = value);
        _filterTours();
      },
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      readOnly: true,
      controller: _dateController,
      onTap: _pickDateRange,
      decoration: InputDecoration(
        labelText: 'Дата вылета',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
    );
  }

  Widget _buildNightsDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedNights,
      decoration: InputDecoration(
        labelText: 'Ночей',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      items:
          List.generate(
            20,
            (i) => i + 1,
          ).map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
      onChanged: (value) {
        setState(() => selectedNights = value);
        _filterTours();
      },
    );
  }

  Widget _buildTouristsDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedTourists,
      decoration: InputDecoration(
        labelText: 'Туристы',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      items:
          List.generate(
            6,
            (i) => i + 1,
          ).map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
      onChanged: (value) => setState(() => selectedTourists = value ?? 2),
    );
  }

  List<Widget> _buildTourCards() {
    if (filteredTours.isEmpty) {
      return [const Center(child: Text('Нет туров по заданным параметрам'))];
    }

    return filteredTours.map((tour) {
      final totalPrice = tour.basePrice * selectedTourists;

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => TourDetailScreen(
                      tour: tour,
                      touristsCount: selectedTourists, // <-- передаём сюда
                    ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                tour.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tour.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$totalPrice ₽ • ${tour.hotelStars}★ отель'),
                    Text('Питание: ${tour.hotelMeals}'),
                    Text(
                      'Рейтинг отеля: ${tour.hotelRating.toStringAsFixed(1)} ★',
                    ),
                    Text(
                      '${tour.flightAirline} (${tour.flightFrom} → ${tour.flightTo})',
                    ),
                    Text(
                      'Ночей: от ${tour.minNights} до ${tour.maxNights}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
