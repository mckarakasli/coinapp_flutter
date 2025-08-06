import 'dart:async';
import 'package:coinappproject/models/trade_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    loadInitialTrades();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updatePrices();
    });
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
          // Burada her bir Trade nesnesinin fiyat bilgisini güncelleyin
          for (var newTrade in moreTrades) {
            // Eski trade verileri varsa, onları güncelle
            var existingTradeIndex =
                trades.indexWhere((trade) => trade.id == newTrade.id);
            if (existingTradeIndex != -1) {
              trades[existingTradeIndex] = newTrade;
            } else {
              trades.add(newTrade);
            }
          }
          trades.sort((a, b) => b.created_at.compareTo(a.created_at));
          fetchedCount += moreTrades.length;
        });
      }
    } catch (error) {
      print('Daha fazla veri yüklenirken hata oluştu: $error');
    }
    isLoadingMore = false;
  }

  // Fiyatları 2 saniyede bir güncelleyen fonksiyon
  void _updatePrices() async {
    try {
      final List<Trade> updatedTrades = await fetchTrades(skip: 0, limit: 1000);
      setState(() {
        for (var updatedTrade in updatedTrades) {
          var tradeIndex =
              trades.indexWhere((trade) => trade.id == updatedTrade.id);
          if (tradeIndex != -1) {
            trades[tradeIndex] = updatedTrade; // Fiyat güncellemesi yapılıyor
          }
        }
      });
    } catch (error) {
      print("Fiyat güncellenirken hata oluştu: $error");
    }
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
  void dispose() {
    _timer.cancel();
    super.dispose();
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
