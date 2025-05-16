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
  final userId = FirebaseAuth.instance.currentUser!.uid;

  Map<String, dynamic>? userInfo;
  List<Map<String, dynamic>> tourBookings = [];
  List<Map<String, dynamic>> hotelBookings = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

      print("UID пользователя: $userId");
      print("Туров найдено (с фильтром): ${toursSnapshot.docs.length}");
      for (var doc in toursSnapshot.docs) {
        print("Тур: ${doc.data()}");
      }

      print("Отелей найдено: ${hotelsSnapshot.docs.length}");
      for (var doc in hotelsSnapshot.docs) {
        print("Отель: ${doc.data()}");
      }

      setState(() {
        userInfo = userDoc.data();

        // Теперь туры уже отфильтрованы сервером
        tourBookings = toursSnapshot.docs.map((doc) => doc.data()).toList();

        hotelBookings = hotelsSnapshot.docs.map((doc) => doc.data()).toList();

        isLoading = false;
      });
    } catch (e) {
      print('Ошибка при загрузке профиля: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildUserInfo() {
    if (userInfo == null) return Text('Не удалось загрузить данные пользователя');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Имя: ${userInfo!['name'] ?? '-'}', style: TextStyle(fontSize: 18)),
          Text('Email: ${userInfo!['email'] ?? '-'}', style: TextStyle(fontSize: 18)),
          Text('Телефон: ${userInfo!['phone'] ?? '-'}', style: TextStyle(fontSize: 18)),
          Text('Язык: ${userInfo!['language'] ?? '-'}', style: TextStyle(fontSize: 18)),
          Text(
            'Последний вход: ${_formatTimestamp(userInfo!['lastLogin'])}',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildTourBookings() {
    if (tourBookings.isEmpty) return Center(child: Text('Нет бронирований туров'));

    return ListView.builder(
      itemCount: tourBookings.length,
      itemBuilder: (context, index) {
        final bookingt = tourBookings[index];
        final timestampValue = bookingt['date'] ?? bookingt['timestamp'];

        return ListTile(
          leading: Icon(Icons.card_travel),
          title: Text('Тур: ${bookingt['tourId'] ?? 'Неизвестно'}'),
          subtitle: Text(
            'Дата: ${_formatTimestamp(timestampValue)}\n'
            'Людей: ${bookingt['numberOfPeople'] ?? '-'}\n'
            'Сумма: \$${bookingt['totalPrice'] ?? '-'}',
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
        final booking = hotelBookings[index];
        return ListTile(
          leading: Icon(Icons.hotel),
          title: Text('Отель: ${booking['hotelName']}'),
          subtitle: Text('Дата: ${_formatTimestamp(booking['timestamp'])}'),
        );
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '-';
    try {
      final date = (timestamp as Timestamp).toDate();
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    } catch (e) {
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
        title: Text('Профиль'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Инфо'),
            Tab(text: 'Туры'),
            Tab(text: 'Отели'),
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
              ],
            ),
    );
  }
}
