import 'package:coinappproject/models/traderlist.dart';
import 'package:coinappproject/services/top_trade_services.dart';
import 'package:coinappproject/services/user_trade_list_services.dart';
import 'package:coinappproject/widgets/user_trade_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserTradeListPage extends StatefulWidget {
  @override
  _UserTradeListPageState createState() => _UserTradeListPageState();
}

class _UserTradeListPageState extends State<UserTradeListPage> {
  int _selectedIndex = 0;

  // Tab index değiştiğinde sayfa değiştirme
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Trades',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Sekmeler
          DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  labelColor: Colors.blueAccent,
                  indicatorColor: Colors.blueAccent,
                  unselectedLabelColor: Colors.black54,
                  tabs: [
                    Tab(text: 'Açık İşlemler'),
                    Tab(text: 'Kapalı İşlemler'),
                    Tab(text: 'Profil'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Açık işlemler
                      FutureBuilder<List<Trade>>(
                        future: UserTradeService().fetchUserTrades(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Hata: ${snapshot.error}',
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 16)));
                          }
                          if (snapshot.hasData) {
                            final trades = snapshot.data!;
                            return TradeCardList(
                              trades: trades,
                              isOpen: true,
                              onClose: (trade) {
                                print("Kapatılan işlem: ${trade.symbol}");
                              },
                            );
                          }
                          return Center(child: Text('Veri bulunamadı.'));
                        },
                      ),
                      // Kapalı işlemler
                      FutureBuilder<List<Trade>>(
                        future: UserTradeService().fetchUserTrades(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Hata: ${snapshot.error}',
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 16)));
                          }
                          if (snapshot.hasData) {
                            final trades = snapshot.data!;
                            return TradeCardList(
                              trades: trades,
                              isOpen: false,
                              onClose: (trade) {
                                print("Kapatılan işlem: ${trade.symbol}");
                              },
                            );
                          }
                          return Center(child: Text('Veri bulunamadı.'));
                        },
                      ),
                      // Profil sekmesi
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(
                                  'https://www.example.com/user-profile.jpg'), // Kullanıcı resmi
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Kullanıcı Adı',
                              style: GoogleFonts.poppins(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'kullanici@example.com',
                              style: GoogleFonts.poppins(
                                  fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                // Profil düzenleme işlemleri
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                              child: Text('Profili Düzenle',
                                  style:
                                      GoogleFonts.poppins(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Profil'),
        ],
      ),
    );
  }
}
