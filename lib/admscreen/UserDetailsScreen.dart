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
            return Center(child: Text('Ошибка загрузки данных пользователя'));
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return Center(child: Text('Пользователь не найден'));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};

          final name = userData['name'] ?? 'Без имени';
          final email = userData['email'] ?? 'Без email';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                margin: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                  ),
                  title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(email),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Бронирования',
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
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        final data = booking.data() as Map<String, dynamic>? ?? {};

                        final tourId = data['tourId'] ?? 'Без названия';
                        final timestamp = data['date'];
                        String formattedDate = 'Не указана';

                        if (timestamp is Timestamp) {
                          final date = timestamp.toDate();
                          formattedDate =
                              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
                        }

                        final status = data['status'] ?? 'Ожидает';

                        return Card(
                          child: ListTile(
                            title: Text('Тур: $tourId'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Дата: $formattedDate'),
                                Text('Статус: $status'),
                              ],
                            ),
                            leading: Icon(Icons.tour),
                          ),
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
