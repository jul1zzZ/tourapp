import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingListScreen extends StatelessWidget {
  final bookingsRef = FirebaseFirestore.instance.collection('Bookings');

  BookingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Все бронирования')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            bookingsRef.orderBy('bookingDate', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

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

  Widget _buildBookingCard(
    BuildContext context,
    String bookingId,
    Map<String, dynamic> data,
  ) {
    final tourTitle = data['tourTitle'] ?? 'Без названия';
    final bookingTimestamp = data['bookingDate'] as Timestamp?;
    final date =
        bookingTimestamp != null
            ? DateFormat('dd.MM.yyyy').format(bookingTimestamp.toDate())
            : 'Неизвестно';

    final name = data['name'] ?? 'Без имени';
    final email = data['email'] ?? 'Нет email';
    final phone = data['phone'] ?? 'Не указан';
    final touristsCount = data['touristsCount'] ?? 0;
    final totalPrice = data['totalPrice'] ?? 0;
    final status = data['status'] ?? 'Ожидает';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Тур: $tourTitle',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text('Имя: $name'),
            Text('Email: $email'),
            Text('Телефон: $phone'),
            Text('Дата бронирования: $date'),
            Text('Количество туристов: $touristsCount'),
            Text('Сумма: ${totalPrice.toString()} ₽'),
            SizedBox(height: 6),
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
                itemBuilder:
                    (context) => [
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
    await FirebaseFirestore.instance
        .collection('Bookings')
        .doc(bookingId)
        .update({'status': newStatus});
  }
}
