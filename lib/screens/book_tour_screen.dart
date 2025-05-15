import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/models/tour.dart';

class BookTourScreen extends StatefulWidget {
  final Tour tour;

  BookTourScreen({required this.tour});

  @override
  _BookTourScreenState createState() => _BookTourScreenState();
}

class _BookTourScreenState extends State<BookTourScreen> {
  DateTime? selectedDate;
  int numberOfPeople = 1;
  bool isBookingInProgress = false; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Бронирование')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Отображаем тур
            Text(
              'Тур: ${widget.tour.destination}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            
            // Выбор даты
            ElevatedButton(
              onPressed: _selectDate,
              child: Text(selectedDate == null
                  ? 'Выберите дату'
                  : 'Дата: ${selectedDate!.toLocal()}'),
            ),
            SizedBox(height: 20),
            
            // Выбор количества людей
            Text('Количество человек: $numberOfPeople', style: TextStyle(fontSize: 18)),
            Slider(
              value: numberOfPeople.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$numberOfPeople',
              onChanged: (value) {
                setState(() {
                  numberOfPeople = value.toInt();
                });
              },
            ),
            SizedBox(height: 20),
            
            // Кнопка для бронирования
            isBookingInProgress
                ? Center(child: CircularProgressIndicator()) // Показываем индикатор загрузки
                : ElevatedButton(
                    onPressed: _bookTour,
                    child: Text('Бронирование'),
                  ),
          ],
        ),
      ),
    );
  }

  // Выбор даты
  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Функция для бронирования
  Future<void> _bookTour() async {
    if (selectedDate == null) {
      _showErrorMessage('Выберите дату бронирования.');
      return; 
    }

    setState(() {
      isBookingInProgress = true; 
    });

    try {
      await FirebaseFirestore.instance.collection('Bookings').add({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'tourId': widget.tour.destination,
        'date': selectedDate,
        'numberOfPeople': numberOfPeople,
        'totalPrice': widget.tour.price * numberOfPeople,
      });

      _showSuccessMessage('Бронирование успешно!');
    } catch (e) {
      _showErrorMessage('Ошибка бронирования, попробуйте позже.');
    } finally {
      setState(() {
        isBookingInProgress = false; 
      });
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.red))),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.green))),
    );
  }
}
