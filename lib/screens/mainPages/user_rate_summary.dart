import 'dart:convert';

import 'package:coinappproject/screens/childPages/user_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';



class RateLeaderboardPage extends StatefulWidget {
  const RateLeaderboardPage({Key? key}) : super(key: key);

  @override
  State<RateLeaderboardPage> createState() => _RateLeaderboardPageState();
}

class _RateLeaderboardPageState extends State<RateLeaderboardPage> {
  List<Map<String, dynamic>> leaderboard = [];
  bool isLoading = true;

  String selectedFilter = 'Tüm Zamanlar';

  List<String> filters = [
    'Tüm Zamanlar',
    'Son 24 Saat',
    'Son 1 Hafta',
    'Son 1 Ay',
  ];

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  bool isDateInSelectedRange(String dateString) {
    final now = DateTime.now();
    final createdAt = DateTime.tryParse(dateString);
    if (createdAt == null) return false;

    switch (selectedFilter) {
      case 'Son 24 Saat':
        return now.difference(createdAt).inHours <= 24;
      case 'Son 1 Hafta':
        return now.difference(createdAt).inDays <= 7;
      case 'Son 1 Ay':
        return now.difference(createdAt).inDays <= 30;
      default:
        return true; // Tüm Zamanlar
    }
  }

  Future<void> _fetchLeaderboard() async {
    final response =
        await http.get(Uri.parse('http://88.222.220.109:8002/trade_list/'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      final filtered = data.where((item) {
        return item['status'] == 0 && isDateInSelectedRange(item['created_at']);
      });

      Map<int, Map<String, dynamic>> userStats = {};

      for (var item in filtered) {
        int userId = item['user_id'];
        String username = item['username'];
        double rate = (item['rate'] as num).toDouble();

        if (!userStats.containsKey(userId)) {
          userStats[userId] = {
            'userId': userId, // UserId’yi de tutuyoruz ki yönlendirelim
            'username': username,
            'imageUrl':
                'https://via.placeholder.com/150', // Varsayılan resim (İstersen API'den al)
            'totalRate': 0.0,
            'totalTrades': 0,
            'positiveTrades': 0,
            'negativeTrades': 0,
          };
        }

        userStats[userId]!['totalRate'] += rate;
        userStats[userId]!['totalTrades'] += 1;
        if (rate > 0) {
          userStats[userId]!['positiveTrades'] += 1;
        } else if (rate < 0) {
          userStats[userId]!['negativeTrades'] += 1;
        }
      }

      final sorted = userStats.values.toList()
        ..sort((a, b) =>
            (b['totalRate'] as double).compareTo(a['totalRate'] as double));

      setState(() {
        leaderboard = sorted;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      debugPrint('API Hatası: ${response.statusCode}');
    }
  }

  Widget _buildRankIcon(int index) {
    if (index == 0) {
      return const Icon(Icons.emoji_events, color: Colors.amber, size: 28);
    } else if (index == 1 || index == 2) {
      return const Icon(Icons.emoji_events, color: Colors.grey, size: 24);
    } else {
      return Text(
        '${index + 1}.',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      );
    }
  }

  Widget _statBox(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Color _rateColor(double rate) {
    if (rate > 0) return Colors.greenAccent;
    if (rate < 0) return Colors.redAccent;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Trader Sıralaması"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButton<String>(
              dropdownColor: Colors.grey[900],
              isExpanded: true,
              value: selectedFilter,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              underline: Container(height: 1, color: Colors.grey),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedFilter = newValue;
                    isLoading = true;
                  });
                  _fetchLeaderboard();
                }
              },
              items: filters.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value,
                      style: GoogleFonts.poppins(color: Colors.white)),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : leaderboard.isEmpty
                    ? const Center(
                        child: Text(
                          "Veri bulunamadı.",
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: leaderboard.length,
                        itemBuilder: (context, index) {
                          final user = leaderboard[index];
                          final totalRate =
                              (user['totalRate'] as double).toStringAsFixed(2);

                          return InkWell(
                            onTap: () {
                              // Kullanıcı detay sayfasına yönlendirme
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserDetailPage(
                                    userId: user['userId'],
                                    username: user['username'],
                                    imageUrl: user['imageUrl'],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade800),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildRankIcon(index),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['username'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            _statBox("Toplam",
                                                "${user['totalTrades']}"),
                                            const SizedBox(width: 10),
                                            _statBox("Pozitif",
                                                "${user['positiveTrades']}"),
                                            const SizedBox(width: 10),
                                            _statBox("Negatif",
                                                "${user['negativeTrades']}"),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "$totalRate%",
                                    style: GoogleFonts.poppins(
                                      color:
                                          _rateColor(double.parse(totalRate)),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
