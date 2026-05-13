import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // BASE URL tetep sama
  static const String baseUrl =
      'https://sholatku-backend-production.up.railway.app';

  // --- 1. Fungsi Register ---
  static Future<bool> register(String nama, String email, String password,
      String nisn, String kelas) async {
    try {
      final response = await http.post(
        // DITAMBAHIN /api biar nyambung ke kodingan Node.js lu
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama': nama,
          'email': email,
          'password': password,
          'nisn': nisn,
          'kelas': kelas,
        }),
      );
      print("Register Status: ${response.statusCode}");
      print("Register Response: ${response.body}");
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
        Uri.parse('$baseUrl/api/auth/verify-otp'),
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
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
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
        // Jangan lupa di sini juga tambahin /api
        Uri.parse('$baseUrl/api/presensi/absen'),
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
        Uri.parse('$baseUrl/api/presensi/riwayat'),
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
