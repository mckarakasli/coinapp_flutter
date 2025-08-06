import 'dart:async';
import 'dart:convert';
import 'package:coinappproject/models/trade_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;



class UserDetailPage extends StatefulWidget {
  final int userId;
  final String username;
  final String imageUrl;

  const UserDetailPage({
    Key? key,
    required this.userId,
    required this.username,
    required this.imageUrl,
  }) : super(key: key);

  @override
  _UserDetailPageState createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Trade> openTrades = [];
  List<Trade> closedTrades = [];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTrades(); // İlk yüklemede spinner göstermek için true set ediyoruz
    _timer = Timer.periodic(Duration(seconds: 5), (_) => _fetchTrades());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _fetchTrades() async {
    try {
      final response =
          await http.get(Uri.parse("http://88.222.220.109:8002/trade_list/"));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final allTrades = data.map((e) => Trade.fromJson(e)).toList();

        final userTrades =
            allTrades.where((t) => t.user_id == widget.userId).toList();

        // Sadece veri güncellenirken setState çağrılır.
        setState(() {
          openTrades = userTrades.where((t) => t.status == 1).toList();
          closedTrades = userTrades.where((t) => t.status == 0).toList();
          _isLoading = false; // İlk yüklemeden sonra spinner kapatılır
        });
      } else {
        throw Exception('Sunucudan veri alınamadı.');
      }
    } catch (e) {
      print('Hata: $e');
      // Hata olsa da spinner kapansın, eski veriler gösterilsin.
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTradeCard(Trade trade) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  trade.username.isNotEmpty
                      ? trade.username[0].toUpperCase()
                      : '',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trade.symbol,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Giriş: \$${trade.formattedEntryPrice}",
                            style: TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.w600)),
                        Text(
                          trade.status == 1
                              ? "Anlık: \$${trade.formattedCurrentPrice}"
                              : "Kapanış: \$${trade.formattedCurrentPrice}",
                          style: TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "${trade.rate.toStringAsFixed(2)}%",
                          style: TextStyle(
                              color: trade.rate >= 0
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Stop Loss: \$${trade.formattedStopLoss}",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              )
            ],
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(widget.username),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[900],
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(widget.imageUrl),
                ),
                SizedBox(height: 12),
                Text(
                  widget.username,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.grey[850],
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.amber,
              tabs: [
                Tab(text: 'Açık İşlemler'),
                Tab(text: 'Kapalı İşlemler'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      openTrades.isEmpty
                          ? Center(
                              child: Text(
                              "Açık işlem bulunamadı.",
                              style: TextStyle(color: Colors.white70),
                            ))
                          : ListView.builder(
                              itemCount: openTrades.length,
                              itemBuilder: (context, index) {
                                return _buildTradeCard(openTrades[index]);
                              }),
                      closedTrades.isEmpty
                          ? Center(
                              child: Text(
                              "Kapalı işlem bulunamadı.",
                              style: TextStyle(color: Colors.white70),
                            ))
                          : ListView.builder(
                              itemCount: closedTrades.length,
                              itemBuilder: (context, index) {
                                return _buildTradeCard(closedTrades[index]);
                              }),
                    ],
                  ),
          )
        ],
      ),
    );
  }
}
