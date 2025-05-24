import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddReviewScreen extends StatefulWidget {
  final String tourId;     // ← должен быть ID документа в Tours, например 'tour_1'
  final String bookingId;

  AddReviewScreen({required this.tourId, required this.bookingId});

  @override
  _AddReviewScreenState createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 3;
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пользователь не авторизован.')),
      );
      return;
    }

    try {
      // Добавляем отзыв
      await FirebaseFirestore.instance.collection('reviews').add({
        'tourId': widget.tourId,
        'bookingId': widget.bookingId,
        'userId': userId,
        'rating': _rating,
        'review': _reviewController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Получаем все отзывы для тура
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('tourId', isEqualTo: widget.tourId)
          .get();

      if (reviewsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (var doc in reviewsSnapshot.docs) {
          totalRating += (doc['rating'] as num).toDouble();
        }

        double avgRating = totalRating / reviewsSnapshot.docs.length;

        // Обновляем рейтинг в документе Tours/{tourId}
        await FirebaseFirestore.instance
            .collection('Tours')
            .doc(widget.tourId)
            .update({'rating': avgRating});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Отзыв успешно добавлен!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Добавить отзыв')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text('Оценка тура:', style: TextStyle(fontSize: 16)),
              Slider(
                min: 1,
                max: 5,
                divisions: 4,
                label: _rating.toStringAsFixed(1),
                value: _rating,
                onChanged: (val) {
                  setState(() {
                    _rating = val;
                  });
                },
              ),
              TextFormField(
                controller: _reviewController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Ваш отзыв',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите текст отзыва';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _isSubmitting
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitReview,
                      child: Text('Отправить'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
