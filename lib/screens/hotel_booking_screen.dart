import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'booking_confirmation_screen.dart';

class HotelBookingScreen extends StatefulWidget {
  @override
  _HotelBookingScreenState createState() => _HotelBookingScreenState();
}

class _HotelBookingScreenState extends State<HotelBookingScreen> {
  final CollectionReference hotelsRef =
      FirebaseFirestore.instance.collection('Hotels');
  final CollectionReference bookingsRef =
      FirebaseFirestore.instance.collection('hotel_booking');

  DateTime? checkInDate;
  DateTime? checkOutDate;
  int numberOfGuests = 1;
  String selectedPaymentMethod = 'Карта';

  bool _isLoading = false;

  // Сохраняем FCM токен пользователя в Firestore (если не сохранен)
  Future<void> _saveUserFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await userDoc.get();
      if (!snapshot.exists || snapshot.get('fcmToken') != token) {
        await userDoc.set({'fcmToken': token}, SetOptions(merge: true));
      }
    }
  }

  Future<void> bookHotel(BuildContext context, Map<String, dynamic> hotelData) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: пользователь не авторизован.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (checkInDate == null || checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Пожалуйста, выберите даты заезда и выезда.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!checkOutDate!.isAfter(checkInDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Дата выезда должна быть позже даты заезда.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _saveUserFCMToken();

      final nights = checkOutDate!.difference(checkInDate!).inDays;
      final pricePerNight = hotelData['price']?.toDouble() ?? 0.0;
      final totalPrice = nights * pricePerNight;

      await bookingsRef.add({
        'hotelName': hotelData['name'],
        'userId': user.uid,
        'checkIn': checkInDate,
        'checkOut': checkOutDate,
        'guests': numberOfGuests,
        'paymentMethod': selectedPaymentMethod,
        'status': 'Ожидает подтверждения',
        'totalPrice': totalPrice,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(hotelName: hotelData['name']),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при бронировании: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final now = DateTime.now();
    final initialDate = isCheckIn
        ? (checkInDate ?? now)
        : (checkOutDate ?? (checkInDate != null ? checkInDate!.add(Duration(days: 1)) : now.add(Duration(days: 1))));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          checkInDate = picked;
          // Если дата выезда раньше заезда — сбрасываем ее
          if (checkOutDate != null && !checkOutDate!.isAfter(checkInDate!)) {
            checkOutDate = null;
          }
        } else {
          checkOutDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Бронирование отелей')),
      body: StreamBuilder<QuerySnapshot>(
        stream: hotelsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final hotels = snapshot.data!.docs;
          if (hotels.isEmpty) {
            return Center(child: Text('Нет доступных отелей'));
          }

          return ListView.builder(
            itemCount: hotels.length,
            itemBuilder: (context, index) {
              final doc = hotels[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Без названия',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),
                      Text(data['city'] ?? 'Город неизвестен', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 6),
                      Text('Цена за ночь: ${data['price'] ?? '—'} руб.', style: TextStyle(fontSize: 16)),
                      Text('Рейтинг: ${data['rating']?.toString() ?? 'N/A'} ⭐', style: TextStyle(fontSize: 16)),
                      Divider(height: 20, thickness: 1),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _selectDate(context, true),
                              child: Text(checkInDate == null
                                  ? 'Дата заезда'
                                  : 'Заезд: ${checkInDate!.toLocal().toString().split(' ')[0]}'),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _selectDate(context, false),
                              child: Text(checkOutDate == null
                                  ? 'Дата выезда'
                                  : 'Выезд: ${checkOutDate!.toLocal().toString().split(' ')[0]}'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      Row(
                        children: [
                          Text('Гостей: $numberOfGuests', style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Slider(
                              value: numberOfGuests.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: numberOfGuests.toString(),
                              onChanged: (value) {
                                setState(() {
                                  numberOfGuests = value.toInt();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      Row(
                        children: [
                          Text('Оплата:', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 12),
                          DropdownButton<String>(
                            value: selectedPaymentMethod,
                            items: ['Карта', 'Электронный кошелек', 'Наличные']
                                .map((method) => DropdownMenuItem<String>(
                                      value: method,
                                      child: Text(method),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedPaymentMethod = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _isLoading
                            ? CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: () => bookHotel(context, data),
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
