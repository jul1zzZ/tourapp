import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
              return _buildBookingCard(context, booking.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, String bookingId, Map<String, dynamic> data) {
    final userId = data['userId'];
    final tourId = data['tourId'] ?? 'Без названия';
    final timestamp = data['date'] as Timestamp?;
    final date = timestamp != null ? DateFormat('yyyy-MM-dd').format(timestamp.toDate()) : 'Неизвестно';
    final people = data['numberOfPeople'] ?? 0;
    final total = data['totalPrice'] ?? 0.0;
    final status = data['status'] ?? 'Ожидает';
    final payment = data['paymentMethod'] ?? 'Не указано';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        String userInfo = 'Загрузка...';
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          userInfo = '${userData['name'] ?? 'Без имени'} (${userData['email'] ?? 'нет почты'})';
        }

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Тур: $tourId', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text('Пользователь: $userInfo'),
                Text('Дата: $date'),
                Text('Количество человек: $people'),
                Text('Сумма: \$${total.toStringAsFixed(2)}'),
                Text('Метод оплаты: $payment'),
                Text(
                  'Статус: $status',
                  style: TextStyle(
                    color: _statusColor(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: PopupMenuButton<String>(
                    onSelected: (value) => _updateStatus(bookingId, value),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'Ожидает', child: Text('Ожидает')),
                      PopupMenuItem(value: 'Оплачено', child: Text('Оплачено')),
                      PopupMenuItem(value: 'Отменено', child: Text('Отменено')),
                    ],
                    icon: Icon(Icons.more_vert),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
