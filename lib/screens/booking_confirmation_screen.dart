import 'package:flutter/material.dart';
import 'package:flutter_application_1/navigate/bottom_navbar_adm.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final String hotelName;

  const BookingConfirmationScreen({
    super.key,
    required this.hotelName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Подтверждение'),
        centerTitle: true,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Бронирование подтверждено!',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Вы успешно забронировали отель:\n«$hotelName»',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    icon: const Icon(Icons.home),
                    label: const Text('На главную'),
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BottomNavbar(isAdmin: false)));
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
