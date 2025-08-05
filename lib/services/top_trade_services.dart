import 'dart:convert';
import 'package:coinappproject/models/traderlist.dart';
import 'package:http/http.dart' as http;


class TradeService {
  Future<List<Trade>> fetchTopTrades() async {
    try {
      final response =
          await http.get(Uri.parse('http://88.222.220.109:8002/top_trades/'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<Trade> allTrades =
            data.map((item) => Trade.fromJson(item)).toList();
        allTrades.sort((a, b) =>
            b.rate.compareTo(a.rate)); // 'rate' field'ına göre sıralama

        return allTrades.take(10).toList(); // İlk 10 veriyi al
      } else {
        throw Exception('Failed to load top trades');
      }
    } catch (e) {
      throw Exception('Error fetching top trades: $e');
    }
  }
}
