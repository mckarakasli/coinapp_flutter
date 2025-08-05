import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TradeCommentPage extends StatefulWidget {
  final int tradeId;
  final String symbol;
  final double entryPrice;
  final String direction;

  const TradeCommentPage({
    Key? key,
    required this.tradeId,
    required this.symbol,
    required this.entryPrice,
    required this.direction,
  }) : super(key: key);

  @override
  State<TradeCommentPage> createState() => _TradeCommentPageState();
}

class _TradeCommentPageState extends State<TradeCommentPage> {
  final TextEditingController _commentController = TextEditingController();
  int? userId;
  int remainingChars = 150;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _commentController.addListener(() {
      setState(() {
        remainingChars = 150 - _commentController.text.length;
      });
    });
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');
    });
  }

  Future<void> _submitComment() async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen giriş yapınız.")),
      );
      return;
    }

    final trimmedComment = _commentController.text.trim();

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
          "trade_id": widget.tradeId,
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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("İşlem Yorum Ekle"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Coin: ${widget.symbol}",
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)),
            Text("Fiyat: \$${widget.entryPrice.toStringAsFixed(2)}",
                style: GoogleFonts.poppins(color: Colors.white70)),
            Text("Yön: ${widget.direction}",
                style: GoogleFonts.poppins(color: Colors.white70)),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 150,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              inputFormatters: [
                LengthLimitingTextInputFormatter(150),
              ],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Yorumunuz",
                labelStyle: const TextStyle(color: Colors.amber),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white38),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                ),
                counterText: "$remainingChars karakter kaldı",
                counterStyle: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitComment,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: const Text("Yorumu Gönder"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
