import 'dart:convert';
import 'package:coinappproject/models/coincard.dart';
import 'package:http/http.dart' as http;


class CoinService {
  Future<List<Coin>> fetchCoins(List<String> coinSymbols) async {
    try {
      final uriPrice = Uri.parse(
        'https://api.binance.com/api/v3/ticker/price?symbols=${Uri.encodeComponent(jsonEncode(coinSymbols))}',
      );
      final uriChange = Uri.parse(
        'https://api.binance.com/api/v3/ticker/24hr?symbols=${Uri.encodeComponent(jsonEncode(coinSymbols))}',
      );

      final respPrice = await http.get(uriPrice);
      final respChange = await http.get(uriChange);

      if (respPrice.statusCode == 200 && respChange.statusCode == 200) {
        List<dynamic> prices = jsonDecode(respPrice.body);
        List<dynamic> changes = jsonDecode(respChange.body);

        Map<String, String> changeMap = {
          for (var c in changes) c['symbol']: c['priceChangePercent'].toString()
        };

        List<Coin> updatedCoins = prices.map((item) {
          String sym = item['symbol'];
          double price = double.tryParse(item['price']) ?? 0;
          String pct = changeMap[sym] ?? "0.00";

          return Coin(
            symbol: sym,
            name: sym.replaceAll('USDT', ''),
            price: price,
            priceChangePercent: pct,
            iconPath: 'assets/images/${sym.toUpperCase()}.png',
          );
        }).toList();

        return updatedCoins;
      } else {
        throw Exception('Failed to load coin data');
      }
    } catch (e) {
      throw Exception('Error fetching coin data: $e');
    }
  }
}
