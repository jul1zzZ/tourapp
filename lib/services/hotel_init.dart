import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> initializeHotels() async {
  CollectionReference hotels = FirebaseFirestore.instance.collection('Hotels');

  await hotels.doc('hotel_1').set({
    'name': 'Sharm Hotel',
    'city': 'Sharm El Sheikh',
    'rating': 4.5,
    'description': 'A luxurious hotel by the beach',
  });

  await hotels.doc('hotel_2').set({
    'name': 'Istanbul Hotel',
    'city': 'Istanbul',
    'rating': 4.7,
    'description': 'A historical hotel in the heart of the city',
  });

  print("Hotels initialized");
}
