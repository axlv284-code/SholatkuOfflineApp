import 'package:geolocator/geolocator.dart';

class LocationService {
  static const double targetLat = -6.9660851;
  static const double targetLong = 110.4019238;

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Layanan lokasi (GPS) tidak aktif.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Izin lokasi ditolak');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Izin lokasi ditolak permanen, silakan cek pengaturan HP');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  double hitungJarak(double userLat, double userLong) {
    return Geolocator.distanceBetween(userLat, userLong, targetLat, targetLong);
  }
}
