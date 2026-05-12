import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // GANTI IP INI tiap kali lu ganti hotspot/wifi (cek pake 'ip addr')
  static const String baseUrl = 'http://10.180.79.222:3000/api';

  // --- 1. Fungsi Register ---
  // Ditambahin parameter nisn dan kelas biar masuk ke tabel users lu
  static Future<bool> register(String nama, String email, String password,
      String nisn, String kelas) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama': nama,
          'email': email,
          'password': password,
          'nisn': nisn,
          'kelas': kelas,
        }),
      );
      // Return true kalau backend ngirim status 201
      return response.statusCode == 201;
    } catch (e) {
      print("Register Error: $e");
      return false;
    }
  }

  // --- 2. Fungsi Verifikasi OTP ---
  static Future<bool> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Verify OTP Error: $e");
      return false;
    }
  }

  // --- 3. Fungsi Login ---
  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Biar lu tau errornya apa (misal: "Email belum diverifikasi")
        print("Login Gagal: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Login Connection Error: $e");
      return null;
    }
  }

  // --- 4. Fungsi Kirim Absen ---
  static Future<bool> kirimAbsen(String jenis, String lokasi) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/presensi/absen'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'jenis_sholat': jenis, 'lokasi': lokasi}),
      );

      print("Absen Status: ${response.statusCode}");
      return response.statusCode == 201;
    } catch (e) {
      print("Absen Error: $e");
      return false;
    }
  }

  // --- 5. Fungsi Ambil Riwayat ---
  static Future<List<dynamic>> ambilRiwayat() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/presensi/riwayat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error Ambil Riwayat: $e");
    }
    return [];
  }
}
