import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_review_screen.dart';

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

      final tourSnap = await FirebaseFirestore.instance
          .collection('Bookings')
          .where('userId', isEqualTo: userId)
          .get();

      final hotelSnap = await FirebaseFirestore.instance
          .collection('hotel_booking')
          .where('userId', isEqualTo: userId)
          .get();

      final Map<String, int> counts = {};
      for (var doc in tourSnap.docs) {
        final tourId = doc['tourId'];
        if (tourId != null) {
          counts[tourId] = (counts[tourId] ?? 0) + 1;
        }
      }

      final sortedTours = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        userInfo = userDoc.data();
        tourBookings = tourSnap.docs;
        hotelBookings = hotelSnap.docs;
        favoriteToursCount = counts;
        topTourIds = sortedTours.take(3).map((e) => e.key).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки данных: $e');
      setState(() => isLoading = false);
    }
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

  Widget _buildInfoTile(String label, IconData icon, String? value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(value ?? '-'),
      ),
    );
  }

  Widget _buildUserInfo() {
    if (userInfo == null) {
      return Center(child: Text('Не удалось загрузить данные пользователя'));
    }

    return ListView(
      children: [
        SizedBox(height: 16),
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.person, size: 40),
        ),
        SizedBox(height: 8),
        Center(child: Text(userInfo!['name'] ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        SizedBox(height: 16),
        _buildInfoTile('Email', Icons.email, userInfo!['email']),
        _buildInfoTile('Телефон', Icons.phone, userInfo!['phone']),
        _buildInfoTile('Язык', Icons.language, userInfo!['language']),
        _buildInfoTile('Последний вход', Icons.access_time, _formatTimestamp(userInfo!['lastLogin'])),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBookingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    Widget? action,
  }) {
    final color = status == 'Подтвержден'
        ? Colors.green
        : status == 'Отклонен'
            ? Colors.red
            : Colors.orange;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ],
            ),
            SizedBox(height: 8),
            Text(subtitle),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(label: Text(status), backgroundColor: color.withOpacity(0.2), labelStyle: TextStyle(color: color)),
                if (action != null) action,
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTourBookings() {
    if (tourBookings.isEmpty) return Center(child: Text('Нет бронирований туров'));

    return ListView.builder(
      itemCount: tourBookings.length,
      itemBuilder: (context, index) {
        final doc = tourBookings[index];
        final data = doc.data();
        final timestamp = data['date'] ?? data['timestamp'];

        return _buildBookingCard(
          icon: Icons.flight,
          title: 'Тур: ${data['tourId'] ?? '—'}',
          subtitle:
              'Дата: ${_formatTimestamp(timestamp)}\nЛюдей: ${data['numberOfPeople'] ?? '-'}\nСумма: ${data['totalPrice'] ?? '-'} ₽',
          status: data['status'] ?? 'Ожидает',
          action: ElevatedButton(
            onPressed: () => _handleReviewNavigation(context, doc),
            child: Text('Отзыв'),
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
        final data = doc.data();

        return _buildBookingCard(
          icon: Icons.hotel,
          title: 'Отель: ${data['hotelName'] ?? '—'}',
          subtitle: 'Дата: ${_formatTimestamp(data['timestamp'])}',
          status: data['status'] ?? 'Ожидает',
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
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text('Не удалось загрузить туры'));

        final tours = snapshot.data!.docs;

        return ListView.builder(
          itemCount: tours.length,
          itemBuilder: (context, index) {
            final tourDoc = tours[index];
            final tour = tourDoc.data() as Map<String, dynamic>;
            final destination = tour['destination'] ?? '—';

            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('tourId', isEqualTo: tourDoc.id)
                  .get(),
              builder: (context, reviewSnap) {
                double rating = 0;
                if (reviewSnap.hasData && reviewSnap.data!.docs.isNotEmpty) {
                  final ratings = reviewSnap.data!.docs.map((doc) {
                    return (doc.data() as Map<String, dynamic>)['rating']?.toDouble() ?? 0.0;
                  }).toList();
                  rating = ratings.reduce((a, b) => a + b) / ratings.length;
                }

                return _buildBookingCard(
                  icon: Icons.favorite,
                  title: '${tour['city']} → $destination',
                  subtitle: 'Отель: ${tour['hotel']}\nЦена: ${tour['price']} ₽\nРейтинг: ${rating.toStringAsFixed(1)} ★\nБронирований: ${favoriteToursCount[destination] ?? 0}',
                  status: 'Популярное',
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _handleReviewNavigation(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> bookingDoc) async {
    final data = bookingDoc.data();

    final tourQuery = await FirebaseFirestore.instance
        .collection('Tours')
        .where('destination', isEqualTo: data['tourId'])
        .limit(1)
        .get();

    if (tourQuery.docs.isNotEmpty) {
      final tourId = tourQuery.docs.first.id;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddReviewScreen(tourId: tourId, bookingId: bookingDoc.id),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Тур не найден')));
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
            Tab(icon: Icon(Icons.person), text: 'Инфо'),
            Tab(icon: Icon(Icons.flight), text: 'Туры'),
            Tab(icon: Icon(Icons.hotel), text: 'Отели'),
            Tab(icon: Icon(Icons.favorite), text: 'Любимые'),
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
