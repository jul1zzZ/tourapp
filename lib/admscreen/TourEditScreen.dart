import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TourEditScreen extends StatefulWidget {
  final String? tourId;
  const TourEditScreen({super.key, this.tourId});

  @override
  _TourEditScreenState createState() => _TourEditScreenState();
}

class _TourEditScreenState extends State<TourEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _categoryController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _pricePerNightController = TextEditingController();
  final _minNightsController = TextEditingController();
  final _maxNightsController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _visaRequired = ValueNotifier<bool>(false);

  // Hotel
  final _hotelNameController = TextEditingController();
  final _hotelRatingController = TextEditingController();
  final _hotelStarsController = TextEditingController();
  final _hotelMealsController = TextEditingController();
  LatLng? _hotelLocation;
  final _mapController = MapController();

  // Flight
  final _flightFromController = TextEditingController();
  final _flightToController = TextEditingController();
  final _flightAirlineController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.tourId != null) _loadTourData();
  }

  Future<void> _loadTourData() async {
    setState(() => _isLoading = true);
    final doc =
        await FirebaseFirestore.instance
            .collection('tours')
            .doc(widget.tourId)
            .get();
    if (doc.exists) {
      final data = doc.data()!;
      _titleController.text = data['title'] ?? '';
      _cityController.text = data['city'] ?? '';
      _countryController.text = data['country'] ?? '';
      _categoryController.text = data['category'] ?? '';
      _basePriceController.text = (data['basePrice'] ?? '').toString();
      _pricePerNightController.text = (data['pricePerNight'] ?? '').toString();
      _minNightsController.text = (data['minNights'] ?? '').toString();
      _maxNightsController.text = (data['maxNights'] ?? '').toString();
      _imageUrlController.text = data['imageUrl'] ?? '';
      _visaRequired.value = data['visaRequired'] ?? false;

      final hotel = data['hotel'] ?? {};
      _hotelNameController.text = hotel['name'] ?? '';
      _hotelRatingController.text = (hotel['rating'] ?? '').toString();
      _hotelStarsController.text = (hotel['stars'] ?? '').toString();
      _hotelMealsController.text = hotel['meals'] ?? '';

      final location = hotel['location'];
      if (location != null) {
        _hotelLocation = LatLng(
          (location['lat'] ?? 0).toDouble(),
          (location['lng'] ?? 0).toDouble(),
        );
      }

      final flight = data['flight'] ?? {};
      _flightFromController.text = flight['from'] ?? '';
      _flightToController.text = flight['to'] ?? '';
      _flightAirlineController.text = flight['airline'] ?? '';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveTour() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'title': _titleController.text.trim(),
      'city': _cityController.text.trim(),
      'country': _countryController.text.trim(),
      'category': _categoryController.text.trim(),
      'basePrice': double.tryParse(_basePriceController.text) ?? 0,
      'pricePerNight': double.tryParse(_pricePerNightController.text) ?? 0,
      'minNights': int.tryParse(_minNightsController.text) ?? 1,
      'maxNights': int.tryParse(_maxNightsController.text) ?? 1,
      'visaRequired': _visaRequired.value,
      'imageUrl': _imageUrlController.text.trim(),
      'hotel': {
        'name': _hotelNameController.text.trim(),
        'rating': double.tryParse(_hotelRatingController.text) ?? 0,
        'stars': int.tryParse(_hotelStarsController.text) ?? 0,
        'meals': _hotelMealsController.text.trim(),
        'location': {
          'lat': _hotelLocation?.latitude ?? 0,
          'lng': _hotelLocation?.longitude ?? 0,
        },
      },
      'flight': {
        'from': _flightFromController.text.trim(),
        'to': _flightToController.text.trim(),
        'airline': _flightAirlineController.text.trim(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final toursRef = FirebaseFirestore.instance.collection('tours');
    if (widget.tourId == null) {
      await toursRef.add(data);
    } else {
      await toursRef.doc(widget.tourId).update(data);
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Тур сохранён')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tourId == null ? 'Новый тур' : 'Редактировать тур'),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(_titleController, 'Заголовок'),
                      _buildTextField(_cityController, 'Город'),
                      _buildTextField(_countryController, 'Страна'),
                      _buildTextField(_categoryController, 'Категория'),
                      _buildTextField(
                        _basePriceController,
                        'Базовая цена',
                        isNumber: true,
                      ),
                      _buildTextField(
                        _pricePerNightController,
                        'Цена за ночь',
                        isNumber: true,
                      ),
                      _buildTextField(
                        _minNightsController,
                        'Мин. ночей',
                        isNumber: true,
                      ),
                      _buildTextField(
                        _maxNightsController,
                        'Макс. ночей',
                        isNumber: true,
                      ),
                      _buildTextField(
                        _imageUrlController,
                        'Ссылка на изображение',
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        'Отель',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      _buildTextField(_hotelNameController, 'Название отеля'),
                      _buildTextField(
                        _hotelStarsController,
                        'Звезды',
                        isNumber: true,
                      ),
                      _buildTextField(
                        _hotelRatingController,
                        'Рейтинг',
                        isNumber: true,
                      ),
                      _buildTextField(_hotelMealsController, 'Питание'),

                      const SizedBox(height: 12),
                      Text('Выберите расположение отеля на карте'),
                      Container(
                        height: 250,
                        margin: const EdgeInsets.only(top: 8, bottom: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter:
                                _hotelLocation ??
                                LatLng(41.3851, 2.1734), // Барселона
                            initialZoom: 13.0,
                            onTap: (tapPosition, point) {
                              setState(() {
                                _hotelLocation = point;
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: ['a', 'b', 'c'],
                            ),
                            if (_hotelLocation != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _hotelLocation!,
                                    width: 40,
                                    height: 40,
                                    child: Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      if (_hotelLocation != null)
                        Text(
                          'Координаты отеля:\n${_hotelLocation!.latitude.toStringAsFixed(5)}, ${_hotelLocation!.longitude.toStringAsFixed(5)}',
                          textAlign: TextAlign.center,
                        ),

                      const SizedBox(height: 16),
                      const Text(
                        'Перелёт',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      _buildTextField(_flightFromController, 'Из города'),
                      _buildTextField(_flightToController, 'В город'),
                      _buildTextField(_flightAirlineController, 'Авиакомпания'),

                      const SizedBox(height: 16),
                      ValueListenableBuilder<bool>(
                        valueListenable: _visaRequired,
                        builder:
                            (context, value, _) => SwitchListTile(
                              title: Text('Требуется виза'),
                              value: value,
                              onChanged: (val) => _visaRequired.value = val,
                            ),
                      ),

                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: Icon(Icons.save),
                        label: Text('Сохранить тур'),
                        onPressed: _saveTour,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size.fromHeight(50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters:
            isNumber
                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
                : null,
        validator:
            (value) =>
                value == null || value.trim().isEmpty ? 'Введите $label' : null,
        maxLines: maxLines,
      ),
    );
  }
}
