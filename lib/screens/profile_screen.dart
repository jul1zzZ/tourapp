import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Map<String, dynamic>? userInfo;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> tourBookings = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> hotelBookings = [];
  Map<String, int> favoriteToursCount = {};
  List<String> topTourIds = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      final toursSnapshot = await FirebaseFirestore.instance
          .collection('Bookings')
          .where('userId', isEqualTo: userId)
          .get();

      final hotelsSnapshot = await FirebaseFirestore.instance
          .collection('hotel_booking')
          .where('userId', isEqualTo: userId)
          .get();

      final Map<String, int> counts = {};
      for (var doc in toursSnapshot.docs) {
        final tourId = doc['tourId'];
        if (tourId != null) {
          counts[tourId] = (counts[tourId] ?? 0) + 1;
        }
      }

      final sortedTours = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        userInfo = userDoc.data();
        tourBookings = toursSnapshot.docs;
        hotelBookings = hotelsSnapshot.docs;
        favoriteToursCount = counts;
        topTourIds = sortedTours.take(3).map((e) => e.key).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Ошибка при загрузке данных: $e');
      setState(() => isLoading = false);
    }
  }

  Widget _buildUserInfo() {
    if (userInfo == null) return Center(child: Text('Не удалось загрузить данные пользователя'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Имя: ${userInfo!['name'] ?? '-'}', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('Email: ${userInfo!['email'] ?? '-'}', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('Телефон: ${userInfo!['phone'] ?? '-'}', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('Язык: ${userInfo!['language'] ?? '-'}', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('Последний вход: ${_formatTimestamp(userInfo!['lastLogin'])}', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildTourBookings() {
  if (tourBookings.isEmpty) return Center(child: Text('Нет бронирований туров'));

  return ListView.builder(
    itemCount: tourBookings.length,
    itemBuilder: (context, index) {
      final doc = tourBookings[index];
      final booking = doc.data();
      final timestamp = booking['date'] ?? booking['timestamp'];
      final status = booking['status'] ?? 'Ожидает';

      return Card(
        margin: EdgeInsets.all(8),
        child: ListTile(
          leading: Icon(Icons.flight),
          title: Text('Тур: ${booking['tourId'] ?? 'Неизвестно'}'),
          subtitle: Text(
            'Дата: ${_formatTimestamp(timestamp)}\n'
            'Людей: ${booking['numberOfPeople'] ?? '-'}\n'
            'Сумма: ${booking['totalPrice'] ?? '-'} ₽\n'
            'Статус: $status',
          ),
          trailing: ElevatedButton(
            child: Text('Оставить отзыв'),
            onPressed: () async {
              // Ищем реальный документ тура по полю destination
              final toursSnapshot = await FirebaseFirestore.instance
                  .collection('Tours')
                  .where('destination', isEqualTo: booking['tourId'])
                  .limit(1)
                  .get();

              if (toursSnapshot.docs.isNotEmpty) {
                final realTourId = toursSnapshot.docs.first.id;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddReviewScreen(
                      tourId: realTourId,
                      bookingId: doc.id,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Тур не найден')),
                );
              }
            },
          ),
        ),
      );
    },
  );
}


  Widget _buildHotelBookings() {
    if (hotelBookings.isEmpty) return Center(child: Text('Нет бронирований отелей'));

    return ListView.builder(
      itemCount: hotelBookings.length,
      itemBuilder: (context, index) {
        final doc = hotelBookings[index];
        final booking = doc.data();
        final status = booking['status'] ?? 'Ожидает';

        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            leading: Icon(Icons.hotel),
            title: Text('Отель: ${booking['hotelName'] ?? 'Неизвестно'}'),
            subtitle: Text(
              'Дата: ${_formatTimestamp(booking['timestamp'])}\n'
              'Статус: $status',
            ),
          ),
        );
      },
    );
  }

 Widget _buildFavoriteTours() {
  if (topTourIds.isEmpty) return Center(child: Text('Нет любимых туров'));

  return FutureBuilder<QuerySnapshot>(
    future: FirebaseFirestore.instance
        .collection('Tours')
        .where('destination', whereIn: topTourIds)
        .get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(child: Text('Не удалось загрузить туры'));
      }

      final tours = snapshot.data!.docs;

      return ListView.builder(
        itemCount: tours.length,
        itemBuilder: (context, index) {
          final tourDoc = tours[index];
          final tour = tourDoc.data() as Map<String, dynamic>;
          final tourName = tour['destination'] ?? '—';

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('reviews')
                .where('tourId', isEqualTo: tourDoc.id)
                .get(),
            builder: (context, reviewSnapshot) {
              if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                return ListTile(
                  title: Text('${tour['city']} → $tourName'),
                  subtitle: Text('Загрузка рейтинга...'),
                );
              }

              double avgRating = 0;
              if (reviewSnapshot.hasData && reviewSnapshot.data!.docs.isNotEmpty) {
                final ratings = reviewSnapshot.data!.docs
                    .map((doc) => (doc.data() as Map<String, dynamic>)['rating']?.toDouble() ?? 0)
                    .toList();
                avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
              }

              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  leading: Icon(Icons.favorite, color: Colors.red),
                  title: Text('${tour['city']} → $tourName'),
                  subtitle: Text(
                    'Отель: ${tour['hotel']}\n'
                    'Цена: ${tour['price']} ₽\n'
                    'Рейтинг: ${avgRating > 0 ? avgRating.toStringAsFixed(1) : '-'} ★\n'
                    'Бронирований: ${favoriteToursCount[tourName] ?? 0} раз',
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}


  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '-';
    try {
      final date = (timestamp as Timestamp).toDate();
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    } catch (_) {
      return '-';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль пользователя'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Инфо'),
            Tab(text: 'Туры'),
            Tab(text: 'Отели'),
            Tab(text: 'Любимые'),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUserInfo(),
                _buildTourBookings(),
                _buildHotelBookings(),
                _buildFavoriteTours(),
              ],
            ),
    );
  }
}

class AddReviewScreen extends StatefulWidget {
  final String tourId;
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

    final userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance.collection('reviews').add({
        'tourId': widget.tourId,
        'bookingId': widget.bookingId,
        'userId': userId,
        'rating': _rating,
        'review': _reviewController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Отзыв успешно добавлен')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении отзыва: $e')),
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
      appBar: AppBar(
        title: Text('Добавить отзыв'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text('Оцените тур:', style: TextStyle(fontSize: 16)),
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
              SizedBox(height: 16),
              TextFormField(
                controller: _reviewController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Ваш отзыв',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Пожалуйста, введите отзыв';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _isSubmitting
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitReview,
                      child: Text('Отправить отзыв'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
