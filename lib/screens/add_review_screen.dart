import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddReviewScreen extends StatefulWidget {
  final String tourId;
  final String bookingId;

  const AddReviewScreen({
    super.key,
    required this.tourId,
    required this.bookingId,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 3.0;
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь не авторизован')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('reviews').add({
        'tourId': widget.tourId,
        'bookingId': widget.bookingId,
        'userId': userId,
        'rating': _rating,
        'review': _reviewController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

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

        await FirebaseFirestore.instance
            .collection('Tours')
            .doc(widget.tourId)
            .update({'rating': avgRating});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отзыв успешно добавлен!')),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить отзыв'),
        centerTitle: true,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          color: colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Оцените тур',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      showValueIndicator: ShowValueIndicator.always,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                    ),
                    child: Slider(
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
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _reviewController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                      labelText: 'Ваш отзыв',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите текст отзыва';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  _isSubmitting
                      ? const CircularProgressIndicator()
                      : FilledButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text('Отправить'),
                          onPressed: _submitReview,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
