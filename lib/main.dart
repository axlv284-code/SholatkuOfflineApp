import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'services/location_service.dart';
import 'services/db_helper.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  tz.initializeTimeZones();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await Prefs.init();

  runApp(const SholatKuApp());
}

Route _createRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;

      const curve = Curves.easeInOutCubic;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}

Future<void> scheduleSholatNotifications() async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'sholat_channel',
    'Jadwal Sholat',
    importance: Importance.max,
    priority: Priority.high,
  );
  const NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
  );

  final jadwal = [
    {'id': 1, 'nama': 'Dzuhur', 'jam': 11, 'menit': 58},
    {'id': 2, 'nama': 'Ashar', 'jam': 15, 'menit': 22},
  ];

  for (var s in jadwal) {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      s['id'] as int,
      'Waktu ${s['nama']} Tiba',
      'Ayo segera ke Masjid SMK 10 untuk sholat berjamaah!',
      _nextInstanceOfTime(s['jam'] as int, s['menit'] as int),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledDate = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }
  return scheduledDate;
}

class Prefs {
  static late SharedPreferences _p;
  static Future init() async => _p = await SharedPreferences.getInstance();

  static Future saveUser(
      String n, String p, String ni, String e, String k) async {
    await _p.setString('name', n);
    await _p.setString('pass', p);
    await _p.setString('nisn', ni);
    await _p.setString('email', e);
    await _p.setString('kelas', k);
  }

  static Future setLoginStatus(bool val) async =>
      await _p.setBool('isLoggedIn', val);
  static bool getLoginStatus() => _p.getBool('isLoggedIn') ?? false;

  static String? getName() => _p.getString('name');
  static String? getPass() => _p.getString('pass');
  static String? getNisn() => _p.getString('nisn');
  static String? getEmail() => _p.getString('email');
  static String? getKelas() => _p.getString('kelas');
}

