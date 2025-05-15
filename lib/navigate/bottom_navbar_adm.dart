import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/screens/search_tour_screen.dart';
import 'package:flutter_application_1/screens/chat_screen.dart';
import 'package:flutter_application_1/screens/profile_screen.dart';


class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String? _role;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        _role = snapshot.data()?['role'] ?? 'user';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isAdmin = _role == 'admin';

    final userPages = [
      SearchToursScreen(),
      UserProfileScreen(),
      ChatScreen(
        currentUserId: FirebaseAuth.instance.currentUser!.uid,)
    ];

    final userNavItems = const [
      BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Поиск'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
      BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Поддержка'),
    ];

    return Scaffold(
      body: userPages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: isAdmin ? [] : userNavItems,
      ),
    );
  }
}
