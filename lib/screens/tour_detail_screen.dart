import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/tour.dart';
import 'package:flutter_application_1/screens/book_tour_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TourDetailsScreen extends StatefulWidget {
  final Tour tour;

  TourDetailsScreen({required this.tour});

  @override
  _TourDetailsScreenState createState() => _TourDetailsScreenState();
}

class _TourDetailsScreenState extends State<TourDetailsScreen> {
  List<Marker> _placeMarkers = [];
  late MapController _mapController;
  String? visaInfo;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadPlaces();
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
      _placeMarkers = markers;
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

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Визовая информация'),
          content: Text(visaInfo ?? 'Нет данных.'),
          actions: [
            TextButton(
              child: Text('Закрыть'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Визовая информация'),
          content: Text('Нет информации о визе для этого направления.'),
          actions: [
            TextButton(
              child: Text('Ок'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tour.destination)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Место назначения: ${widget.tour.destination}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('Цена: ${widget.tour.price} USD', style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              Text('Тип тура: ${widget.tour.tourType}', style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              Text('Рейтинг: ${widget.tour.rating}', style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              Text('Дата начала: ${widget.tour.startDate}', style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              Text('Дата окончания: ${widget.tour.endDate}', style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              Text('Описание: ${widget.tour.description}', style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),
              SizedBox(
                height: 300,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _placeMarkers.isNotEmpty
                        ? _placeMarkers.first.point
                        : LatLng(30.0444, 31.2357),
                    initialZoom: 12.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: _placeMarkers,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadVisaInfo,
                child: Text('Информация о визе'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookTourScreen(tour: widget.tour),
                    ),
                  );
                },
                child: Text('Забронировать'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
