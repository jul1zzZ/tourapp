import 'package:flutter/material.dart';
import 'package:flutter_application_1/admscreen/TourListScreen.dart';
import 'package:flutter_application_1/admscreen/UserListScreen.dart';
import 'package:flutter_application_1/admscreen/BookingListScreen .dart';
import 'package:flutter_application_1/screens/login_screen.dart'; // <-- Убедись, что путь корректный
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_chats_list_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Админ-панель'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () async {
              await FirebaseAuth.instance.signOut(); // Выход из Firebase
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false, // Удаляет все предыдущие маршруты
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.grid_view),
            title: Text('Управление турами'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TourListScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Пользователи и брони'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserListScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('Все брони'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookingListScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.chat),
            title: Text('Чаты с пользователями'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminChatsListScreen()),
    );
  },
),
        ],
      ),
    );
  }
}
