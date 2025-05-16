import 'package:flutter/material.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final String hotelName;

  const BookingConfirmationScreen({Key? key, required this.hotelName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Подтверждение')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
              SizedBox(height: 20),
              Text(
                'Бронирование подтверждено!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Вы успешно забронировали отель: $hotelName',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: Text('На главную'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
