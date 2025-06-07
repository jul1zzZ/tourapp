import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final User? user = FirebaseAuth.instance.currentUser;

  Map<String, dynamic>? userInfo;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> tourBookings = [];
  Map<String, int> favoriteToursCount = {};
  List<String> topTourTitles = [];
  Set<String> reviewedTourIds = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user == null) return;

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();

      final bookingsSnap =
          await FirebaseFirestore.instance
              .collection('Bookings')
              .where('email', isEqualTo: user!.email)
              .get();

      final reviewsSnap =
          await FirebaseFirestore.instance
              .collection('Reviews')
              .where('email', isEqualTo: user!.email)
              .get();

      final reviewedIds =
          reviewsSnap.docs.map((doc) => doc['tourId'] as String).toSet();

      final Map<String, int> counts = {};
      for (final doc in bookingsSnap.docs) {
        final title = doc['tourTitle'];
        if (title is String && title.isNotEmpty) {
          counts[title] = (counts[title] ?? 0) + 1;
        }
      }

      final sortedTours =
          counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        userInfo = userDoc.data();
        tourBookings = bookingsSnap.docs;
        favoriteToursCount = counts;
        topTourTitles = sortedTours.take(3).map((e) => e.key).toList();
        reviewedTourIds = reviewedIds;
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

  void _showReviewDialog(String tourId, String tourTitle) {
    final controller = TextEditingController();
    int rating = 5;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Отзыв о "$tourTitle"'),
            content: StatefulBuilder(
              builder: (context, setStateDialog) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      decoration: InputDecoration(hintText: 'Введите отзыв'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return IconButton(
                          icon: Icon(
                            Icons.star,
                            color: rating >= star ? Colors.amber : Colors.grey,
                          ),
                          onPressed: () => setStateDialog(() => rating = star),
                        );
                      }),
                    ),
                    Text('Оценка: $rating звёзд'),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                child: const Text('Отмена'),
                onPressed: () => Navigator.pop(context),
              ),
              FilledButton(
                child: const Text('Отправить'),
                onPressed: () async {
                  final reviewText = controller.text.trim();
                  if (reviewText.isEmpty) return;

                  await FirebaseFirestore.instance.collection('Reviews').add({
                    'tourId': tourId,
                    'tourTitle': tourTitle,
                    'email': user!.email,
                    'reviewText': reviewText,
                    'rating': rating,
                    'createdAt': Timestamp.now(),
                  });

                  setState(() {
                    reviewedTourIds.add(tourId);
                  });

                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  Widget _infoTile(String label, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(value ?? '-', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildUserInfo() {
    if (userInfo == null) {
      return const Center(
        child: Text('Не удалось загрузить данные пользователя'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 16),
          Text(
            userInfo!['name'] ?? 'Имя отсутствует',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _infoTile('Email', userInfo!['email']),
          _infoTile('Телефон', userInfo!['phone']),
          _infoTile('Язык', userInfo!['language']),
          _infoTile('Последний вход', _formatTimestamp(userInfo!['lastLogin'])),
        ],
      ),
    );
  }

  Widget _buildTourBookings() {
    if (tourBookings.isEmpty) {
      return const Center(child: Text('У вас пока нет бронирований.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tourBookings.length,
      itemBuilder: (context, index) {
        final booking = tourBookings[index].data();
        final tourId = booking['tourId'];
        final tourTitle = booking['tourTitle'];
        final alreadyReviewed = reviewedTourIds.contains(tourId);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tourTitle ?? 'Название отсутствует',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Дата: ${_formatTimestamp(booking['bookingDate'])}'),
                Text('Туристов: ${booking['touristsCount'] ?? '-'}'),
                Text('Сумма: ${booking['totalPrice'] ?? '-'} ₽'),
                Text('Статус: ${booking['status'] ?? 'Ожидает'}'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed:
                      alreadyReviewed
                          ? null
                          : () => _showReviewDialog(tourId, tourTitle),
                  child: Text(
                    alreadyReviewed ? 'Отзыв оставлен' : 'Оставить отзыв',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoriteTours() {
    if (topTourTitles.isEmpty) {
      return const Center(child: Text('Нет популярных туров'));
    }

    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('tours')
              .where('title', whereIn: topTourTitles)
              .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Не удалось загрузить туры'));
        }

        final tours = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tours.length,
          itemBuilder: (context, index) {
            final tour = tours[index].data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tour['title'] ?? 'Название отсутствует',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Город: ${tour['city'] ?? '-'}'),
                    Text('Страна: ${tour['country'] ?? '-'}'),
                    Text('Цена: ${tour['basePrice'] ?? '-'} ₽'),
                    Text(
                      'Бронирований: ${favoriteToursCount[tour['title']] ?? 0}',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
        title: const Text('Профиль пользователя'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Инфо'),
            Tab(icon: Icon(Icons.history), text: 'Бронирования'),
            Tab(icon: Icon(Icons.star), text: 'Популярное'),
          ],
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildUserInfo(),
                  _buildTourBookings(),
                  _buildFavoriteTours(),
                ],
              ),
    );
  }
}
