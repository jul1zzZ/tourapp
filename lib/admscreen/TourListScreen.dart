import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/admscreen/TourEditScreen.dart';

class TourListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final toursRef = FirebaseFirestore.instance.collection('Tours');

    return Scaffold(
      appBar: AppBar(title: Text('Туры')),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TourEditScreen()),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: toursRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Ошибка при загрузке туров: ${snapshot.error}');
            return Center(child: Text('Ошибка при загрузке туров'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print('Нет данных о турах');
            return Center(child: Text('Список туров пуст'));
          }

          final tours = snapshot.data!.docs;

          print('Загружено туров: ${tours.length}');
          for (var doc in tours) {
            print('Тур: ${doc.id}, данные: ${doc.data()}');
          }

          return ListView.builder(
            itemCount: tours.length,
            itemBuilder: (context, index) {
              final tour = tours[index];
              final data = tour.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['destination'] ?? 'Без названия'),
                subtitle: Text(data['description'] ?? 'Без описания'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
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
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Удалить тур?'),
                            content: Text('Вы уверены, что хотите удалить этот тур?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Отмена'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Удалить'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await tour.reference.delete();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
