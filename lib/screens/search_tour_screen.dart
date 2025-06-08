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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ищите идеальный тур',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              _buildTextField('Откуда', _departureController, enabled: false),

              const SizedBox(height: 16),

              _buildDestinationDropdown(),

              const SizedBox(height: 16),

              _buildDateField(),

              const SizedBox(height: 16),

              _buildNightsDropdown(),

              const SizedBox(height: 16),

              _buildTouristsDropdown(),

              const SizedBox(height: 24),

              FilledButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Поиск'),
                onPressed: _filterTours,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: colorScheme.primary,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Найдено туров: ${filteredTours.length}',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              ..._buildTourCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: enabled ? null : const Icon(Icons.flight_takeoff),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: enabled ? null : Colors.grey.shade200,
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
        filled: true,
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
    return TextField(
      readOnly: true,
      controller: _dateController,
      onTap: _pickDateRange,
      decoration: InputDecoration(
        labelText: 'Дата вылета',
        suffixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
      ),
    );
  }

  Widget _buildNightsDropdown() {
    List<int> nightOptions = List.generate(20, (i) => i + 1);
    if (selectedNights != null && !nightOptions.contains(selectedNights)) {
      nightOptions.add(selectedNights!);
      nightOptions.sort();
    }

    return DropdownButtonFormField<int>(
      value: selectedNights,
      decoration: InputDecoration(
        labelText: 'Ночей',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
      ),
      items:
          nightOptions
              .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
              .toList(),
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
        filled: true,
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
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'Нет туров по заданным параметрам',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      ];
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
                      touristsCount: selectedTourists,
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
                    Text('$totalPrice ₽ • ${tour.hotel.stars}★ отель'),
                    Text('Питание: ${tour.hotel.meals}'),
                    Text(
                      'Рейтинг отеля: ${tour.hotel.rating.toStringAsFixed(1)} ★',
                    ),
                    Text(
                      '${tour.flightAirline} (${tour.flightFrom} → ${tour.flightTo})',
                    ),
                    Text(
                      'Ночей: от ${tour.minNights} до ${tour.maxNights}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    TourRatingWidget(tourId: tour.id),
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

class TourRatingWidget extends StatelessWidget {
  final String tourId;

  const TourRatingWidget({required this.tourId, super.key});

  Future<double> _fetchAverageRating() async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('Reviews')
            .where('tourId', isEqualTo: tourId)
            .get();

    if (querySnapshot.docs.isEmpty) return 0;

    final ratings =
        querySnapshot.docs
            .map((doc) => (doc.data()['rating'] ?? 0) as int)
            .toList();

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
              Icon(Icons.star, color: Colors.grey, size: 16),
              SizedBox(width: 4),
              Text('Загрузка...'),
            ],
          );
        }
        if (snapshot.hasError) {
          return const Text('Ошибка загрузки рейтинга');
        }

        final averageRating = snapshot.data ?? 0;

        if (averageRating == 0) {
          return const Text('Рейтинг отсутствует');
        }

        return Row(
          children: [
            const Icon(Icons.star, color: Colors.orange, size: 16),
            const SizedBox(width: 4),
            Text('${averageRating.toStringAsFixed(1)} ★'),
          ],
        );
      },
    );
  }
}
