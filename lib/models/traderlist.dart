import 'package:coinappproject/utils/number_formater.dart';

class Trade {
  final int? id;
  final int user_id;
  final String symbol;
  final String direction;
  final double rate;
  final int status;
  final String username;
  final double entry_price;
  final double target_price;
  final double stop_loss; // stop_loss tipi double olarak kaldı
  final DateTime created_at;
  final double current_price;
  final DateTime? closedTime; // nullable oldu
  final String comment;
 
 

  Trade({
    required this.id,
    required this.symbol,
    required this.direction,
    required this.rate,
    required this.username,
    required this.created_at,
    required this.entry_price,
    required this.target_price,
    required this.stop_loss,
    required this.status,
    required this.current_price,
    required this.user_id,
    required this.comment,
    
    this.closedTime,
    
  });

  
  // Her bir double değeri için formatlanmış getter'lar ekleyelim
  String get formattedStopLoss => NumberFormatter.formatDouble(stop_loss);
  String get formattedCurrentPrice => NumberFormatter.formatDouble(current_price);
  String get formattedRate => NumberFormatter.formatDouble(rate);
  String get formattedEntryPrice => NumberFormatter.formatDouble(entry_price);
  String get formattedTargetPrice => NumberFormatter.formatDouble(target_price);
  


factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'] is int
          ? json['id']
          : null, // Eğer id null değilse alıyoruz
      user_id: json['user_id'], // user_id anahtarını doğru yazıyoruz
      symbol: json['symbol']?.toString() ?? 'Bilinmiyor',
      direction: json['direction']?.toString() ?? 'N/A',
      username: json['username']?.toString() ?? 'N/A',
      created_at: DateTime.parse(json['created_at']),
      closedTime: json['closed_time'] != null && json['closed_time'] != ""
            ? DateTime.parse(json['closed_time'])
            : null,
      rate: double.tryParse(json['rate']?.toString() ?? '0') ?? 0.0,
      entry_price: json['entry_price']?.toDouble() ?? 0.0,
      target_price: json['target_price']?.toDouble() ?? 0.0,
      stop_loss: json['stop_loss']?.toDouble() ?? 0.0,
      current_price: json['binance_price']?.toDouble() ?? 0.0,
      comment: (json['comment'] is String)
            ? json['comment']
            : (json['comment'] is Map && json['comment']?['comment'] != null)
                ? json['comment']['comment']
                : '',

      status :json['status']
    );
  }


  toJson() {}
}
