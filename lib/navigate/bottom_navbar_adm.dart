import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/search_tour_screen.dart';
import 'package:flutter_application_1/screens/profile_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/hotel_booking_screen.dart'; // 👈 импортируем экран бронирования
import 'package:flutter_application_1/admscreen/AdminDashboardScreen.dart';
import '../admscreen/admin_chats_list_screen.dart';

class BottomNavbar extends StatefulWidget {
  final bool isAdmin;

  BottomNavbar({required this.isAdmin});

  @override
  _BottomNavbarState createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final userPages = [
      SearchToursScreen(),
      HotelBookingScreen(), // 👈 добавили экран бронирования
      UserProfileScreen(),
      ChatScreen(currentUserId: FirebaseAuth.instance.currentUser!.uid,),
    ];

    final userNavItems = const [
      BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Поиск'),
      BottomNavigationBarItem(icon: Icon(Icons.hotel), label: 'Отели'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
      BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Поддержка'),
    ];

    final adminPages = [
      AdminDashboardScreen(),
      AdminChatsListScreen(),
    ];

    final adminNavItems = const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Панель'),
      BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Чаты'),
    ];

    return Scaffold(
      body: widget.isAdmin ? adminPages[_selectedIndex] : userPages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: widget.isAdmin ? adminNavItems : userNavItems,
        selectedItemColor: Colors.blue,       // цвет активного пункта
        unselectedItemColor: Colors.grey,     // цвет неактивных пунктов
        backgroundColor: Colors.white,         // фон панели (можно поменять)
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
