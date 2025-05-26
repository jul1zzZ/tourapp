import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/admscreen/TourEditScreen.dart';

class TourListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final toursRef = FirebaseFirestore.instance.collection('Tours');

    return Scaffold(
      appBar: AppBar(
        title: Text('Туры'),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: toursRef.orderBy('destination').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка при загрузке туров'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Список туров пуст'));
          }

          final tours = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tours.length,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemBuilder: (context, index) {
              final tour = tours[index];
              final data = tour.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 6),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text(
                    data['destination'] ?? 'Без названия',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    data['description'] ?? 'Без описания',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blueAccent),
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
                        icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: 'Удалить',
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
                                  child: Text('Удалить', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await tour.reference.delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Тур удалён')),
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
