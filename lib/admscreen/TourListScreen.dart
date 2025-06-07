import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/admscreen/TourEditScreen.dart';

class TourListScreen extends StatelessWidget {
  const TourListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final toursRef = FirebaseFirestore.instance.collection('tours');

    return Scaffold(
      appBar: AppBar(title: const Text('Туры'), backgroundColor: Colors.teal),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Добавить тур',
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => TourEditScreen(),
              transitionsBuilder: (_, anim, __, child) {
                return FadeTransition(opacity: anim, child: child);
              },
            ),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: toursRef.orderBy('title').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Ошибка при загрузке туров'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Список туров пуст'));
          }

          final tours = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tours.length,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemBuilder: (context, index) {
              final tour = tours[index];
              final data = tour.data() as Map<String, dynamic>;

              final hotel = data['hotel'] ?? {};
              final flight = data['flight'] ?? {};

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading:
                      data['imageUrl'] != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              data['imageUrl'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                          : const Icon(
                            Icons.image,
                            size: 60,
                            color: Colors.grey,
                          ),
                  title: Text(
                    data['title'] ?? 'Без названия',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('${data['city'] ?? '-'}, ${data['country'] ?? '-'}'),
                      Text('Категория: ${data['category'] ?? '-'}'),
                      if (hotel['name'] != null)
                        Text(
                          'Отель: ${hotel['name']} ★${hotel['stars'] ?? ''}',
                        ),
                      if (data['basePrice'] != null)
                        Text('Базовая цена: ${data['basePrice']} ₽'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        tooltip: 'Редактировать',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TourEditScreen(tourId: tour.id),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        tooltip: 'Удалить',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Удалить тур?'),
                                  content: const Text(
                                    'Вы уверены, что хотите удалить этот тур?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('Отмена'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: const Text(
                                        'Удалить',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                          );

                          if (confirm == true) {
                            await tour.reference.delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Тур удалён')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
