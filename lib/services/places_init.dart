import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> initializePlaces() async {
  final egyptPlaces = [
    {
      "name": "Pyramids of Giza",
      "type": "attraction",
      "lat": 29.9792,
      "lng": 31.1342,
      "city": "Egypt",
    },
    {
      "name": "Khan El Khalili Bazaar",
      "type": "attraction",
      "lat": 30.0478,
      "lng": 31.2625,
      "city": "Egypt",
    },
    {
      "name": "Nile View Hotel",
      "type": "hotel",
      "lat": 30.0444,
      "lng": 31.2357,
      "city": "Egypt",
    },
    {
      "name": "El Fishawy Cafe",
      "type": "restaurant",
      "lat": 30.0476,
      "lng": 31.2626,
      "city": "Egypt",
    },
    {
      "name": "The Egyptian Museum",
      "type": "attraction",
      "lat": 30.0478,
      "lng": 31.2336,
      "city": "Egypt",
    },
    {
      "name": "Felfela Restaurant",
      "type": "restaurant",
      "lat": 30.0459,
      "lng": 31.2430,
      "city": "Egypt",
    },
  ];

  final turkeyPlaces = [
    {
      "name": "Hagia Sophia",
      "type": "attraction",
      "lat": 41.0086,
      "lng": 28.9802,
      "city": "Turkey",
    },
    {
      "name": "Blue Mosque",
      "type": "attraction",
      "lat": 41.0054,
      "lng": 28.9768,
      "city": "Turkey",
    },
    {
      "name": "Topkapi Palace",
      "type": "attraction",
      "lat": 41.0115,
      "lng": 28.9834,
      "city": "Turkey",
    },
    {
      "name": "Sultanahmet Köftecisi",
      "type": "restaurant",
      "lat": 41.0058,
      "lng": 28.9764,
      "city": "Turkey",
    },
    {
      "name": "Istanbul Hotel",
      "type": "hotel",
      "lat": 41.0065,
      "lng": 28.9769,
      "city": "Turkey",
    },
    {
      "name": "Grand Bazaar",
      "type": "attraction",
      "lat": 41.0106,
      "lng": 28.9680,
      "city": "Turkey",
    },
  ];

  await _uploadPlaces("Egypt", egyptPlaces);
  await _uploadPlaces("Turkey", turkeyPlaces);
}

Future<void> _uploadPlaces(String city, List<Map<String, dynamic>> places) async {
  final cityCollection = FirebaseFirestore.instance.collection('Cities').doc(city).collection('Places');
  final globalCollection = FirebaseFirestore.instance.collection('places');

  for (final place in places) {
    await cityCollection.add(place);        // Вложенная коллекция Cities/{city}/Places
    await globalCollection.add(place);      // Отдельная коллекция places
  }
}
