import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:coinappproject/screens/mainPages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; 



class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _rotateAnimation =
        Tween<double>(begin: 0.0, end: 6.28).animate(_controller);

    // Kullanıcı durumunu kontrol et
    _checkUserStatus();
  }

  // Kullanıcı durumunu SharedPreferences ile kontrol etme
  void _checkUserStatus() async {
    // SharedPreferences'ten kullanıcı durumu (isLoggedIn) bilgisini al
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // 4 saniye bekle ve kullanıcıya göre yönlendirme yap
    await Future.delayed(const Duration(seconds: 4));

    if (isLoggedIn) {
      // Eğer kullanıcı oturum açmışsa, anasayfaya yönlendir
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      // Eğer kullanıcı oturum açmamışsa, giriş sayfasına yönlendir
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildMatrixText() {
    return SizedBox(
      height: 40,
      child: AnimatedTextKit(
        animatedTexts: [
          TyperAnimatedText('Kripto Verileri Yükleniyor...',
              textStyle: GoogleFonts.sourceCodePro(
                fontSize: 18,
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              )),
          TyperAnimatedText('Blok Zincir Sorgulanıyor...',
              textStyle: GoogleFonts.sourceCodePro(
                fontSize: 18,
                color: Colors.lightGreenAccent,
                fontWeight: FontWeight.bold,
              )),
          TyperAnimatedText('Dijital Cüzdanlar Bağlanıyor...',
              textStyle: GoogleFonts.sourceCodePro(
                fontSize: 18,
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              )),
        ],
        repeatForever: true,
        pause: const Duration(milliseconds: 1000),
      ),
    );
  }

  Widget buildRotatingCoin() {
    return AnimatedBuilder(
      animation: _rotateAnimation,
      builder: (_, __) {
        return Transform.rotate(
          angle: _rotateAnimation.value,
          child: Container(
            height: 80,
            width: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amberAccent,
                  blurRadius: 18,
                  spreadRadius: 3,
                )
              ],
            ),
            child: const Icon(Icons.currency_bitcoin,
                color: Colors.black, size: 45),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        color: Colors.black, // Artık düz siyah
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildRotatingCoin(),
              const SizedBox(height: 30),
              buildMatrixText(),
              const SizedBox(height: 40),
              SizedBox(
                width: 220,
                child: LinearProgressIndicator(
                  minHeight: 8,
                  color: Colors.greenAccent,
                  backgroundColor: Colors.green.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
