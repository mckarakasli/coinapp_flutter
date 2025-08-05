import 'dart:convert';
import 'dart:async';
import 'package:coinappproject/screens/authPages/login_page.dart';
import 'package:coinappproject/screens/authPages/register_page.dart';

import 'package:coinappproject/screens/mainPages/home_page.dart';
import 'package:coinappproject/screens/all_trade_list_page.dart';
import 'package:coinappproject/screens/childPages/loading_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;

// --------------------- MAIN ---------------------
void main() {
  runApp(
    ScreenUtilInit(
      designSize: Size(375, 812), // iPhone 11 baz alınabilir
      builder: (context, child) => const MyApp(),
    ),
  );
}

// --------------------- MYAPP ---------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home : HomePage()
    );
  }
}


