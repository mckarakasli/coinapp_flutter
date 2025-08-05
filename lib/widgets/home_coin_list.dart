import 'package:coinappproject/models/traderlist.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PopularTradesList extends StatelessWidget {
  final List<Trade> topTrades;
  final bool isLoading;

  const PopularTradesList({
    super.key,
    required this.topTrades,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(
        color: Colors.white,
      ));
    }

    return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: topTrades.length,
        itemBuilder: (context, index) {
          final trade = topTrades[index];

          // Rate color based on the value
          Color rateColor =
              trade.rate < 0 ? Colors.redAccent : Colors.greenAccent;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1F1F1F),
                  Color(0xFF333333),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Symbol and Up/Down indicator
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
                          Icon(
                            trade.direction.toLowerCase() == 'buy'
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: trade.direction.toLowerCase() == 'buy'
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            trade.direction.toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      // Username
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            trade.username,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Entry, Target and Stop Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Entry: \$${trade.formattedEntryPrice}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Target: \$${trade.formattedTargetPrice}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Stop Loss: \$${trade.formattedStopLoss}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                                                    Text(
                            'Anlık Fiyat: \$${trade.formattedCurrentPrice}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Rate Color (if negative)
                  Text(
                    'Rate: ${trade.rate.toStringAsFixed(2)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: rateColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }
}

