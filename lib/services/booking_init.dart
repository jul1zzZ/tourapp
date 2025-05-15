import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> initializeBookings() async {
  CollectionReference bookings = FirebaseFirestore.instance.collection('Bookings');

  await bookings.doc('booking_1').set({
    'userId': 'user_123',
    'tourId': 'tour_1',
    'date': Timestamp.fromDate(DateTime(2025, 6, 1)),
    'numberOfPeople': 2,
    'totalPrice': 1000,
  });

  await bookings.doc('booking_2').set({
    'userId': 'user_456',
    'tourId': 'tour_2',
    'date': Timestamp.fromDate(DateTime(2025, 7, 1)),
    'numberOfPeople': 1,
    'totalPrice': 350,
  });

  print("Bookings initialized");
}