class SholatKuApp extends StatelessWidget {
  const SholatKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    bool isUserLoggedIn = Prefs.getLoginStatus();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0C46A1),
        scaffoldBackgroundColor: const Color(0xFFF8FAFD),
      ),
      home: isUserLoggedIn ? const MainNav() : const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0C46A1), Color(0xFFF7F8FA)],
            stops: [0.3, 0.3],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      )
                    ],
                  ),
                  child: Image.network(
                    'https://portalsemarang.com/wp-content/uploads/2011/05/smk-10-smg21-300x292.jpg',
                    height: 100,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "SHOLATKU SMK 10",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0C46A1),
                    letterSpacing: 1.2,
                  ),
                ),
                const Text(
                  "Silakan login untuk melakukan presensi",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 40),
                Card(
                  elevation: 5,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      children: [
                        TextField(
                          controller: _u,
                          decoration: InputDecoration(
                            hintText: "Email Pengguna",
                            prefixIcon: const Icon(Icons.person_outline),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _p,
                          obscureText: _isObscure,
                          decoration: InputDecoration(
                            hintText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_isObscure
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _isObscure = !_isObscure),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 55),
                            backgroundColor: const Color(0xFF0C46A1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () async {
                            final db = DbHelper();
                            String emailInput = _u.text.trim().toLowerCase();
                            String passInput = _p.text;

                            // 1. Cek login ke SQLite
                            var user =
                                await db.loginUser(emailInput, passInput);

                            if (user != null) {
                              await Prefs.setLoginStatus(true);

                              // AMBIL DATA DARI DATABASE (Bukan dari Prefs!)
                              // user['nama'] diambil dari kolom 'nama' di SQLite
                              String namaAsli = user['nama'] ?? "User";
                              String nisnAsli = user['nisn'] ?? "";
                              String kelasAsli = user['kelas'] ?? "";

                              // SIMPAN KE SESSION BIAR PROFIL BENAR
                              await Prefs.saveUser(namaAsli, passInput,
                                  nisnAsli, emailInput, kelasAsli);

                              if (mounted) {
                                scheduleSholatNotifications();
                                Navigator.of(context).pushReplacement(
                                    _createRoute(const MainNav()));
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Email atau Password salah!"),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                          child: const Text(
                            "MASUK",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).push(_createRoute(const RegPage())),
                  child: const Text(
                    "Belum punya akun? Daftar Sekarang",
                    style: TextStyle(
                      color: Color(0xFF0C46A1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegPage extends StatefulWidget {
  const RegPage({super.key});
  @override
  State<RegPage> createState() => _RegPageState();
}

class _RegPageState extends State<RegPage> {
  final _n = TextEditingController();
  final _pa = TextEditingController();
  final _ni = TextEditingController();
  final _em = TextEditingController();
  final _ke = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Akun Baru",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(30),
        children: [
          _regField(_n, "Nama Lengkap", Icons.person_outline),
          _regField(_ke, "Kelas (Contoh: XI PPLG 1)", Icons.class_outlined),
          _regField(_ni, "NISN", Icons.badge_outlined),
          _regField(_em, "Email", Icons.email_outlined),
          _regField(_pa, "Password", Icons.lock_outline, isPass: true),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              backgroundColor: const Color(0xFF0C46A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () async {
              final db = DbHelper();
              // Masukin semua data ke SQLite
              await db.registerUser(_n.text, _em.text.trim().toLowerCase(),
                  _pa.text, _ni.text, _ke.text);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Berhasil Daftar!")));
                Navigator.pop(context);
              }
            },
            child: const Text("SIMPAN DATA",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _regField(TextEditingController c, String l, IconData i,
      {bool isPass = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: c,
        obscureText: isPass,
        decoration: InputDecoration(
          labelText: l,
          prefixIcon: Icon(i),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _idx = 0;

  final _pgs = [
    const Home(),
    const PresensiPage(),
    const RiwayatPage(),
    const ProfilPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: IndexedStack(
          key: ValueKey<int>(_idx),
          index: _idx,
          children: _pgs,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) {
          if (_idx != i) {
            setState(() => _idx = i);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0C46A1),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_filled), label: "Beranda"),
          BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_rounded), label: "Presensi"),
          BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded), label: "Riwayat"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: "Profil"),
        ],
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _time = "";
  String _date = "";
  String _dist = "Mendeteksi...";
  List<Map<String, dynamic>> _today = [];
  final _db = DbHelper();
  final _l = LocationService();

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          _time = DateFormat('HH:mm:ss').format(DateTime.now());
          _date =
              DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
        });
      }
    });

    _initLocationTracking();
    _loadPresensiData();
  }

  void _initLocationTracking() async {
    try {
      await _l.getCurrentLocation();
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((Position p) {
        if (mounted) {
          double d = _l.hitungJarak(p.latitude, p.longitude);
          setState(() {
            _dist = "${d.toStringAsFixed(0)}m dari Masjid";
          });
        }
      });
    } catch (e) {
      if (mounted) setState(() => _dist = "GPS/Izin Bermasalah");
    }
  }

  void _loadPresensiData() async {
    // Filter data berdasarkan email user aktif
    final list = await _db.getPresensiByUser(Prefs.getEmail() ?? "");
    if (mounted) {
      setState(() {
        _today = list;
      });
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Beranda",
            style: TextStyle(fontWeight: FontWeight.w900)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0C46A1), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0C46A1).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Waktu Sekarang",
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 5),
                  Text(_time,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                  Text(_date,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.orangeAccent, size: 18),
                      const SizedBox(width: 5),
                      Text(_dist,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text("Jadwal Sholat",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                    child: _itemS(
                        "Dzuhur", "11:58", Icons.wb_sunny, Colors.orange)),
                const SizedBox(width: 15),
                Expanded(
                    child: _itemS("Ashar", "15:22", Icons.cloud, Colors.blue)),
              ],
            ),
            const SizedBox(height: 30),
            const Text("Presensi Hari Ini",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            _today.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text("Belum ada absen",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)),
                  )
                : Column(
                    children: _today
                        .take(2)
                        .map((e) => Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              elevation: 1,
                              child: ListTile(
                                leading: const Icon(Icons.check_circle,
                                    color: Colors.green, size: 30),
                                title: Text(e['nama_sholat'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text("${e['waktu']} • ${e['jarak']}"),
                              ),
                            ))
                        .toList(),
                  ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFBBDEFB)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_rounded, color: Color(0xFF0C46A1)),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "Mari berjamaah di masjid SMK 10 Semarang.",
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0C46A1),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _itemS(String n, String j, IconData i, Color c) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(i, color: c, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600)),
              Text(j,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

class PresensiPage extends StatefulWidget {
  const PresensiPage({super.key});
  @override
  State<PresensiPage> createState() => _PresensiPageState();
}

class _PresensiPageState extends State<PresensiPage> {
  File? _img;
  final _db = DbHelper();
  final _loc = LocationService();
  double _rawDist = 999.0;
  String _sel = "Dzuhur";

  void _updateLocation() async {
    try {
      Position p = await _loc.getCurrentLocation();
      if (mounted) {
        setState(() {
          _rawDist = _loc.hitungJarak(p.latitude, p.longitude);
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _updateLocation();
  }

  @override
  Widget build(BuildContext context) {
    bool isNearby = _rawDist <= 50;
    Color accentColor = isNearby ? Colors.green : Colors.redAccent;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Presensi",
            style: TextStyle(fontWeight: FontWeight.w900)),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(35),
            ),
            child: Row(
              children: [
                Expanded(child: _buildTabItem("Dzuhur")),
                Expanded(child: _buildTabItem("Ashar")),
              ],
            ),
          ),
          const SizedBox(height: 35),
          GestureDetector(
            onTap: () async {
              final x = await ImagePicker().pickImage(
                source: ImageSource.camera,
                preferredCameraDevice: CameraDevice.front,
              );
              if (x != null) {
                _updateLocation();
                setState(() => _img = File(x.path));
              }
            },
            child: Container(
              height: 380,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: const Color(0xFF0C46A1).withOpacity(0.2), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ],
              ),
              child: _img == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_front_rounded,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 15),
                        const Text("Klik Ambil Foto Selfie",
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold)),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.file(_img!, fit: BoxFit.cover),
                    ),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(isNearby ? Icons.location_on : Icons.location_off,
                    color: accentColor),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isNearby ? "Lokasi Sesuai" : "Lokasi Terlalu Jauh",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: accentColor),
                      ),
                      Text(
                        "Jarak: ${_rawDist.toStringAsFixed(0)}m dari lokasi.",
                        style: TextStyle(
                            fontSize: 12, color: accentColor.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 35),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 65),
              backgroundColor: const Color(0xFF0C46A1),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              shadowColor: const Color(0xFF0C46A1).withOpacity(0.4),
            ),
            onPressed: (_img == null || !isNearby)
                ? null
                : () async {
                    // Menyertakan email_user saat menyimpan absen ke SQLite
                    await _db.simpanPresensi({
                      'nama_sholat': _sel,
                      'waktu': DateFormat('HH:mm').format(DateTime.now()),
                      'jarak': "${_rawDist.toStringAsFixed(0)}m",
                      'foto_path': _img!.path,
                      'email_user': Prefs.getEmail() ?? "",
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Berhasil Absen!"),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (c) => const MainNav()));
                    }
                  },
            child: const Text("KIRIM ABSEN",
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title) {
    bool isSelected = _sel == title;
    return GestureDetector(
      onTap: () => setState(() => _sel = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0C46A1) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: const Color(0xFF0C46A1).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat",
            style: TextStyle(fontWeight: FontWeight.w900)),
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Mengambil riwayat dari SQLite berdasarkan email yang sedang login
        future: DbHelper().getPresensiByUser(Prefs.getEmail() ?? ""),
        builder: (c, s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.data!.isEmpty) {
            return const Center(
                child: Text("Belum ada riwayat untuk akun ini."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: s.data!.length,
            itemBuilder: (c, i) => Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.data![i]['nama_sholat'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    s.data![i]['waktu'],
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});
  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0C46A1), Color(0xFF1E88E5)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: Offset(0, 8),
                )
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 50),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white30,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child:
                        Icon(Icons.person, size: 65, color: Color(0xFF0C46A1)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  Prefs.getName() ?? "Siswa SMK 10",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Kelas ${Prefs.getKelas() ?? "Belum Diatur"}",
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(25, 30, 25, 20),
              children: [
                _buildModernBox(
                    "NISN", Prefs.getNisn() ?? "-", Icons.badge_rounded),
                _buildModernBox("Email Akun", Prefs.getEmail() ?? "-",
                    Icons.alternate_email_rounded),
                _buildModernBox("Institusi", "SMK Negeri 10 Semarang",
                    Icons.school_rounded),
                const SizedBox(height: 35),
                GestureDetector(
                  onTap: () async {
                    await Prefs.setLoginStatus(false);
                    if (mounted) {
                      Navigator.of(context)
                          .pushReplacement(_createRoute(const LoginPage()));
                    }
                  },
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5252).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "LOGOUT DARI APLIKASI",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Versi Aplikasi 1.0.2",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBox(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0C46A1).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0C46A1), size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
