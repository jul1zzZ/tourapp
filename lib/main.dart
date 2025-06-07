import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models//init_tours.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Сообщение в фоне: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeTours();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late FirebaseMessaging _messaging;

  @override
  void initState() {
    super.initState();
    addLocationsToHotels(); // вызов функции обновления данных
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
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Уведомление в foreground: ${message.messageId}');
        if (message.notification != null) {
          final title = message.notification!.title ?? '';
          final body = message.notification!.body ?? '';

          showDialog(
            context: navigatorKey.currentContext!,
            builder:
                (_) => AlertDialog(
                  title: Text(title),
                  content: Text(body),
                  actions: [
                    TextButton(
                      onPressed:
                          () =>
                              Navigator.of(navigatorKey.currentContext!).pop(),
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

  final Map<String, Map<String, double>> cityCoordinates = {
    'Афины': {'lat': 37.9715, 'lng': 23.7267},
    'Барселона': {'lat': 41.3851, 'lng': 2.1734},
    'Прага': {'lat': 50.0755, 'lng': 14.4378},
    'Стамбул': {'lat': 41.0082, 'lng': 28.9784},
    'Бангкок': {'lat': 13.7563, 'lng': 100.5018},
    'Токио': {'lat': 35.6762, 'lng': 139.6503},
    'Париж': {'lat': 48.8566, 'lng': 2.3522},
    'Дубай': {'lat': 25.2048, 'lng': 55.2708},
    'Рим': {'lat': 41.9028, 'lng': 12.4964},
    'Каир': {'lat': 30.0444, 'lng': 31.2357},
  };

  Future<void> addLocationsToHotels() async {
    final collection = FirebaseFirestore.instance.collection('tours');
    final snapshot = await collection.get();

    for (final doc in snapshot.docs) {
      final city = doc.get('city');
      final coords = cityCoordinates[city];

      if (coords != null) {
        await doc.reference.update({
          'hotel.location': {'lat': coords['lat'], 'lng': coords['lng']},
        });
        print('Updated document ${doc.id} with location for $city');
      } else {
        print('No coordinates found for city: $city (doc id: ${doc.id})');
      }
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
            TargetPlatform.android:
                CupertinoPageTransitionsBuilder(), // или FadeUpwardsPageTransitionsBuilder()
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
