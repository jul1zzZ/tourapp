import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  @override
  _PasswordRecoveryScreenState createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _message;
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _message = null;
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      setState(() {
        _message = "Письмо отправлено!";
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      prefixIcon: Icon(icon),
      labelText: label,
      filled: true,
      fillColor: colorScheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Восстановление пароля"),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Иллюстрация
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Icon(
                  Icons.lock_reset_rounded,
                  size: 96,
                  color: colorScheme.primary,
                ),
              ),
              // Заголовок
              Text(
                "Забыли пароль?",
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Введите email, и мы отправим ссылку для сброса пароля.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // Форма
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _emailController,
                  decoration:
                      _inputDecoration('Email', Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value != null && value.contains('@')
                          ? null
                          : 'Введите корректный email',
                ),
              ),

              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.send),
                        label: const Text("Отправить письмо"),
                        onPressed: _resetPassword,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
              if (_message != null) ...[
                const SizedBox(height: 24),
                Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _message == "Письмо отправлено!"
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
