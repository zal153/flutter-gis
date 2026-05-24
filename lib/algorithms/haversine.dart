import 'dart:math';

class HaversineAlgorithm {
  static const double _earthRadius = 6371.0; // km

  static double hitungJarak({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {

    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);

    final c = 2 * asin(sqrt(a));

    return _earthRadius * c;
  }

  static String formatJarak(double jarakKm) {
    if (jarakKm < 1.0) {
      return '${(jarakKm * 1000).toStringAsFixed(0)} m';
    }
    return '${jarakKm.toStringAsFixed(2)} km';
  }

  static String estimasiWaktu(double jarakKm) {
    final menitDouble = (jarakKm / 30) * 60;
    final menit = menitDouble.ceil();
    if (menit < 60) return '$menit menit';
    final jam = menit ~/ 60;
    final sisaMenit = menit % 60;
    return '$jam jam $sisaMenit menit';
  }

  /// Menghitung jam tiba berdasarkan waktu sekarang + durasi perjalanan.
  /// Contoh output: "19:02"
  static String estimasiWaktuTiba(double jarakKm) {
    final menitDouble = (jarakKm / 30) * 60;
    final durasiMenit = menitDouble.ceil();
    final sekarang = DateTime.now();
    final tiba = sekarang.add(Duration(minutes: durasiMenit));
    final jam = tiba.hour.toString().padLeft(2, '0');
    final menit = tiba.minute.toString().padLeft(2, '0');
    return '$jam:$menit';
  }
}
