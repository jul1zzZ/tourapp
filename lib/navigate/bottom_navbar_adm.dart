import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      UserProfileScreen(),
      ChatScreen(currentUserId: userId),
    ];

    final adminPages = [AdminDashboardScreen(), AdminChatsListScreen()];

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('chats')
              .where('userId', isEqualTo: userId)
              .snapshots(),
      builder: (context, chatSnapshot) {
        if (!chatSnapshot.hasData) {
          return _buildScaffold(
            userId,
            isWideScreen,
            userPages,
            adminPages,
            false,
          );
        }

        final chatDocs = chatSnapshot.data!.docs;
        if (chatDocs.isEmpty) {
          return _buildScaffold(
            userId,
            isWideScreen,
            userPages,
            adminPages,
            false,
          );
        }

        final chatId = chatDocs.first.id;

        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .where('senderId', isNotEqualTo: userId)
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
          builder: (context, messageSnapshot) {
            final hasUnread =
                messageSnapshot.hasData &&
                messageSnapshot.data!.docs.isNotEmpty;
            return _buildScaffold(
              userId,
              isWideScreen,
              userPages,
              adminPages,
              hasUnread,
            );
          },
        );
      },
    );
  }

  Widget _buildScaffold(
    String userId,
    bool isWideScreen,
    List<Widget> userPages,
    List<Widget> adminPages,
    bool hasUnread,
  ) {
    final userDestinations = [
      const NavigationDestination(
        icon: Icon(Icons.search),
        selectedIcon: Icon(Icons.search_outlined),
        label: 'Поиск',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person),
        selectedIcon: Icon(Icons.person_outline),
        label: 'Профиль',
      ),
      NavigationDestination(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.chat_bubble_outline),
            if (hasUnread)
              const Positioned(
                top: -2,
                right: -2,
                child: CircleAvatar(radius: 5, backgroundColor: Colors.red),
              ),
          ],
        ),
        selectedIcon: const Icon(Icons.chat),
        label: 'Поддержка',
      ),
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

    final destinations = widget.isAdmin ? adminDestinations : userDestinations;
    final pages = widget.isAdmin ? adminPages : userPages;

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
              destinations:
                  destinations
                      .map(
                        (d) => NavigationRailDestination(
                          icon: d.icon,
                          selectedIcon: d.selectedIcon,
                          label: Text(d.label),
                        ),
                      )
                      .toList(),
            ),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar:
          isWideScreen
              ? null
              : NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                destinations: destinations,
              ),
    );
  }
}
