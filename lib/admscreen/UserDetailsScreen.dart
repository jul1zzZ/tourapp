// lib/screens/admin/user_details_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailsScreen extends StatelessWidget {
  final String userId;

  UserDetailsScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final bookingsRef = FirebaseFirestore.instance
        .collection('Bookings')
        .where('userId', isEqualTo: userId);

    return Scaffold(
      appBar: AppBar(title: Text('Детали пользователя')),
      body: FutureBuilder<DocumentSnapshot>(
        future: userRef.get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (userSnapshot.hasError) {
            return Center(child: Text('Ошибка загрузки пользователя'));
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return Center(child: Text('Пользователь не найден'));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(userData['name'] ?? 'Без имени'),
                subtitle: Text(userData['email'] ?? 'Без email'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Text(
                  'Бронирования:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: bookingsRef.snapshots(),
                  builder: (context, bookingSnapshot) {
                    if (bookingSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (bookingSnapshot.hasError) {
                      return Center(child: Text('Ошибка загрузки бронирований'));
                    }

                    final bookings = bookingSnapshot.data?.docs ?? [];

                    if (bookings.isEmpty) {
                      return Center(child: Text('Нет бронирований'));
                    }

                    return ListView.builder(
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        final data = booking.data() as Map<String, dynamic>;

                        // Обработка даты
                        String formattedDate = 'Не указана';
                        if (data['date'] is Timestamp) {
                          final date = (data['date'] as Timestamp).toDate();
                          formattedDate =
                              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
                        }

                        return ListTile(
                          title: Text(data['tourId'] ?? 'Без названия'),
                          subtitle: Text('Дата: $formattedDate'),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
