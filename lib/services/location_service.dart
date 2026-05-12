import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
  }

  static Future<void> scheduleSholat() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails('sholat_channel', 'Jadwal Sholat',
          importance: Importance.max, priority: Priority.high),
    );
    final jadwal = [
      {'id': 1, 'nama': 'Dzuhur', 'jam': 11, 'menit': 58},
      {'id': 2, 'nama': 'Ashar', 'jam': 15, 'menit': 22},
    ];
    for (var s in jadwal) {
      await _plugin.zonedSchedule(
        s['id'] as int,
        'Waktu ${s['nama']} Tiba',
        'Ayo segera ke Masjid SMK 10!',
        _nextTime(s['jam'] as int, s['menit'] as int),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static tz.TZDateTime _nextTime(int h, int m) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
    if (scheduled.isBefore(now))
      scheduled = scheduled.add(const Duration(days: 1));
    return scheduled;
  }
}
