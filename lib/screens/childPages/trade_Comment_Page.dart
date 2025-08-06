import 'package:coinappproject/services/trade_save_services.dart';
import 'package:coinappproject/utils/number_formater.dart';
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
            Text("Fiyat: \$${NumberFormatter.formatDouble(widget.entryPrice)}",
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
                onPressed: () {
                  submitComment(
                    context: context,
                    userId: userId,
                    commentController: _commentController,
                    tradeId: widget.tradeId,
                  );
                },
                child: Text('Yorum Gönder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
