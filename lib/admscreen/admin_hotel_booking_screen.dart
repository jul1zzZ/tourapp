import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminHotelBookingScreen extends StatelessWidget {
  final CollectionReference bookingsRef = FirebaseFirestore.instance.collection('hotel_booking');
  final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');

  Future<void> _confirmPayment(String bookingId) async {
    await bookingsRef.doc(bookingId).update({'status': 'Подтверждено'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Бронирования отелей (Админ)')),
      body: StreamBuilder<QuerySnapshot>(
        stream: bookingsRef.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final bookings = snapshot.data!.docs;

          if (bookings.isEmpty) return Center(child: Text('Нет бронирований.'));

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final data = booking.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Отель: ${data['hotelName'] ?? '—'}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text('Гостей: ${data['guests'] ?? '?'}'),
                      Text('Заезд: ${_formatDate(data['checkIn'])}'),
                      Text('Выезд: ${_formatDate(data['checkOut'])}'),
                      Text('Способ оплаты: ${data['paymentMethod'] ?? '—'}'),
                      Text('Статус: ${data['status'] ?? 'Ожидает'}',
                          style: TextStyle(
                              color: data['status'] == 'Подтверждено'
                                  ? Colors.green
                                  : Colors.orange)),
                      SizedBox(height: 8),
                      if (data['status'] != 'Подтверждено')
                        ElevatedButton(
                          onPressed: () => _confirmPayment(booking.id),
                          child: Text('Подтвердить оплату'),
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

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '—';
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
