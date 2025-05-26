import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/search_tour_screen.dart';
import 'package:flutter_application_1/screens/profile_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/hotel_booking_screen.dart';
import 'package:flutter_application_1/admscreen/AdminDashboardScreen.dart';
import '../admscreen/admin_chats_list_screen.dart';

class BottomNavbar extends StatefulWidget {
  final bool isAdmin;

  const BottomNavbar({super.key, required this.isAdmin});

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final isWideScreen = MediaQuery.of(context).size.width >= 600;

    final userPages = [
       SearchToursScreen(),
       HotelBookingScreen(),
       UserProfileScreen(),
      ChatScreen(currentUserId: userId),
    ];

    final userDestinations = const [
      NavigationDestination(
        icon: Icon(Icons.search),
        selectedIcon: Icon(Icons.search_outlined),
        label: 'Поиск',
      ),
      NavigationDestination(
        icon: Icon(Icons.hotel),
        selectedIcon: Icon(Icons.hotel_outlined),
        label: 'Отели',
      ),
      NavigationDestination(
        icon: Icon(Icons.person),
        selectedIcon: Icon(Icons.person_outline),
        label: 'Профиль',
      ),
      NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        selectedIcon: Icon(Icons.chat),
        label: 'Поддержка',
      ),
    ];

    final adminPages = [
       AdminDashboardScreen(),
       AdminChatsListScreen(),
    ];

    final adminDestinations = const [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Панель',
      ),
      NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        selectedIcon: Icon(Icons.chat),
        label: 'Чаты',
      ),
    ];

    final pages = widget.isAdmin ? adminPages : userPages;
    final destinations = widget.isAdmin ? adminDestinations : userDestinations;

    return Scaffold(
      body: Row(
        children: [
          if (isWideScreen)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: destinations
                  .map((d) => NavigationRailDestination(
                        icon: d.icon,
                        selectedIcon: d.selectedIcon,
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              animationDuration: const Duration(milliseconds: 400),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: destinations,
            ),
    );
  }
}
