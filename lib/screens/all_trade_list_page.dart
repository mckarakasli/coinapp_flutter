import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// MODELLER

class Comment {
  final int id;
  final int user_id;
  final int trade_id;
  final String comment;
  final DateTime created_at;

  Comment({
    required this.id,
    required this.user_id,
    required this.trade_id,
    required this.comment,
    required this.created_at,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      user_id: json['user_id'],
      trade_id: json['trade_id'],
      comment: json['comment'] ?? '',
      created_at: DateTime.parse(json['created_at']),
    );
  }
}

class Trade {
  final int id;
  final String symbol;
  final int user_id;
  final double entry_price;
  final double target_price;
  final double stop_loss;
  final int status;
  final String direction;
  final double closed_price;
  final double rate;
  final DateTime? closed_time;
  final DateTime created_at;
  final String username;
  final double binance_price;
  final int trade_id;
  final int userstop;
  final Comment? comment;

  Trade({
    required this.id,
    required this.symbol,
    required this.user_id,
    required this.entry_price,
    required this.target_price,
    required this.stop_loss,
    required this.status,
    required this.direction,
    required this.closed_price,
    required this.rate,
    this.closed_time,
    required this.created_at,
    required this.username,
    required this.binance_price,
    required this.trade_id,
    required this.userstop,
    this.comment,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'],
      symbol: json['symbol'],
      user_id: json['user_id'],
      entry_price: (json['entry_price'] as num).toDouble(),
      target_price: (json['target_price'] as num).toDouble(),
      stop_loss: (json['stop_loss'] as num).toDouble(),
      status: json['status'],
      direction: json['direction'],
      closed_price: (json['closed_price'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
      closed_time: json['closed_time'] != null
          ? DateTime.parse(json['closed_time'])
          : null,
      created_at: DateTime.parse(json['created_at']),
      username: json['username'],
      binance_price: (json['binance_price'] as num).toDouble(),
      trade_id: json['trade_id'],
      userstop: json['userstop'],
      comment:
          json['comment'] != null ? Comment.fromJson(json['comment']) : null,
    );
  }

  String get formattedEntryPrice => entry_price.toStringAsFixed(4);
  String get formattedCurrentPrice =>
      (status == 1 ? binance_price : closed_price).toStringAsFixed(4);
  String get formattedStopLoss => stop_loss.toStringAsFixed(4);
}

// WIDGET

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.black,
      
      body: TradeListWidget(),
    ),
  ));
}

class TradeListWidget extends StatefulWidget {
  const TradeListWidget({super.key});

  @override
  State<TradeListWidget> createState() => _TradeListWidgetState();
}

class _TradeListWidgetState extends State<TradeListWidget> {
  List<Trade> trades = [];
  bool isLoadingMore = false;
  int fetchedCount = 0;
  final int pageSize = 5;

  @override
  void initState() {
    super.initState();
    loadInitialTrades();
  }

  Future<List<Trade>> fetchTrades({int skip = 0, int limit = 5}) async {
    final url = Uri.parse(
        "http://88.222.220.109:8002/trade_list/?skip=$skip&limit=$limit");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      data.sort((a, b) {
        DateTime dateA = DateTime.parse(a['created_at']);
        DateTime dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA);
      });
      return data.map((item) => Trade.fromJson(item)).toList();
    } else {
      throw Exception("Veriler alınamadı.");
    }
  }

  void loadInitialTrades() async {
    try {
      final List<Trade> initialTrades =
          await fetchTrades(skip: 0, limit: pageSize);
      setState(() {
        trades = initialTrades;
        fetchedCount = initialTrades.length;
      });
      loadMoreTrades();
    } catch (error) {
      print('İlk veri alınırken hata oluştu: $error');
    }
  }

  void loadMoreTrades() async {
    if (isLoadingMore) return;
    isLoadingMore = true;
    try {
      final List<Trade> moreTrades =
          await fetchTrades(skip: fetchedCount, limit: 1000);
      if (moreTrades.isNotEmpty) {
        setState(() {
          trades.addAll(moreTrades);
          trades.sort((a, b) => b.created_at.compareTo(a.created_at));
          fetchedCount += moreTrades.length;
        });
      }
    } catch (error) {
      print('Daha fazla veri yüklenirken hata oluştu: $error');
    }
    isLoadingMore = false;
  }

  String _calculateTimeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} saniye önce paylaşıldı';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce paylaşıldı';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce paylaşıldı';
    } else {
      return '${difference.inDays} gün önce paylaşıldı';
    }
  }

  Widget _infoText(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: trades.length,
      itemBuilder: (context, index) {
        final trade = trades[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: const Color(0xFF1E1E1E),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ÜST BİLGİLER (avatar, kullanıcı adı, sembol)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.blueAccent,
                      child: Text(
                        trade.username.isNotEmpty
                            ? trade.username[0].toUpperCase()
                            : '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sembol ve kullanıcı adı
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                trade.symbol,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                trade.username,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Fiyatlar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _infoText("Giriş: \$${trade.formattedEntryPrice}",
                                  Colors.blueGrey),

                           
                              _infoText(
                                "${trade.rate}%",
                                trade.rate >= 0
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _infoText("Hedef: \$${trade.target_price}",
                              Colors.greenAccent),
                                 _infoText(
                            trade.status == 1
                                ? "Anlık: \$${trade.formattedCurrentPrice}"
                                : "Kapanış: \$${trade.formattedCurrentPrice}",
                            Colors.orangeAccent,
                          ),
                          // Stop loss etiketi
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _infoText(
                                  "Stop Loss: \$${trade.formattedStopLoss}",
                                  Colors.grey),
                              _infoText(
                                trade.status == 0 ? "İşlem kapandı" : "",
                                Colors.red,
                              ),
                              _infoText(
                                trade.status == 1 ? "Hala işlemde" : "",
                                Colors.greenAccent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Yorum varsa göster
                if (trade.comment?.comment.isNotEmpty == true) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.comment,
                              color: Colors.blueAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trade.username,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  trade.comment!.comment,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Paylaşım zamanı
                Text(
                  _calculateTimeAgo(trade.created_at),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
