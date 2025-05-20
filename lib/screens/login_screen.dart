import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'register_screen.dart';
import 'password_recovery_screen.dart';
import 'package:flutter_application_1/screens/search_tour_screen.dart';
import 'package:flutter_application_1/admscreen/AdminDashboardScreen.dart'; 
import 'package:flutter_application_1/navigate/bottom_navbar_adm.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    requestNotificationPermission();
  }

  Future<void> requestNotificationPermission() async {
    // Запрос разрешений на уведомления (важно для iOS)
    await FirebaseMessaging.instance.requestPermission();
  }

  Future<void> saveUserFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
        print('FCM Token сохранён: $token');
      }
    } catch (e) {
      print('Ошибка при сохранении FCM Token: $e');
    }
  }

  Future<void> _loginUser() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Пожалуйста, введите email и пароль.';
      });
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          throw Exception('Пользователь не найден в базе данных.');
        }

        final role = userDoc.get('role');

        await saveUserFCMToken();

        if (role == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminDashboardScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BottomNavbar(isAdmin: false)));
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        if (e.code == 'user-not-found') {
          _errorMessage = 'Пользователь с таким email не найден.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Неверный пароль.';
        } else if (e.code == 'too-many-requests') {
          _errorMessage = 'Слишком много попыток входа. Попробуйте позже.';
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      print('Ошибка входа: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Произошла ошибка: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Вход")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Пароль'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _loginUser,
                    child: Text('Войти'),
                  ),
            if (_errorMessage != null) ...[
              SizedBox(height: 20),
              Text(_errorMessage!, style: TextStyle(color: Colors.red)),
            ],
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PasswordRecoveryScreen()),
                );
              },
              child: Text('Забыли пароль?'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegistrationScreen()),
                );
              },
              child: Text('Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}
