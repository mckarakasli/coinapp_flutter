import 'dart:async';
import 'dart:convert';
import 'package:coinappproject/models/trade_model.dart';
import 'package:coinappproject/screens/authPages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  String username = '';
  String email = '';
  String imageUrl = "https://cdn-icons-png.flaticon.com/512/219/219983.png";

  late TabController _tabController;

  List<Trade> openTrades = [];
  List<Trade> closedTrades = [];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkLoginStatus();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _loadTrades();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      });
    } else {
      await _loadUserProfile();
      await _loadTrades();
      setState(() {
        _isLoggedIn = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'Kullanıcı Adı';
      email = prefs.getString('email') ?? 'E-posta';
      imageUrl = prefs.getString('imageUrl') ??
          'https://cdn-icons-png.flaticon.com/512/219/219983.png';
    });
  }

  Future<void> _loadTrades() async {
    try {
      final allTrades = await fetchTrades();
      setState(() {
        openTrades =
            allTrades.where((t) => t.status == 1).toList(); // Açık işlemler
        closedTrades =
            allTrades.where((t) => t.status == 0).toList(); // Kapalı işlemler
      });
    } catch (e) {
      print('Hata oluştu: $e');
    }
  }

  Future<List<Trade>> fetchTrades() async {
    final prefs = await SharedPreferences.getInstance();
    final int? storedUserId = prefs.getInt('user_id');

    final response =
        await http.get(Uri.parse("http://88.222.220.109:8002/trade_list/"));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      final allTrades = data.map((item) => Trade.fromJson(item)).toList();

      final filteredTrades = allTrades.where((trade) {
        return trade.user_id == storedUserId;
      }).toList();

      return filteredTrades;
    } else {
      throw Exception("Veriler alınamadı.");
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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  Future<void> _closeTrade(Trade trade) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "İşlemi Kapat",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          "Bu işlemi kapatmak istediğinize emin misiniz?",
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "İptal",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              "Onayla",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Anlık fiyatı closed_price olarak alıyoruz
      final double closedPrice =
          double.tryParse(trade.formattedCurrentPrice.toString()) ?? 0.0;


      final response = await http.post(
        Uri.parse("http://88.222.220.109:8002/close_trade/"),
        body: jsonEncode({
          "trade_id": trade.id,
          "closed_price": closedPrice,
        }),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        await _loadTrades();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem başarıyla kapatıldı.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem kapatılamadı!')),
        );
      }

      // Demo amaçlı log
      print(
          "İşlem kapatma isteği gönderildi: Trade ID = ${trade.id}, Closed Price = $closedPrice");
    }
  }

  Widget _buildTradeCard(Trade trade) {
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoText("Giriş: \$${trade.formattedEntryPrice}",
                              Colors.greenAccent),
                          _infoText(
                            trade.status == 1
                                ? "Anlık: \$${trade.formattedCurrentPrice}"
                                : "Kapanış: \$${trade.formattedCurrentPrice}",
                            Colors.orangeAccent,
                          ),
                          _infoText(
                            "${trade.rate}%",
                            trade.rate >= 0
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoText("Stop Loss: \$${trade.formattedStopLoss}",
                              Colors.grey),

                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (trade.status == 1)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _closeTrade(trade),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    "İşlemi Kapat",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text("Profil"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(imageUrl),
                ),
                const SizedBox(height: 10),
                Text(
                  username,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.grey[850],
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.amber,
              tabs: const [
                Tab(text: "Açık İşlemler"),
                Tab(text: "Kapalı İşlemler"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                openTrades.isEmpty
                    ? const Center(
                        child: Text(
                          "Açık işlem bulunamadı.",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: openTrades.length,
                        itemBuilder: (context, index) {
                          final trade = openTrades[index];
                          return _buildTradeCard(trade);
                        },
                      ),
                closedTrades.isEmpty
                    ? const Center(
                        child: Text(
                          "Kapalı işlem bulunamadı.",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: closedTrades.length,
                        itemBuilder: (context, index) {
                          final trade = closedTrades[index];
                          return _buildTradeCard(trade);
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
