import 'package:coinappproject/utils/number_formater.dart';

class Comment {
  final int id;
  final int user_id;
  final int trade_id;
  final String comment;
  final DateTime created_at;

  Comment({
    required this.id,
    required this.user_id,
    required this.trade_id,
    required this.comment,
    required this.created_at,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      user_id: json['user_id'],
      trade_id: json['trade_id'],
      comment: json['comment'] ?? '',
      created_at: DateTime.parse(json['created_at']),
    );
  }
}


class Trade {
  final int id;
  final String symbol;
  final int user_id;
  final double entry_price;
  final double target_price;
  final double stop_loss;
  final int status;
  final String direction;
  final double closed_price;
  final double rate;
  final DateTime? closed_time;
  final DateTime created_at;
  final String username;
  final double binance_price;
  final int trade_id;
  final int userstop;
  final Comment? comment;

  Trade({
    required this.id,
    required this.symbol,
    required this.user_id,
    required this.entry_price,
    required this.target_price,
    required this.stop_loss,
    required this.status,
    required this.direction,
    required this.closed_price,
    required this.rate,
    this.closed_time,
    required this.created_at,
    required this.username,
    required this.binance_price,
    required this.trade_id,
    required this.userstop,
    this.comment,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'],
      symbol: json['symbol'],
      user_id: json['user_id'],
      entry_price: (json['entry_price'] as num).toDouble(),
      target_price: (json['target_price'] as num).toDouble(),
      stop_loss: (json['stop_loss'] as num).toDouble(),
      status: json['status'],
      direction: json['direction'],
      closed_price: (json['closed_price'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
      closed_time: json['closed_time'] != null
          ? DateTime.parse(json['closed_time'])
          : null,
      created_at: DateTime.parse(json['created_at']),
      username: json['username'],
      binance_price: (json['binance_price'] as num).toDouble(),
      trade_id: json['trade_id'],
      userstop: json['userstop'],
      comment:
          json['comment'] != null ? Comment.fromJson(json['comment']) : null,
    );
  }

  String get formattedEntryPrice => NumberFormatter.formatDouble(entry_price);
  String get formattedCurrentPrice =>
      (status == 1 ? NumberFormatter.formatDouble(binance_price) : NumberFormatter.formatDouble(closed_price));
  String get formattedStopLoss => NumberFormatter.formatDouble(stop_loss);
}
