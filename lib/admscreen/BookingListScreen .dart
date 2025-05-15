// lib/screens/admin/booking_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bookingsRef = FirebaseFirestore.instance.collection('Bookings');

    return Scaffold(
      appBar: AppBar(title: Text('Все бронирования')),
      body: StreamBuilder<QuerySnapshot>(
        stream: bookingsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final bookings = snapshot.data!.docs;

          if (bookings.isEmpty) {
            return Center(child: Text('Нет бронирований'));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final bookingData = booking.data() as Map<String, dynamic>;
              final userId = bookingData['userId'];
              final tourId = bookingData['tourId'] ?? 'Без названия';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  String userInfo = 'Загрузка...';

                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    userInfo = userData['email'] ?? userData['name'] ?? 'Неизвестный пользователь';
                  } else if (userSnapshot.hasError) {
                    userInfo = 'Ошибка загрузки пользователя';
                  }

                  return ListTile(
                    title: Text('Тур: $tourId'),
                    subtitle: Text('Пользователь: $userInfo'),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
