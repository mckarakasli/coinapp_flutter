import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/traderlist.dart';

class TradeCardList extends StatelessWidget {
  final List<Trade> trades;
  final bool isOpen;
  final Function(Trade) onClose;

  const TradeCardList({
    required this.trades,
    required this.isOpen,
    required this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (trades.isEmpty) {
      return const Center(
        child: Text("İşlem bulunamadı", style: TextStyle(color: Colors.white)),
      );
    }

    return ListView.builder(
      itemCount: trades.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final trade = trades[index];

        final directionUp = trade.direction.toLowerCase() == 'up';
        final directionIcon =
            directionUp ? Icons.arrow_upward : Icons.arrow_downward;
        final directionColor =
            directionUp ? Colors.greenAccent : Colors.redAccent;

        final elapsedTime = trade.closedTime != null
            ? _calculateElapsedTime(trade.created_at, trade.closedTime!)
            : '';

        final rateColor =
            trade.rate < 0 ? Colors.redAccent : Colors.greenAccent;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1F1F1F), Color(0xFF333333)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst Bilgi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          trade.symbol,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(directionIcon, color: directionColor),
                        const SizedBox(width: 6),
                        Text(
                          trade.direction.toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      trade.username,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Fiyatlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Giriş: \$${trade.formattedEntryPrice}",
                            style: GoogleFonts.poppins(color: Colors.white70)),
                        Text("Hedef: \$${trade.formattedTargetPrice}",
                            style: GoogleFonts.poppins(color: Colors.white70)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Stop: \$${trade.formattedStopLoss}",
                            style: GoogleFonts.poppins(
                                color: Colors.orangeAccent)),
                        Text("Anlık: \$${trade.formattedCurrentPrice}",
                            style: GoogleFonts.poppins(color: Colors.white54)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Rate
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Rate: %${trade.formattedRate}",
                    style: GoogleFonts.poppins(
                      color: rateColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Yorum (isteğe bağlı)
                if (trade.comment.isNotEmpty)
                  Text(
                    "Yorum: ${trade.comment}",
                    style: GoogleFonts.poppins(
                        color: Colors.amberAccent, fontStyle: FontStyle.italic),
                  ),

                const SizedBox(height: 10),

                // Açık işlemse kapat butonu
                if (isOpen)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => _confirmClose(context, trade),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                      child: const Text("İşlemi Kapat"),
                    ),
                  ),

                const SizedBox(height: 8),

                // Tarih Bilgisi
                Text("Oluşturulma: ${trade.created_at.toString()}",
                    style: GoogleFonts.poppins(color: Colors.white70)),
                if (!isOpen && trade.closedTime != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Kapanma: ${trade.closedTime.toString()}",
                          style: GoogleFonts.poppins(color: Colors.white70)),
                      if (elapsedTime.isNotEmpty)
                        Text("Geçen Süre: $elapsedTime",
                            style:
                                GoogleFonts.poppins(color: Colors.greenAccent)),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _calculateElapsedTime(DateTime start, DateTime end) {
    final diff = end.difference(start);
    return "${diff.inDays} gün, ${diff.inHours % 24} saat";
  }

  void _confirmClose(BuildContext context, Trade trade) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title:
            const Text("İşlemi Kapat", style: TextStyle(color: Colors.white)),
        content: const Text("İşlemi kapatmak istiyor musunuz?",
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onClose(trade);
            },
            child: const Text("Onayla", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
