import 'dart:async';
import 'package:coinappproject/models/coincard.dart';
import 'package:coinappproject/models/trade_model.dart';
import 'package:coinappproject/widgets/home_all_trade_list_page.dart';
import 'package:coinappproject/screens/authPages/login_page.dart';
import 'package:coinappproject/screens/mainPages/signals.page.dart';

import 'package:coinappproject/screens/mainPages/profile_page.dart';
import 'package:coinappproject/screens/mainPages/user_rate_summary.dart';

import 'package:coinappproject/services/binance_services.dart';

import 'package:coinappproject/widgets/bottom_navigator.dart';
import 'package:coinappproject/widgets/home_coin_card.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<Coin> displayedCoins = [];
  
  bool isLoading = true;
  bool isTradesLoading = true;
  int _currentIndex = 0;
  String? username;
  String? email;
  int? userid;
  late Timer _timer;
  late TabController _tabController;

  final CoinService _coinService = CoinService();


  final List<Widget> _pages = [
    const HomePage(),
    const RateLeaderboardPage(),
    UserProfilePage(),
    SignalPage(),
  ];

  final List<String> coinSymbols = [
    "BTCUSDT",
    "ETHUSDT",
    "BNBUSDT",
    "XRPUSDT",
    "ADAUSDT",
    "DOGEUSDT",
    
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCoins();

    _tabController = TabController(length: 3, vsync: this);

    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadCoins();
    });
  }

  Future<void> _loadCoins() async {
    try {
      List<Coin> updatedCoins = await _coinService.fetchCoins(coinSymbols);
      setState(() {
        displayedCoins = updatedCoins;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('Error loading coins: $e');
    }
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userid = prefs.getInt('user_id');
      username = prefs.getString('username');
      email = prefs.getString('email');
    });
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
    Navigator.push(context, MaterialPageRoute(builder: (_) => _pages[index]));
  }

  @override
  void dispose() {
    _timer.cancel();
    _tabController.dispose();
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  final double screenHeight = MediaQuery.of(context).size.height;
  final double appBarHeight = kToolbarHeight;
  final double statusBarHeight = MediaQuery.of(context).padding.top;
  final double cardsHeight = screenHeight * 0.3;
  final double tabBarHeight = 48;

  return Scaffold(
    extendBodyBehindAppBar: true,
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: username != null
          ? Text(
              'Hoş geldin, $username',
              style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            )
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.person, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    username == null ? const LoginPage() : UserProfilePage(),
              ),
            );
          },
        ),
      ],
    ),
    body: SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
                children: [
                  /// COIN KARTLARI → %30 ekran yüksekliği
                  SizedBox(
                    height: cardsHeight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: displayedCoins.length,
                        itemBuilder: (context, idx) {
                          return CoinCard(coin: displayedCoins[idx]);
                        },
                      ),
                    ),
                  ),

                  /// TABBAR → sabit yükseklik
                  SizedBox(
                    height: tabBarHeight,
                    child: Container(
                      color: Colors.grey[900],
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.amber,
                        tabs: const [
                          Tab(text: "Akış"),
                          Tab(text: "En çok yükselenler"),
                          Tab(text: "En çok düşenler"),
                        ],
                      ),
                    ),
                  ),

                  /// TABBARVIEW → kalan tüm alan
                  Expanded(
                    child: Container(
                      color: Colors.black,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          const TradeListWidget(),
                          const Center(
                            child: Text(
                              "Satış işlemleri yakında burada listelenecek.",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          isTradesLoading
                              ? const Center(
                                  child: CircularProgressIndicator(color: Colors.white),
                                )
                              : const Center(
                                  child: Text(
                                    "Veri yüklendi",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ),
    bottomNavigationBar: BottomNavBar(
      currentIndex: _currentIndex,
      onTap: _onItemTapped,
    ),
  );
}
}
