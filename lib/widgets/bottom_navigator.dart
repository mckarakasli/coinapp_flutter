import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF2E2E2E), // koyu gri arka plan
      selectedItemColor: Colors.amber, // seçili buton sarı
      unselectedItemColor: Colors.white54, // seçilmemiş butonlar şeffaf beyaz
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Panel'),
        BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_num), label: 'Liderlik Tablosu'),
        BottomNavigationBarItem(
            icon: Icon(Icons.account_balance), label: 'Profilim'),
        BottomNavigationBarItem(
            icon: Icon(Icons.signal_cellular_0_bar_outlined), label: 'Signals'),
      ],
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed, // 4 item olduğu için fixed önerilir
    );
  }
}
