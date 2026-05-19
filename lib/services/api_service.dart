import 'dart:convert';
import 'dart:io'; // WAJIB ada buat ngebaca objek File foto
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      'https://sholatku-backend-production.up.railway.app';

  // --- 1. Fungsi Register ---
  static Future<bool> register(String nama, String email, String password,
      String nisn, String kelas) async {
    try {
      final response = await http.post(
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
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // --- 2. Fungsi Verifikasi OTP / Login Sukses ---
  static Future<bool> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        // AMANKAN SESSION: Menyimpan ID user asli hasil login OTP agar tidak menjadi "1" terus
        if (data['user'] != null && data['user']['id'] != null) {
          await prefs.setString('user_id', data['user']['id'].toString());
        } else if (data['id'] != null) {
          await prefs.setString('user_id', data['id'].toString());
        }

        if (data['token'] != null) {
          await prefs.setString('token', data['token']);
        }
        return true;
      }
      return false;
    } catch (e) {
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
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        // AMANKAN SESSION: Simpan ID saat login biasa sukses
        if (data['user'] != null && data['user']['id'] != null) {
          await prefs.setString('user_id', data['user']['id'].toString());
        } else if (data['id'] != null) {
          await prefs.setString('user_id', data['id'].toString());
        }

        if (data['token'] != null) {
          await prefs.setString('token', data['token']);
        }
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- 4. Fungsi Kirim Absen (MENERIMA PARAMETER USER ID NYATA) ---
  static Future<bool> kirimAbsen(
      String userId, String jenis, String lokasi, File fotoFile) async {
    try {
      final url = Uri.parse('$baseUrl/api/presensi/absen');

      // 1. Ubah file gambar fisik menjadi string Base64 teks biasa
      List<int> imageBytes = await fotoFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      print("-> Mengirim request untuk User ID: $userId");

      // 2. Kirim murni pakai http.post JSON standar
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'jenis': jenis,
          'jenis_sholat': jenis,
          'lokasi': lokasi,
          'foto_base64': base64Image,
        }),
      );

      print("Absen Status: ${response.statusCode}");
      print("Absen Response Server: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Absen Error di ApiService: $e");
      return false;
    }
  }

  // --- 5. Fungsi Ambil Riwayat (FIX SINKRON 100% SAMA BACKEND) ---
  static Future<List<dynamic>> ambilRiwayat() async {
    final prefs = await SharedPreferences.getInstance();
    // Ambil ID akun yang aktif, kalau tidak ada barulah mengarah ke fallback "1"
    final String userId = prefs.getString('user_id') ?? "1";

    try {
      print("-> Menarik data riwayat dari backend untuk User ID: $userId...");
      // Menembak langsung ke endpoint param: /api/presensi/riwayat/:user_id
      final response = await http.get(
        Uri.parse('$baseUrl/api/presensi/riwayat/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      print("Riwayat Status Code: ${response.statusCode}");
      print("Riwayat Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        // Jika backend mengembalikan object terstruktur { status: 'success', data: [...] }
        if (resData is Map && resData['data'] != null) {
          return resData['data'];
        }
        // Jika backend mengembalikan data mentah list array langsung
        if (resData is List) {
          return resData;
        }
      }
    } catch (e) {
      print("Error Ambil Riwayat di ApiService: $e");
    }
    return [];
  }
}
