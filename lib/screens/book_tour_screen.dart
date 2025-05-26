import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/models/tour.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/screens/search_tour_screen.dart';
import 'package:flutter_application_1/navigate/bottom_navbar_adm.dart';

class BookTourScreen extends StatefulWidget {
  final Tour tour;

  const BookTourScreen({required this.tour, Key? key}) : super(key: key);

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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Бронирование тура')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Тур: ${widget.tour.destination}',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Выбор даты
            FilledButton(
              onPressed: _selectDate,
              child: Text(
                selectedDate == null
                    ? 'Выберите дату'
                    : 'Дата: ${DateFormat('dd.MM.yyyy').format(selectedDate!)}',
              ),
            ),
            const SizedBox(height: 24),

            // Кол-во человек
            Text('Количество человек: $numberOfPeople',
                style: textTheme.titleMedium),
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
            const SizedBox(height: 24),

            // Оплата
            Text('Способ оплаты:', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Выберите способ оплаты',
              ),
              items: _paymentMethods.map((method) {
                return DropdownMenuItem(
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
            const SizedBox(height: 32),

            // Кнопка
            isBookingInProgress
                ? const Center(child: CircularProgressIndicator())
                : FilledButton.icon(
                    onPressed: _bookTour,
                    icon: const Icon(Icons.check),
                    label: const Text('Забронировать'),
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
        title: const Text('Оплата прошла успешно'),
        content: Text('Метод: $_selectedPaymentMethod'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК'),
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

      await Future.delayed(const Duration(seconds: 1));

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BottomNavbar(isAdmin: false)));
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
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.red)),
        backgroundColor: Colors.red.shade50,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.green)),
        backgroundColor: Colors.green.shade50,
      ),
    );
  }
}
