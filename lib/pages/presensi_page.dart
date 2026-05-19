import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import buat session OTP

class PresensiPage extends StatefulWidget {
  const PresensiPage({super.key});

  @override
  State<PresensiPage> createState() => _PresensiPageState();
}

class _PresensiPageState extends State<PresensiPage> {
  String selectedSholat = "Dzuhur";
  XFile? imageFile;
  CameraController? _controller;
  bool _isCameraReady = false;
  String _distanceInfo = "Mencari Lokasi...";
  bool _canAbsen = false;
  double _buttonScale = 1.0;

  @override
  void initState() {
    super.initState();
    _setupCamera();
    _checkLocation();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(frontCamera, ResolutionPreset.medium);

      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _isCameraReady = true);
    } catch (e) {
      print("Error Kamera: $e");
    }
  }

  Future<void> _checkLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      double latMasjid = -7.004755;
      double lngMasjid = 110.272010;
      double distance = Geolocator.distanceBetween(
          position.latitude, position.longitude, latMasjid, lngMasjid);
      if (!mounted) return;
      setState(() {
        if (distance <= 50) {
          _distanceInfo = "Lokasi Sesuai (Jarak: ${distance.toInt()}m)";
          _canAbsen = true;
        } else {
          _distanceInfo =
              "Terlalu Jauh! Jarak: ${distance.toInt()}m.\nMax radius 50m dari Masjid.";
          _canAbsen = false;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _distanceInfo = "Gagal mendapatkan lokasi.");
    }
  }

  Future<File?> _kompresiFotoAsli(String targetPath) async {
    final tempDir = await getTemporaryDirectory();
    final outPath =
        "${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";

    print("-> Melakukan kompresi fisik file foto asli...");
    var result = await FlutterImageCompress.compressAndGetFile(
      targetPath,
      outPath,
      quality: 35,
      minWidth: 640,
      minHeight: 480,
    );

    if (result == null) return null;
    return File(result.path);
  }

  void _submitAbsensi() async {
    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Ambil foto muka lu dulu, Xl!"),
          backgroundColor: Colors.orange));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
    try {
      Position pos = await Geolocator.getCurrentPosition();

      // === AMBIL DATA USER ID LOGIN OTP DARI STORAGE HP ===
      final prefs = await SharedPreferences.getInstance();
      // Mengambil 'user_id' atau 'id', jika null fallback aman ke string "1"
      String userIdAsli =
          prefs.getString('user_id') ?? prefs.getInt('id')?.toString() ?? "1";

      File? fileMatang = await _kompresiFotoAsli(imageFile!.path);
      File fotoKirim = fileMatang ?? File(imageFile!.path);

      print("-> Mengirim absensi untuk User ID Nyata: $userIdAsli");
      print("-> Ukuran file terkompresi: ${await fotoKirim.length()} bytes");

      // Lempar data ke ApiService dengan parameter lengkap termasuk userIdAsli
      bool success = await ApiService.kirimAbsen(userIdAsli, selectedSholat,
          "${pos.latitude}, ${pos.longitude}", fotoKirim);

      if (mounted) Navigator.pop(context);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Absen Berhasil Terkirim Nyata!"),
            backgroundColor: Colors.green));
        setState(() => imageFile = null);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Gagal kirim absen! Server muntah data."),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print("Error Pas Kirim Absen: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Column(
        children: [
          const SizedBox(height: 50),
          const Text("Presensi",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(25)),
              child: Row(children: [
                _buildSholatTab("Dzuhur"),
                _buildSholatTab("Ashar")
              ]),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.blue.withOpacity(0.2), width: 2)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: imageFile != null
                    ? Stack(
                        children: [
                          Image.file(File(imageFile!.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton(
                              onPressed: () => setState(() => imageFile = null),
                              icon: const Icon(Icons.cancel,
                                  color: Colors.red, size: 35),
                            ),
                          )
                        ],
                      )
                    : _isCameraReady
                        ? Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              CameraPreview(_controller!),
                              Positioned(
                                bottom: 20,
                                child: GestureDetector(
                                  onTap: () async {
                                    final img =
                                        await _controller!.takePicture();
                                    setState(() => imageFile = img);
                                  },
                                  child: Container(
                                    height: 70,
                                    width: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 4),
                                    ),
                                    child: const Icon(Icons.camera_alt,
                                        color: Colors.white, size: 35),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: _canAbsen ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                Icon(_canAbsen ? Icons.location_on : Icons.location_off,
                    color: _canAbsen ? Colors.green : Colors.red),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_distanceInfo,
                      style: TextStyle(
                          color: _canAbsen ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
                if (!_canAbsen)
                  IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _checkLocation)
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _buttonScale = 0.95),
              onTapUp: (_) => setState(() => _buttonScale = 1.0),
              onTapCancel: () => setState(() => _buttonScale = 1.0),
              child: AnimatedScale(
                scale: _buttonScale,
                duration: const Duration(milliseconds: 100),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: (_canAbsen && imageFile != null)
                        ? _submitAbsensi
                        : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C46A1),
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        elevation: 5),
                    child: const Text("KIRIM ABSEN",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSholatTab(String nama) {
    bool isSelected = selectedSholat == nama;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedSholat = nama),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0C46A1) : Colors.transparent,
              borderRadius: BorderRadius.circular(25)),
          child: Center(
              child: Text(nama,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }
}
