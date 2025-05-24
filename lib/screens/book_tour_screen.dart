import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/models/tour.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/screens/search_tour_screen.dart';

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
  String? _selectedPaymentMethod;

  final List<String> _paymentMethods = [
    'Карта Visa/MasterCard',
    'Электронный кошелёк (ЮMoney, QIWI)',
    'Наличные при встрече',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Бронирование')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Тур: ${widget.tour.destination}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: _selectDate,
              child: Text(selectedDate == null
                  ? 'Выберите дату'
                  : 'Дата: ${DateFormat('dd.MM.yyyy').format(selectedDate!)}'),
            ),
            SizedBox(height: 20),

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

            Text('Способ оплаты:', style: TextStyle(fontSize: 18)),
            DropdownButton<String>(
              value: _selectedPaymentMethod,
              hint: Text('Выберите способ оплаты'),
              isExpanded: true,
              items: _paymentMethods.map((method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value;
                });
              },
            ),
            SizedBox(height: 30),

            isBookingInProgress
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _bookTour,
                    child: Text('Забронировать'),
                  ),
          ],
        ),
      ),
    );
  }

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

  Future<void> _simulatePayment() async {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Оплата'),
        content: Text('Оплата через "$_selectedPaymentMethod" прошла успешно.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _bookTour() async {
  if (selectedDate == null) {
    _showErrorMessage('Выберите дату бронирования.');
    return;
  }

  if (_selectedPaymentMethod == null) {
    _showErrorMessage('Выберите способ оплаты.');
    return;
  }

  setState(() {
    isBookingInProgress = true;
  });

  try {
    await _simulatePayment();

    await FirebaseFirestore.instance.collection('Bookings').add({
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'tourId': widget.tour.destination,
      'date': selectedDate,
      'numberOfPeople': numberOfPeople,
      'totalPrice': widget.tour.price * numberOfPeople,
      'paymentMethod': _selectedPaymentMethod,
      'status': 'Ожидает подтверждения',
      'timestamp': Timestamp.now(),
    });

    _showSuccessMessage('Бронирование успешно!');

    await Future.delayed(Duration(seconds: 1));

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SearchToursScreen()),
      (route) => false,
    );
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
