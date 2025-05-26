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
  final CollectionReference hotelsRef = FirebaseFirestore.instance.collection('Hotels');
  final CollectionReference bookingsRef = FirebaseFirestore.instance.collection('hotel_booking');

  DateTime? checkInDate;
  DateTime? checkOutDate;
  int numberOfGuests = 1;
  String selectedPaymentMethod = 'Карта';
  bool _isLoading = false;

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

    if (user == null || checkInDate == null || checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Проверьте данные бронирования.'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
      return;
    }

    if (!checkOutDate!.isAfter(checkInDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Дата выезда должна быть позже даты заезда.'),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
      ));
      return;
    }

    setState(() => _isLoading = true);

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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(hotelName: hotelData['name']),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ошибка при бронировании: ${e.toString()}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final now = DateTime.now();
    final initial = isCheckIn
        ? (checkInDate ?? now)
        : (checkOutDate ?? (checkInDate ?? now).add(const Duration(days: 1)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          checkInDate = picked;
          if (checkOutDate != null && !checkOutDate!.isAfter(picked)) {
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бронирование отелей'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: hotelsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final hotels = snapshot.data!.docs;

          if (hotels.isEmpty) {
            return const Center(child: Text('Нет доступных отелей'));
          }

          return ListView.builder(
            itemCount: hotels.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final doc = hotels[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Без названия',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(data['city'] ?? 'Город неизвестен'),
                      const SizedBox(height: 8),
                      Text('Цена за ночь: ${data['price']}₽'),
                      Text('Рейтинг: ${data['rating'] ?? '—'} ⭐'),
                      const Divider(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () => _selectDate(context, true),
                              child: Text(checkInDate == null
                                  ? 'Дата заезда'
                                  : 'Заезд: ${checkInDate!.toLocal().toString().split(' ')[0]}'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () => _selectDate(context, false),
                              child: Text(checkOutDate == null
                                  ? 'Дата выезда'
                                  : 'Выезд: ${checkOutDate!.toLocal().toString().split(' ')[0]}'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Text('Гостей: $numberOfGuests'),
                          Expanded(
                            child: Slider(
                              value: numberOfGuests.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: '$numberOfGuests',
                              onChanged: (val) {
                                setState(() {
                                  numberOfGuests = val.toInt();
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          const Text('Оплата:'),
                          const SizedBox(width: 12),
                          DropdownButton<String>(
                            value: selectedPaymentMethod,
                            items: ['Карта', 'Электронный кошелек', 'Наличные']
                                .map((method) => DropdownMenuItem(
                                      value: method,
                                      child: Text(method),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedPaymentMethod = val;
                                });
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Align(
                        alignment: Alignment.centerRight,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : FilledButton(
                                onPressed: () => bookHotel(context, data),
                                child: const Text('Забронировать'),
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
