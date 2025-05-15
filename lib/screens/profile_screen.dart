import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Профиль')),
      body: Center(child: Text('Здесь будет профиль пользователя')),
    );
  }
}
