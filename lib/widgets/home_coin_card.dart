import 'package:coinappproject/models/coincard.dart';
import 'package:coinappproject/screens/childPages/coin_detail_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CoinCard extends StatelessWidget {
  final Coin coin;

  const CoinCard({super.key, required this.coin});

  @override
  Widget build(BuildContext context) {
    final String changeStr =
        coin.formattedPriceChangePercent.replaceAll('%', '').trim();
    final double change = double.tryParse(changeStr) ?? 0.0;

    final bool isPositive = change >= 0;
    final Color changeColor = isPositive ? Colors.green : Colors.red;
    final IconData changeIcon =
        isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CoinDetailPage(name: coin.name, price: coin.price),
          ),
        );
      },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        color: Colors.white,
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Coin simgesi ve adı
              Row(
                children: [
            Image.asset(
                    'assets/images/${coin.symbol.toLowerCase()}.png',
                    width: 28.w,
                    height: 28.w,
                    package: null, // varsayılan paket
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.monetization_on,
                          size: 28.w, color: Colors.grey);
                    },
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      coin.name,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 4.h),

              // Fiyat
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "\$${coin.formattedPrice}",
                  style: GoogleFonts.lato(
                    fontSize: 13.sp,
                    color: Colors.black87,
                  ),
                ),
              ),

              SizedBox(height: 2.h),

              // Değişim yüzdesi
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    changeIcon,
                    color: changeColor,
                    size: 16.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${change.toStringAsFixed(2)}%',
                    style: GoogleFonts.lato(
                      fontSize: 12.sp,
                      color: changeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
