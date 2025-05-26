import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/tour.dart';
import 'package:flutter_application_1/screens/book_tour_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TourDetailsScreen extends StatefulWidget {
  final Tour tour;

  const TourDetailsScreen({required this.tour, Key? key}) : super(key: key);

  @override
  State<TourDetailsScreen> createState() => _TourDetailsScreenState();
}

class _TourDetailsScreenState extends State<TourDetailsScreen> {
  final List<Marker> _placeMarkers = [];
  late final MapController _mapController = MapController();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _reviewsStream;
  String? visaInfo;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
    _reviewsStream = FirebaseFirestore.instance
        .collection('reviews')
        .where('tourId', isEqualTo: widget.tour.id)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _loadPlaces() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Cities')
        .doc(widget.tour.destination)
        .collection('Places')
        .get();

    final markers = snapshot.docs.map((doc) {
      final data = doc.data();
      return Marker(
        width: 40,
        height: 40,
        point: LatLng(data['lat'], data['lng']),
        child: Icon(
          _getIcon(data['type']),
          color: Colors.red,
          size: 30,
        ),
      );
    }).toList();

    setState(() {
      _placeMarkers.addAll(markers);
    });
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'hotel':
        return Icons.hotel;
      case 'restaurant':
        return Icons.restaurant;
      case 'attraction':
        return Icons.attractions;
      default:
        return Icons.place;
    }
  }

  Future<void> _loadVisaInfo() async {
    final doc = await FirebaseFirestore.instance
        .collection('VisaRequirements')
        .doc(widget.tour.destination)
        .get();

    if (doc.exists) {
      final data = doc.data();
      setState(() {
        visaInfo = data?['info'];
      });
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Визовая информация'),
        content: Text(visaInfo ?? 'Нет информации о визе для этого направления.'),
        actions: [
          TextButton(
            child: const Text('Закрыть'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _reviewsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data?.docs ?? [];

        if (reviews.isEmpty) {
          return const Text('Пока нет отзывов. Будьте первым!');
        }

        final avgRating = reviews
                .map((r) => (r.data()['rating'] as num?)?.toDouble() ?? 0.0)
                .reduce((a, b) => a + b) /
            reviews.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Отзывы (средний рейтинг: ${avgRating.toStringAsFixed(1)})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            ...reviews.map((doc) {
              final data = doc.data();
              final rating = data['rating'] ?? 0;
              final review = data['review'] ?? '';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              return Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 18,
                      );
                    }),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review),
                      if (timestamp != null)
                        Text(
                          '${timestamp.day}.${timestamp.month}.${timestamp.year}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _showAddReviewDialog,
              child: const Text('Оставить отзыв'),
            ),
          ],
        );
      },
    );
  }

  void _showAddReviewDialog() {
    final TextEditingController _reviewController = TextEditingController();
    double ratingValue = 3;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Оставить отзыв'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Оценка:'),
              Slider(
                value: ratingValue,
                min: 1,
                max: 5,
                divisions: 4,
                label: ratingValue.toStringAsFixed(0),
                onChanged: (val) {
                  setStateDialog(() => ratingValue = val);
                },
              ),
              TextField(
                controller: _reviewController,
                decoration: const InputDecoration(labelText: 'Ваш отзыв'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            child: const Text('Отправить'),
            onPressed: () async {
              final text = _reviewController.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Пожалуйста, введите текст отзыва.')),
                );
                return;
              }

              await FirebaseFirestore.instance.collection('reviews').add({
                'tourId': widget.tour.id,
                'rating': ratingValue,
                'review': text,
                'timestamp': Timestamp.now(),
              });

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.tour.destination)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Место назначения: ${widget.tour.destination}',
                style: textTheme.titleMedium),
            const SizedBox(height: 10),
            Text('Цена: ${widget.tour.price} руб.', style: textTheme.bodyLarge),
            Text('Тип тура: ${widget.tour.tourType}', style: textTheme.bodyLarge),
            Text('Дата начала: ${widget.tour.startDate}', style: textTheme.bodyLarge),
            Text('Дата окончания: ${widget.tour.endDate}', style: textTheme.bodyLarge),
            const SizedBox(height: 10),
            Text('Описание: ${widget.tour.description}', style: textTheme.bodyMedium),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _placeMarkers.isNotEmpty
                      ? _placeMarkers.first.point
                      : const LatLng(0, 0),
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  MarkerLayer(markers: _placeMarkers),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loadVisaInfo,
              child: const Text('Информация о визе'),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookTourScreen(tour: widget.tour),
                  ),
                );
              },
              child: const Text('Забронировать'),
            ),
            const Divider(height: 40),
            _buildReviews(),
          ],
        ),
      ),
    );
  }
}
