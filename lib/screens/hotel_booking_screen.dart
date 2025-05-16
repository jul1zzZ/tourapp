import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'booking_confirmation_screen.dart';

class HotelBookingScreen extends StatelessWidget {
  final CollectionReference hotelsRef = FirebaseFirestore.instance.collection('Hotels');
  final CollectionReference bookingsRef = FirebaseFirestore.instance.collection('hotel_booking');

  Future<void> bookHotel(BuildContext context, String hotelName) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ошибка: пользователь не авторизован.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    await bookingsRef.add({
      'hotelName': hotelName,
      'userId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(hotelName: hotelName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Бронирование отелей')),
      body: StreamBuilder<QuerySnapshot>(
        stream: hotelsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final hotels = snapshot.data!.docs;

          if (hotels.isEmpty) return Center(child: Text('Нет доступных отелей'));

          return ListView.builder(
            itemCount: hotels.length,
            itemBuilder: (context, index) {
              final doc = hotels[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['name'] ?? 'Без названия',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(data['city'] ?? 'Город неизвестен'),
                      SizedBox(height: 4),
                      Text(data['description'] ?? ''),
                      SizedBox(height: 4),
                      Text('Рейтинг: ${data['rating']?.toString() ?? 'N/A'} ⭐'),
                      SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => bookHotel(context, data['name']),
                          child: Text('Забронировать'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
