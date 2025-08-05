
import 'package:coinappproject/screens/mainPages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String responseMessage = '';

  Future<void> login() async {
    final response = await http.post(
      Uri.parse('http://88.222.220.109:8000/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': emailController.text,
        'password': passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', data['user_id']);
        await prefs.setString('username', data['username']);
        await prefs.setString('email', data['email']);
        await prefs.setBool('isLogin', true);

        setState(() {
          responseMessage =
              "ID: ${data['id']}, Username: ${data['username']}, Email: ${data['email']}";
        });

        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("SharedPreferences Hatası: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Giriş başarısız: ${response.body}")),
      );
    }
  }

  void goToRegisterPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  void guestContinue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  Widget customTextField(TextEditingController controller, String label,
      {bool obscure = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white24)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.amber)),
      ),
    );
  }

  Widget modernButton(String text, VoidCallback onTap,
      {Color color = Colors.amber, Color textColor = Colors.black}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(text,
            style:
                TextStyle(color: textColor, fontSize: 16, letterSpacing: 0.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.amber),
              const SizedBox(height: 16),
              const Text("Giriş Yap",
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 6),
              const Text("Lütfen hesabınıza giriş yapın",
                  style: TextStyle(fontSize: 14, color: Colors.white60)),
              const SizedBox(height: 32),
              customTextField(emailController, "E-posta",
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 18),
              customTextField(passwordController, "Şifre", obscure: true),
              const SizedBox(height: 24),
              modernButton("Giriş Yap", login),
              const SizedBox(height: 12),
              modernButton("Google ile Giriş", () {},
                  color: Colors.redAccent, textColor: Colors.white),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Hesabın yok mu?",
                      style: TextStyle(color: Colors.white60)),
                  TextButton(
                    onPressed: goToRegisterPage,
                    child: const Text("Kayıt Ol",
                        style: TextStyle(
                            color: Colors.amber, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              TextButton(
                onPressed: guestContinue,
                child: const Text("Misafir olarak devam et",
                    style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 20),
              if (responseMessage.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.green[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Gelen Veri: $responseMessage',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
