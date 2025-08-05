class NumberFormatter {
  // Genel bir formatlama fonksiyonu
  static String formatDouble(double value) {
    String valueStr = value.toStringAsFixed(4); // Başlangıçta 4 haneli gösterim

    // Noktadan önceki kısmı alıyoruz
    List<String> parts = valueStr.split('.');
    String integerPart = parts[0];

    // Eğer tam sayının uzunluğu 1 ile 10 hane arasında ise, sadece 2 ondalık göster
    if (integerPart.length >= 1 && integerPart.length <= 10) {
      valueStr = value.toStringAsFixed(2);
    }

    // Eğer tam sayının uzunluğu 1 hane ise, 4 ondalık göster
    if (integerPart.length == 1) {
      valueStr = value.toStringAsFixed(4);
    }

    return valueStr;
  }

  // Yüzdelik değer formatlayıcı (% işaretiyle ve sabit 2 hane)
  static String formatPercent(String value) {
    // "%" varsa temizle
    value = value.replaceAll('%', '');

    double parsed = double.tryParse(value) ?? 0.0;
    return "${parsed.toStringAsFixed(2)}%";
  }
}
