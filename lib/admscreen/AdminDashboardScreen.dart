import 'package:flutter/material.dart';
import 'package:flutter_application_1/admscreen/TourListScreen.dart';
import 'package:flutter_application_1/admscreen/UserListScreen.dart';
import 'BookingListScreen .dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_chats_list_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final List<_AdminOption> options = [
    _AdminOption(
      icon: Icons.grid_view,
      title: 'Управление турами',
      screen: TourListScreen(),
    ),
    _AdminOption(
      icon: Icons.person,
      title: 'Пользователи и брони',
      screen: UserListScreen(),
    ),
    _AdminOption(
      icon: Icons.history,
      title: 'Все брони',
      screen: BookingListScreen(),
    ),
    _AdminOption(
      icon: Icons.chat,
      title: 'Чаты с пользователями',
      screen: AdminChatsListScreen(),
    ),
  ];

  void _navigateWithFade(BuildContext context, Widget page) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: Duration(milliseconds: 400),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Админ-панель'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: options.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final option = options[index];
            return GestureDetector(
              onTap: () => _navigateWithFade(context, option.screen),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                color: isDark ? Colors.grey[800] : Colors.blueAccent,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(option.icon, size: 40, color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        option.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AdminOption {
  final IconData icon;
  final String title;
  final Widget screen;

  const _AdminOption({
    required this.icon,
    required this.title,
    required this.screen,
  });
}

