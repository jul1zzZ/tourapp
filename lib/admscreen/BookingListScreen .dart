import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingListScreen extends StatelessWidget {
  final bookingsRef = FirebaseFirestore.instance.collection('Bookings');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Все бронирования')),
      body: StreamBuilder<QuerySnapshot>(
        stream: bookingsRef.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final bookings = snapshot.data!.docs;

          if (bookings.isEmpty) return Center(child: Text('Нет бронирований'));

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final data = booking.data() as Map<String, dynamic>;

              final userId = data['userId'];
              final tourId = data['tourId'] ?? 'Без названия';
              final date = (data['date'] as Timestamp).toDate().toLocal().toString().split(' ')[0];
              final people = data['numberOfPeople'];
              final total = data['totalPrice'];
              final status = data['status'] ?? 'Ожидает';
              final payment = data['paymentMethod'] ?? 'Не указано';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  String userInfo = 'Загрузка...';
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    userInfo = '${userData['name'] ?? 'Без имени'} (${userData['email']})';
                  }

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text('Тур: $tourId'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Пользователь: $userInfo'),
                          Text('Дата: $date'),
                          Text('Людей: $people'),
                          Text('Сумма: \$${total.toString()}'),
                          Text('Оплата: $payment'),
                          Text('Статус: $status', style: TextStyle(
                            color: _statusColor(status),
                            fontWeight: FontWeight.bold,
                          )),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          _updateStatus(booking.id, value);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'Ожидает', child: Text('Ожидает')),
                          PopupMenuItem(value: 'Оплачено', child: Text('Оплачено')),
                          PopupMenuItem(value: 'Отменено', child: Text('Отменено')),
                        ],
                        child: Icon(Icons.more_vert),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Оплачено':
        return Colors.green;
      case 'Отменено':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _updateStatus(String bookingId, String newStatus) async {
    await FirebaseFirestore.instance.collection('Bookings').doc(bookingId).update({
      'status': newStatus,
    });
  }
}
