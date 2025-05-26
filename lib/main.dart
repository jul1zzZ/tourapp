import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Сообщение в фоне: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late FirebaseMessaging _messaging;

  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
  }

  void _initFirebaseMessaging() async {
    _messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Пользователь разрешил уведомления');

      String? token = await _messaging.getToken();
      print('FCM Token: $token');

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Уведомление в foreground: ${message.messageId}');
        if (message.notification != null) {
          final title = message.notification!.title ?? '';
          final body = message.notification!.body ?? '';

          showDialog(
            context: navigatorKey.currentContext!,
            builder: (_) => AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(navigatorKey.currentContext!).pop(),
                  child: const Text('ОК'),
                ),
              ],
            ),
          );
        }
      });
    } else {
      print('Пользователь отказался от уведомлений');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(), // или FadeUpwardsPageTransitionsBuilder()
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: LoginScreen(),
    );
  }
}
