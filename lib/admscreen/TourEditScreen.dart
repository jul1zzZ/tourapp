import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TourEditScreen extends StatefulWidget {
  final String? tourId;
  TourEditScreen({this.tourId});

  @override
  _TourEditScreenState createState() => _TourEditScreenState();
}

class _TourEditScreenState extends State<TourEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _destinationController = TextEditingController();
  final _hotelController = TextEditingController();
  final _priceController = TextEditingController();
  final _ratingController = TextEditingController();
  final _tourTypeController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.tourId != null) {
      _loadTourData();
    }
  }

  Future<void> _loadTourData() async {
    setState(() => _isLoading = true);
    final doc = await FirebaseFirestore.instance.collection('Tours').doc(widget.tourId).get();
    if (doc.exists) {
      final data = doc.data()!;
      _cityController.text = data['city'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _destinationController.text = data['destination'] ?? '';
      _hotelController.text = data['hotel'] ?? '';
      _priceController.text = (data['price'] ?? '').toString();
      _ratingController.text = (data['rating'] ?? '').toString();
      _tourTypeController.text = data['tourType'] ?? '';
      _startDate = (data['startDate'] as Timestamp?)?.toDate();
      _endDate = (data['endDate'] as Timestamp?)?.toDate();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveTour() async {
    if (!_formKey.currentState!.validate() || _startDate == null || _endDate == null) return;

    final data = {
      'city': _cityController.text.trim(),
      'description': _descriptionController.text.trim(),
      'destination': _destinationController.text.trim(),
      'hotel': _hotelController.text.trim(),
      'price': double.tryParse(_priceController.text) ?? 0,
      'rating': double.tryParse(_ratingController.text) ?? 0,
      'tourType': _tourTypeController.text.trim(),
      'startDate': _startDate,
      'endDate': _endDate,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final toursRef = FirebaseFirestore.instance.collection('Tours');

    if (widget.tourId == null) {
      await toursRef.add(data);
    } else {
      await toursRef.doc(widget.tourId).update(data);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tourId == null ? 'Новый тур' : 'Редактировать тур'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildTextField(_cityController, 'Город'),
                    _buildTextField(_destinationController, 'Страна/направление'),
                    _buildTextField(_hotelController, 'Отель'),
                    _buildTextField(_tourTypeController, 'Тип тура'),
                    _buildTextField(_priceController, 'Цена', isNumber: true),
                    _buildTextField(_ratingController, 'Рейтинг (0–5)', isNumber: true),
                    _buildTextField(_descriptionController, 'Описание', maxLines: 4),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(_startDate == null
                              ? 'Дата начала не выбрана'
                              : 'Начало: ${dateFormatter.format(_startDate!)}'),
                        ),
                        TextButton(
                          onPressed: () => _selectDate(context, true),
                          child: Text('Выбрать дату'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(_endDate == null
                              ? 'Дата окончания не выбрана'
                              : 'Конец: ${dateFormatter.format(_endDate!)}'),
                        ),
                        TextButton(
                          onPressed: () => _selectDate(context, false),
                          child: Text('Выбрать дату'),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveTour,
                      child: Text('Сохранить'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) =>
            value == null || value.isEmpty ? 'Введите $label' : null,
        maxLines: maxLines,
      ),
    );
  }
}
