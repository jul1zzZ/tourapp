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
    if (widget.tourId != null) _loadTourData();
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
      firstDate: DateTime.now().subtract(Duration(days: 1)),
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
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Выберите даты начала и окончания.')));
      return;
    }

    final price = double.tryParse(_priceController.text) ?? 0;
    final rating = double.tryParse(_ratingController.text) ?? 0;

    if (rating < 0 || rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Рейтинг должен быть от 0 до 5.')));
      return;
    }

    final data = {
      'city': _cityController.text.trim(),
      'description': _descriptionController.text.trim(),
      'destination': _destinationController.text.trim(),
      'hotel': _hotelController.text.trim(),
      'price': price,
      'rating': rating,
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

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Тур сохранён')));
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(_cityController, 'Город'),
                    _buildTextField(_destinationController, 'Страна/направление'),
                    _buildTextField(_hotelController, 'Отель'),
                    _buildTextField(_tourTypeController, 'Тип тура'),
                    _buildTextField(_priceController, 'Цена', isNumber: true),
                    _buildTextField(_ratingController, 'Рейтинг (0–5)', isNumber: true),
                    _buildTextField(_descriptionController, 'Описание', maxLines: 4),

                    const SizedBox(height: 16),

                    _buildDateRow(
                      label: 'Дата начала',
                      date: _startDate,
                      onTap: () => _selectDate(context, true),
                      formatter: dateFormatter,
                    ),
                    _buildDateRow(
                      label: 'Дата окончания',
                      date: _endDate,
                      onTap: () => _selectDate(context, false),
                      formatter: dateFormatter,
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: Icon(Icons.save),
                      label: Text('Сохранить тур'),
                      onPressed: _saveTour,
                      style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
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
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Введите $label' : null,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildDateRow({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required DateFormat formatter,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(label),
        subtitle: Text(
          date == null ? 'Не выбрано' : formatter.format(date),
          style: TextStyle(color: date == null ? Colors.grey : null),
        ),
        trailing: Icon(Icons.calendar_today),
        onTap: onTap,
      ),
    );
  }
}
