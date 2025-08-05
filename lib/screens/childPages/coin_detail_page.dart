import 'package:coinappproject/screens/authPages/login_page.dart';
import 'package:coinappproject/screens/childPages/trade_Comment_Page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CoinDetailPage extends StatefulWidget {
  final String name;
  final double price;

  const CoinDetailPage({super.key, required this.name, required this.price});

  @override
  State<CoinDetailPage> createState() => _CoinDetailPageState();
}

class _CoinDetailPageState extends State<CoinDetailPage> {
  late TextEditingController _targetController;
  late TextEditingController _stopLossController;
  double? gainPercent;
  double? lossPercent;
  String? username;
  String? email;
  int? userid;

  Map<String, dynamic>? signalsData;
  bool isLoadingSignals = true;

  String selectedInterval = "1h";

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _targetController = TextEditingController(
      text: widget.price.toStringAsFixed(2),
    );

    double stopLossDefault = widget.price * 0.97;
    _stopLossController = TextEditingController(
      text: stopLossDefault.toStringAsFixed(2),
    );

    fetchSignals();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userid = prefs.getInt('user_id');
      username = prefs.getString('username');
      email = prefs.getString('email');
    });
  }

  Future<void> fetchSignals() async {
    final url = Uri.parse("http://88.222.220.109:8004/signals");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);

        final Map<String, dynamic>? coinData = data["results"] != null
            ? Map<String, dynamic>.from(data["results"])
            : null;

        final coinKey = "${widget.name.toUpperCase()}USDT";

        setState(() {
          signalsData = coinData != null
              ? coinData[coinKey] as Map<String, dynamic>?
              : null;
          isLoadingSignals = false;
        });
      } else {
        setState(() {
          isLoadingSignals = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingSignals = false;
      });
    }
  }

  void calculateGain() {
    final double? target = double.tryParse(_targetController.text);
    final double? stopLoss = double.tryParse(_stopLossController.text);

    if (stopLoss == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Geçerli bir stoploss değeri girin.")),
      );
      return;
    }

    if (target != null && widget.price > 0) {
      setState(() {
        gainPercent = ((target - widget.price) / widget.price) * 100;
      });
    }

    if (stopLoss != null && widget.price > 0) {
      setState(() {
        lossPercent = ((widget.price - stopLoss) / widget.price) * 100;
      });
    }
  }

  Future<void> sendDataToAPI(String direction) async {
    try {
      final url = Uri.parse('http://88.222.220.109:8001/create_trade');

      final double entryPrice = widget.price;
      final double targetPrice = double.tryParse(_targetController.text) ?? 0.0;
      final double? stoploss = double.tryParse(
        _stopLossController.text.replaceAll(',', '.'),
      );

      if (stoploss == null || stoploss <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçerli bir stoploss değeri girin')),
        );
        return;
      }

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": userid,
          "symbol": widget.name,
          "entry_price": entryPrice,
          "target_price": targetPrice,
          "stop_loss": stoploss,
          "status": 1,
          "rate": 0,
          "direction": direction, // "up" veya "down" burada
          "closed_price": 0,
          "result": 0,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final tradeId = responseData['id'];

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem başarıyla açıldı!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TradeCommentPage(
              tradeId: tradeId,
              symbol: widget.name,
              entryPrice: entryPrice,
              direction: direction,
            ),
          ),
        );
      } else if (response.statusCode == 422) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri hatalı: ${response.body}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Veri gönderilemedi. Hata kodu: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: $e')),
      );
    }
  }

  Widget buildIntervalSelector() {
    final intervals = ["15m", "1h", "4h", "1d"];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: intervals.map((interval) {
          final isSelected = selectedInterval == interval;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ChoiceChip(
              label: Text(interval),
              selected: isSelected,
              selectedColor: Colors.amber,
              backgroundColor: Colors.grey.shade700,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (_) {
                setState(() {
                  selectedInterval = interval;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildSignals() {
    if (isLoadingSignals) {
      return const Center(child: CircularProgressIndicator());
    }

    if (signalsData == null || signalsData!.isEmpty) {
      return const Center(
        child: Text(
          "Sinyaller bulunamadı.",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final intervalData =
        signalsData![selectedInterval] as Map<String, dynamic>?;

    if (intervalData == null || intervalData.isEmpty) {
      return Center(
        child: Text(
          "Seçilen zaman dilimi için sinyal bulunamadı.",
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    final emaData = intervalData["ema"] as Map<String, dynamic>?;

    final String macdSignal = intervalData["macd"] ?? "Bilinmiyor";

    final Map<String, dynamic>? rsiData = intervalData["rsi"] != null
        ? Map<String, dynamic>.from(intervalData["rsi"])
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (emaData != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: emaData.entries.map((entry) {
              final emaName = entry.key;
              final emaInfo = entry.value as Map<String, dynamic>;
              final signal = emaInfo["signal"] ?? "Bilinmiyor";
              final price = emaInfo["price"] ?? 0.0;
              final signalColor = signal == "AL" ? Colors.green : Colors.red;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        emaName,
                        style: GoogleFonts.montserrat(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        signal,
                        style: GoogleFonts.montserrat(
                          color: signalColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "\$${price.toStringAsFixed(2)}",
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                "MACD",
                style: GoogleFonts.montserrat(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                macdSignal,
                style: GoogleFonts.montserrat(
                  color: macdSignal == "AL"
                      ? Colors.green
                      : macdSignal == "SAT"
                          ? Colors.red
                          : Colors.yellow,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (rsiData != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.7),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  "RSI",
                  style: GoogleFonts.montserrat(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Değer: ${rsiData["value"]?.toStringAsFixed(2) ?? "-"}",
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${rsiData["signal"] ?? "-"}",
                  style: GoogleFonts.montserrat(
                    color: rsiData["signal"] == "AL"
                        ? Colors.green
                        : rsiData["signal"] == "SAT"
                            ? Colors.red
                            : Colors.yellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Text(
              widget.name,
              style: GoogleFonts.montserrat(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "\$${widget.price.toStringAsFixed(2)}",
              style: GoogleFonts.montserrat(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _targetController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Hedef Fiyat",
                labelStyle: const TextStyle(color: Colors.amber),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.amber),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.amber),
                ),
                fillColor: Colors.grey.shade900,
                filled: true,
              ),
              onChanged: (_) => calculateGain(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _stopLossController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Stop Loss",
                labelStyle: const TextStyle(color: Colors.amber),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.amber),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.amber),
                ),
                fillColor: Colors.grey.shade900,
                filled: true,
              ),
              onChanged: (_) => calculateGain(),
            ),
            const SizedBox(height: 20),
            if (gainPercent != null)
              Text(
                "Kazanç: %${gainPercent!.toStringAsFixed(2)}",
                style: GoogleFonts.montserrat(
                  color: gainPercent! >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            if (lossPercent != null)
              Text(
                "Zarar: %${lossPercent!.toStringAsFixed(2)}",
                style: GoogleFonts.montserrat(
                  color: lossPercent! >= 0 ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            const SizedBox(height: 30),
            userid != null
                ? Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => sendDataToAPI("up"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            "AL",
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => sendDataToAPI("down"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            "SAT",
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Text(
                        "İşlem açmak için lütfen üye girişi yapınız.",
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
   TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()),
                          );
                        },
                        child: Text(
                          "Giriş Yap",
                          style: GoogleFonts.montserrat(
                            color: Colors.amber,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    
                  ),
                  const SizedBox(height: 20),
                              buildIntervalSelector(),
            const SizedBox(height: 20),
            buildSignals(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
