import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/tour.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class BookingScreen extends StatefulWidget {
  final Tour tour;
  final int touristsCount;
  final String userEmail; // добавляем

  const BookingScreen({
    super.key,
    required this.tour,
    required this.touristsCount,
    required this.userEmail,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  late final TextEditingController _emailController;

  final maskFormatter = MaskTextInputFormatter(
    mask: '+7 ### ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.userEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('Bookings').add({
        'tourId': widget.tour.id, // убедись, что id есть в модели
        'tourTitle': widget.tour.title,
        'touristsCount': widget.touristsCount,
        'name': _nameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'totalPrice': widget.tour.basePrice * widget.touristsCount,
        'bookingDate': Timestamp.now(),
      });

      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Бронирование успешно оформлено!')),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка при бронировании: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.tour.basePrice * widget.touristsCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бронирование тура'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.tour.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Количество туристов: ${widget.touristsCount}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Итоговая цена: ${totalPrice.toStringAsFixed(0)} ₽',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[700],
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Имя',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) =>
                              (value == null || value.isEmpty)
                                  ? 'Введите имя'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [maskFormatter],
                      decoration: const InputDecoration(
                        labelText: 'Телефон',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Введите телефон';
                        if (maskFormatter.getUnmaskedText().length != 10)
                          return 'Введите полный номер телефона';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: false, // запрещаем редактирование, если нужно
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:
                            _isSubmitting
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'Подтвердить бронирование',
                                  style: TextStyle(fontSize: 18),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
