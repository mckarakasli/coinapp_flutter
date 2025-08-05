import 'dart:convert';
import 'package:coinappproject/models/traderlist.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;


class UserTradeService {
  Future<List<Trade>> fetchUserTrades() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) {
      throw Exception('User ID bulunamadı');
    }

    final response =
        await http.get(Uri.parse('http://88.222.220.109:8002/top_trades/'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      List<Trade> allTrades = data.map((e) => Trade.fromJson(e)).toList();

      List<Trade> userTrades =
          allTrades.where((trade) => trade.user_id == userId).toList();

      userTrades.sort((a, b) => b.rate.compareTo(a.rate));

      return userTrades.take(10).toList();
    } else {
      throw Exception('API hatası: ${response.statusCode}');
    }
  }
}
