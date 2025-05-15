import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> initDatabase() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // 1. Создание пользователя
  await firestore.collection('users').doc('user_test_001').set({
    'name': 'Тест Пользователь',
    'email': 'testuser@mail.com',
    'phone': '+70000000000',
    'photoUrl': '',
    'favorites': [],
    'language': 'ru',
    'createdAt': FieldValue.serverTimestamp(),
    'lastLogin': FieldValue.serverTimestamp(),
  });

  // 2. Создание тура
  await firestore.collection('tours').doc('tour_test_001').set({
    'title': 'Тест Тур: Мальдивы',
    'description': 'Тестовый тур на пляжный отдых.',
    'location': {
      'country': 'Мальдивы',
      'city': 'Мале',
      'coordinates': {
        'lat': 4.1755,
        'lng': 73.5093,
      },
    },
    'price': 1500,
    'rating': 4.8,
    'tags': ['пляжный', 'экзотика'],
    'startDate': Timestamp.now(),
    'endDate': Timestamp.now(),
    'images': [],
    'availableSeats': 10,
  });

  // 3. Создание бронирования
  await firestore.collection('bookings').doc('booking_test_001').set({
    'userId': 'user_test_001',
    'tourId': 'tour_test_001',
    'status': 'confirmed',
    'paymentStatus': 'paid',
    'bookingDate': FieldValue.serverTimestamp(),
    'travelers': 2,
    'totalPrice': 3000,
  });

  // 4. Создание чата
  final chatRef = firestore.collection('chats').doc('chat_test_001');
  await chatRef.set({
    'participants': ['user_test_001', 'admin_test_001'],
    'lastMessage': 'Здравствуйте! Чем могу помочь?',
    'lastMessageTime': FieldValue.serverTimestamp(),
  });

  await chatRef.collection('messages').add({
    'senderId': 'admin_test_001',
    'message': 'Здравствуйте! Чем могу помочь?',
    'sentAt': FieldValue.serverTimestamp(),
  });

  // 5. Добавление акции
  await firestore.collection('promotions').doc('promo_test_001').set({
    'title': 'Тестовая акция: Скидка 20%',
    'description': 'Только до конца месяца!',
    'startDate': Timestamp.now(),
    'endDate': Timestamp.now(),
    'imageUrl': 'https://example.com/promo.jpg',
  });

  // 6. Информация о визе
  await firestore.collection('visa_info').doc('MV').set({
    'country': 'Мальдивы',
    'requirements': [
      'Паспорт',
      'Бронирование отеля',
      'Билет туда-обратно'
    ],
    'visaRequired': false,
    'notes': 'Виза ставится по прилету.',
  });

  print('✅ База данных успешно инициализирована!');
}
