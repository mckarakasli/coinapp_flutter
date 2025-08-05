import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class SignalPage extends StatefulWidget {
  const SignalPage({Key? key}) : super(key: key);

  @override
  State<SignalPage> createState() => _SignalPageState();
}

class _SignalPageState extends State<SignalPage> {
  Map<String, dynamic>? results;
  List<String> errors = [];
  bool isLoading = true;

  final List<String> intervals = ["15m", "1h", "4h", "1d"];
  String selectedInterval = "1h";

  @override
  void initState() {
    super.initState();
    fetchSignals();
  }

  Future<void> fetchSignals() async {
    final url = Uri.parse("http://88.222.220.109:8004/signals");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          results = data["results"];
          errors = List<String>.from(data["errors"] ?? []);
          isLoading = false;
        });
      } else {
        throw Exception("Sunucu hatası: ${response.statusCode}");
      }
    } catch (e) {
      print("Hata: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  String getSingleSignal(String value) {
    return value == "AL" ? "AL" : "SAT";
  }

  Color getSignalColor(String signal) {
    return signal == "AL" ? Colors.greenAccent : Colors.redAccent;
  }

  // Burada EMA sinyalini küçük yatay kutucuk olarak gösteriyoruz
  Widget buildSingleEmaSignal(String ema, String status) {
    final signal = getSingleSignal(status);
    return Container(
      margin: const EdgeInsets.only(right: 10, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: getSignalColor(signal), width: 2),
        boxShadow: [
          BoxShadow(
            color: getSignalColor(signal).withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ema,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.amber.shade300,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            signal == "AL" ? Icons.check_circle : Icons.cancel,
            color: getSignalColor(signal),
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            signal,
            style: GoogleFonts.montserrat(
              color: getSignalColor(signal),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Seçilen interval için tüm sinyalleri yatay liste yapıyoruz
  Widget buildIntervalPanel(String interval, Map<String, dynamic> signals) {
    if (interval != selectedInterval) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$interval EMA Sinyalleri",
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.amber.shade400,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: signals.entries
                .map((entry) =>
                    buildSingleEmaSignal(entry.key, entry.value.toString()))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget buildCoinCard(String symbol, Map<String, dynamic> coinData) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: Colors.grey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              symbol,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade300,
              ),
            ),
            const Divider(color: Colors.amberAccent, thickness: 1.2),
            ...coinData.entries.map((entry) {
              final interval = entry.key;
              final signals = Map<String, dynamic>.from(entry.value);
              return buildIntervalPanel(interval, signals);
            }),
          ],
        ),
      ),
    );
  }

  Widget buildIntervalSelector() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: intervals.map((interval) {
          final isSelected = interval == selectedInterval;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ChoiceChip(
              label: Text(
                interval,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : Colors.white,
                ),
              ),
              selected: isSelected,
              selectedColor: Colors.amber,
              backgroundColor: Colors.grey.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    selectedInterval = interval;
                  });
                }
              },
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "EMA Sinyalleri",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Column(
        children: [
          buildIntervalSelector(),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  )
                : results == null
                    ? Center(
                        child: Text(
                          "Veri alınamadı.",
                          style: GoogleFonts.montserrat(color: Colors.white70),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchSignals,
                        color: Colors.amber,
                        child: ListView(
                          padding: const EdgeInsets.only(top: 12, bottom: 20),
                          children: [
                            ...results!.entries.map((entry) => buildCoinCard(
                                entry.key,
                                Map<String, dynamic>.from(entry.value))),
                            if (errors.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  "Hatalı Coinler: ${errors.join(', ')}",
                                  style: GoogleFonts.montserrat(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
