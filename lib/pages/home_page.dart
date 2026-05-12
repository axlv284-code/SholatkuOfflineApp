import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'presensi_page.dart';
import 'riwayat_page.dart';
import 'login_page.dart'; // Import login page buat logout
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _userName = "User";
  String _userNisn = "-";
  String _userKelas = "XI RPL";

  late Timer _timer;
  String _formattedTime = "";
  String _formattedDate = "";
  String _jarakInfo = "Menghitung...";
  bool _diSekolah = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _updateTime();
    _checkDistance();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      _updateTime();
      if (t.tick % 10 == 0) {
        _checkDistance();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Ambil data asli dari SharedPreferences yang disimpan pas login
  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_nama') ?? "User";
      _userNisn = prefs.getString('user_nisn') ?? "-";
      // Kalau di login_page belum simpan kelas, defaultnya XI RPL
      _userKelas = prefs.getString('user_kelas') ?? "XI RPL";
    });
  }

  // Fungsi Logout
  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus token & session

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<void> _checkDistance() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      double distance = Geolocator.distanceBetween(
          position.latitude, position.longitude, -6.9659546, 110.4018987);

      if (mounted) {
        setState(() {
          _diSekolah = distance <= 50;
          _jarakInfo = "${distance.toInt()}m dari Masjid";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _jarakInfo = "Lokasi mati");
    }
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    setState(() {
      _formattedTime = DateFormat('HH:mm:ss').format(now);
      _formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
    });
  }

  List<Widget> _pages() => [
        _buildBeranda(),
        const PresensiPage(),
        const RiwayatPage(),
        const ProfilePage(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: _pages()[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0C46A1),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt), label: 'Presensi'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildBeranda() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Waktu Sekarang",
                    style: TextStyle(color: Colors.white70)),
                Text(_formattedTime,
                    style: const TextStyle(
                        fontSize: 45,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text(_formattedDate,
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 15),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_diSekolah ? Icons.verified_user : Icons.location_on,
                          color:
                              _diSekolah ? Colors.greenAccent : Colors.orange,
                          size: 18),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Lokasi Terdeteksi",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                          Text(_jarakInfo,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 25, 20, 15),
            child: Text("Jadwal Sholat",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Row(
            children: [
              _buildJadwalSmall(
                  "Dzuhur", "11:58", Icons.wb_sunny, Colors.orange),
              _buildJadwalSmall("Ashar", "15:22", Icons.cloud, Colors.blue),
            ],
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text("Presensi Hari Ini",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ]),
            child: const Center(
                child: Column(
              children: [
                Icon(Icons.assignment_turned_in_outlined,
                    color: Colors.grey, size: 40),
                SizedBox(height: 10),
                Text("Belum ada absen hari ini",
                    style: TextStyle(color: Colors.grey)),
              ],
            )),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildJadwalSmall(
      String nama, String waktu, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
            ]),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(nama,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(waktu,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfil() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 70, 20, 40),
          decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)]),
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white,
                  child:
                      Icon(Icons.person, size: 60, color: Color(0xFF0D47A1))),
              const SizedBox(height: 15),
              Text(_userName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text(_userKelas, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildInfoTile(Icons.badge, "NISN", _userNisn),
        _buildInfoTile(Icons.school, "Sekolah", "SMK Negeri 10 Semarang"),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Yakin mau keluar aplikasi, Xl?"),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Batal")),
                      TextButton(
                          onPressed: _handleLogout,
                          child: const Text("Keluar",
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text("LOGOUT DARI APLIKASI",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF0C46A1)),
      ),
      title:
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87)),
    );
  }
}
