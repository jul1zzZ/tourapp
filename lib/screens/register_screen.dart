import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7 ### ### ##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rawPhone = phoneMaskFormatter.getUnmaskedText();
      if (rawPhone.length != 10 || !rawPhone.startsWith('9')) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Введите корректный номер телефона, начиная с 9 (пример: 9123456789)';
        });
        return;
      }

      final formattedPhone = '+7$rawPhone';

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': _emailController.text.trim(),
          'name': _nameController.text.trim(),
          'phone': formattedPhone,
          'photoUrl': '',
          'language': 'ru',
          'favorites': [],
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'role': 'user',
        });
      }

      Fluttertoast.showToast(
        msg: "Регистрация успешна!",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Регистрация"),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('Имя', Icons.person),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Введите имя' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: _inputDecoration('Телефон', Icons.phone),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [phoneMaskFormatter],
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Введите телефон' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration('Email', Icons.email),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value != null && value.contains('@')
                      ? null
                      : 'Введите корректный email',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: _inputDecoration('Пароль', Icons.lock),
                  obscureText: true,
                  validator: (value) =>
                      value != null && value.length >= 6
                          ? null
                          : 'Минимум 6 символов',
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _registerUser,
                          icon: const Icon(Icons.check),
                          label: const Text('Зарегистрироваться'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
