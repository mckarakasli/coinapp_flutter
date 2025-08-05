import 'dart:ui';

import 'package:coinappproject/utils/number_formater.dart';
import 'package:flutter/material.dart';

class Coin {
  final String symbol;
  final String name;
  double price;
  String priceChangePercent;
  final String iconPath;
  Color cardColor;

  Coin({
    required this.symbol,
    required this.name,
    required this.price,
    required this.priceChangePercent,
    required this.iconPath,
    this.cardColor = Colors.grey,
  });

  // Fiyatı .00 formatında döndürür
  String get formattedPrice {
    return NumberFormatter.formatDouble(price);
  }

  // Yüzdelik değişimi %.00 formatında döndürür
  String get formattedPriceChangePercent {
    return NumberFormatter.formatPercent(priceChangePercent);
  }

  // Fiyat güncellemesi ve kart rengini geçici değiştirme
  void update(double newPrice, String newPct) {
    String formattedNewPrice = NumberFormatter.formatDouble(newPrice);

    cardColor = newPrice > price
        ? Colors.green.shade700
        : (newPrice < price ? Colors.red.shade700 : Colors.grey);

    price = newPrice;
    priceChangePercent = newPct;

    // 800ms sonra rengi tekrar gri yap
    Future.delayed(const Duration(milliseconds: 800), () {
      cardColor = Colors.grey;
    });
  }
}
