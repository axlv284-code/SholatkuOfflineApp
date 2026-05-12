import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart'; // Tambah ini
import 'services/notification_service.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/riwayat_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi format tanggal Indonesia dan Timezone
  await initializeDateFormatting('id_ID', null);
  tz.initializeTimeZones();

  // 2. Jalankan servis notifikasi
  await NotificationService.init();
  await NotificationService.scheduleSholat();

  // 3. CEK STATUS LOGIN (Auto-Login)
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');

  // 4. Jalankan aplikasi dengan status login (isLoggedIn)
  runApp(SholatKuApp(isLoggedIn: token != null));
}

class SholatKuApp extends StatelessWidget {
  final bool isLoggedIn; // Tambah variabel ini

  const SholatKuApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SholatKu SMK 10',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // 5. Tentukan halaman pertama:
      // Kalau isLoggedIn true, langsung ke HomePage. Kalau false, ke LoginPage.
      home: isLoggedIn ? const HomePage() : const LoginPage(),

      // Route tetep ada buat navigasi manual kalau butuh
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/riwayat': (context) => const RiwayatPage(),
      },
    );
  }
}
