import 'package:latlong2/latlong.dart';
import 'crowd_report.dart';

class Atm {
  final String id, nama, bank, alamat, jamOperasional;
  final double latitude, longitude;
  final List<String> fasilitas;

  const Atm({required this.id, required this.nama, required this.bank, required this.alamat,
    required this.latitude, required this.longitude, required this.fasilitas, required this.jamOperasional});

  LatLng get latLng => LatLng(latitude, longitude);

  // Firestore kamu nyimpen latitude/longitude sebagai String (mis. "-7.7433042"),
  // bukan number — jadi .toDouble() langsung bakal crash (NoSuchMethodError).
  // Helper ini nerima dua-duanya: kalau udah num, langsung dikonversi; kalau
  // String, di-parse dulu pakai double.tryParse(), fallback ke 0 kalau gagal.
  static double _parseCoord(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  factory Atm.fromMap(String id, Map<String, dynamic> m) => Atm(
    id: id,
    nama: m['nama'] ?? '', bank: m['bank'] ?? '', alamat: m['alamat'] ?? '',
    latitude: _parseCoord(m['latitude']), longitude: _parseCoord(m['longitude']),
    fasilitas: List<String>.from(m['fasilitas'] ?? []), jamOperasional: m['jamOperasional'] ?? '24 Jam',
  );

  Map<String, dynamic> toMap() => {
    'nama': nama, 'bank': bank, 'alamat': alamat, 'latitude': latitude,
    'longitude': longitude, 'fasilitas': fasilitas, 'jamOperasional': jamOperasional,
  };
}

class AtmResult {
  final Atm atm;
  final double jarakKm;
  /// Skor gabungan dari Weighted Scoring. Null jika ATM ini diranking murni berdasarkan jarak
  /// (mis. di peta utama), bukan lewat AtmService.rankAtms().
  final double? score;
  /// Level keramaian saat ini. Null jika belum ada laporan atau belum diambil.
  final CrowdLevel? crowdLevel;
  const AtmResult(this.atm, this.jarakKm, {this.score, this.crowdLevel});
}