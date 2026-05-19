import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'otp_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _nisnController = TextEditingController(); // Tambah ini
  final _kelasController = TextEditingController(); // Tambah ini

  void _handleRegister() async {
    // Cek semua field jangan sampai kosong
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passController.text.isEmpty ||
        _nisnController.text.isEmpty ||
        _kelasController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lengkapin dulu semua datanya!")));
      return;
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()));

    // SEKARANG KIRIM 5 ARGUMEN (Biar error di gambar ilang)
    bool success = await ApiService.register(
      _nameController.text,
      _emailController.text,
      _passController.text,
      _nisnController.text,
      _kelasController.text,
    );

    if (mounted) Navigator.pop(context);

    if (success) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  OtpVerificationPage(email: _emailController.text)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Gagal daftar, cek koneksi atau email sudah ada.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Daftar Akun"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: "Nama Lengkap", prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 15),
            TextField(
                controller: _nisnController,
                decoration: const InputDecoration(
                    labelText: "NISN", prefixIcon: Icon(Icons.numbers))),
            const SizedBox(height: 15),
            TextField(
                controller: _kelasController,
                decoration: const InputDecoration(
                    labelText: "Kelas (Contoh: XI RPL 1)",
                    prefixIcon: Icon(Icons.school))),
            const SizedBox(height: 15),
            TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: "Email", prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 15),
            TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: "Password", prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleRegister,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C46A1)),
                child: const Text("DAFTAR SEKARANG",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
