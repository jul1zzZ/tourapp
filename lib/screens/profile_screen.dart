import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final userId = FirebaseAuth.instance.currentUser!.uid;

  Map<String, dynamic>? userInfo;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> tourBookings = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> hotelBookings = [];

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

      setState(() {
        userInfo = userDoc.data();
        tourBookings = toursSnapshot.docs;
        hotelBookings = hotelsSnapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      print('Ошибка при загрузке профиля: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _editBooking({
    required String docId,
    required String collection,
    required int currentPeople,
    required Timestamp currentDate,
  }) async {
    final peopleController = TextEditingController(text: currentPeople.toString());
    Timestamp updatedDate = currentDate;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Редактировать бронирование'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: peopleController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Количество людей'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final pickedDate = await DatePicker.showDateTimePicker(
                  context,
                  showTitleActions: true,
                  minTime: DateTime.now(),
                  currentTime: currentDate.toDate(),
                );
                if (pickedDate != null) {
                  updatedDate = Timestamp.fromDate(pickedDate);
                }
              },
              child: Text('Изменить дату'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection(collection).doc(docId).update({
                  'numberOfPeople': int.tryParse(peopleController.text) ?? currentPeople,
                  'timestamp': updatedDate,
                });
                Navigator.pop(context);
                _fetchUserData();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Бронирование обновлено')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
              }
            },
            child: Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(String docId, String collection) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Отмена бронирования'),
        content: Text('Вы уверены, что хотите отменить бронирование?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Нет')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Да')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Бронирование отменено')));
        _fetchUserData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка при отмене: $e')));
      }
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
        final timestampValue = booking['date'] ?? booking['timestamp'];
        final status = booking['status'] ?? 'Ожидает';

        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            leading: Icon(Icons.card_travel),
            title: Text('Тур: ${booking['tourId'] ?? 'Неизвестно'}'),
            subtitle: Text(
              'Дата: ${_formatTimestamp(timestampValue)}\n'
              'Людей: ${booking['numberOfPeople'] ?? '-'}\n'
              'Сумма: \$${booking['totalPrice'] ?? '-'}\n'
              'Статус: $status',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _editBooking(
                    docId: doc.id,
                    collection: 'Bookings',
                    currentPeople: booking['numberOfPeople'] ?? 1,
                    currentDate: booking['timestamp'] ?? Timestamp.now(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _cancelBooking(doc.id, 'Bookings'),
                ),
              ],
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _editBooking(
                    docId: doc.id,
                    collection: 'hotel_booking',
                    currentPeople: booking['numberOfPeople'] ?? 1,
                    currentDate: booking['timestamp'] ?? Timestamp.now(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _cancelBooking(doc.id, 'hotel_booking'),
                ),
              ],
            ),
          ),
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
