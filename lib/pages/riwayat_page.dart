import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // WAJIB TAMBAH INI JIR AGAR FORMAT 'id_ID' AKTIF

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  late Future<List<dynamic>> _futureRiwayat;

  @override
  void initState() {
    super.initState();
    // Paksa aktifkan pelokalan bahasa Indonesia sebelum mengambil data
    initializeDateFormatting('id_ID', null);
    _refreshData();
  }

  // Fungsi buat ambil data ulang
  void _refreshData() {
    setState(() {
      _futureRiwayat = ApiService.ambilRiwayat();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Riwayat Presensi",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureRiwayat,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF0D47A1)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 10),
                  Text("Gagal memuat data: ${snapshot.error}",
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center),
                  TextButton(
                      onPressed: _refreshData, child: const Text("Coba Lagi"))
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off,
                      size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("Belum ada riwayat untuk akun ini.",
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 10),
                  TextButton(
                      onPressed: _refreshData,
                      child: const Text(
                        "Refresh Layar",
                        style: TextStyle(color: Color(0xFF0D47A1)),
                      ))
                ],
              ),
            );
          }

          final riwayat = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _refreshData(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: riwayat.length,
              itemBuilder: (context, index) {
                final item = riwayat[index];

                // Logic format tanggal yang aman
                String tglIndo = "Tanggal tidak valid";
                try {
                  // Mengatasi format string mentah dari SQL MySQL
                  String tglRaw = item['tanggal'].toString();
                  DateTime tglParsed = DateTime.parse(tglRaw);
                  tglIndo =
                      DateFormat('EEEE, d MMM yyyy', 'id_ID').format(tglParsed);
                } catch (e) {
                  tglIndo = item['tanggal'].toString();
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      // TAMPILKAN FOTO REAL DARI CLOUDINARY JIKA ADA URL-NYA
                      child: item['foto'] != null && item['foto'] != '-'
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                item['foto'],
                                width: 30,
                                height: 30,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(
                                    Icons.mosque,
                                    color: Color(0xFF1E88E5)),
                              ),
                            )
                          : const Icon(Icons.mosque, color: Color(0xFF1E88E5)),
                    ),
                    title: Text(
                      item['jenis_sholat'] ?? "Sholat",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text(tglIndo,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black87)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(item['waktu'] ?? "--:--",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text("Hadir",
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
