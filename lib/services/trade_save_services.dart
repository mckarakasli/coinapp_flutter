import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<void> submitComment({
  required BuildContext context,
  required int? userId,
  required TextEditingController commentController,
  required int? tradeId,
}) async {
  if (userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Lütfen giriş yapınız.")),
    );
    return;
  }

  final trimmedComment = commentController.text.trim();

  if (trimmedComment.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Yorum boş olamaz.")),
    );
    return;
  }

  if (trimmedComment.length > 150) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Yorum 150 karakterden uzun olamaz.")),
    );
    return;
  }

  try {
    final response = await http.post(
      Uri.parse("http://88.222.220.109:8001/add_comment"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId!,
        "trade_id": tradeId,
        "comment": trimmedComment,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yorum başarıyla kaydedildi.")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Yorum gönderilemedi: ${response.body}")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Bir hata oluştu: $e")),
    );
  }
}

