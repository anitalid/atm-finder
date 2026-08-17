import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

/*
 * Service untuk mengubah koordinat (lat/lng) menjadi alamat jalan
 * yang lebih manusiawi, memakai Nominatim (reverse geocoding
 * gratis dari OpenStreetMap).
 *
 * KAPAN DIPAKAI:
 * Bukan untuk semua ATM sekaligus (akan kena rate limit dan
 * melanggar usage policy Nominatim: max 1 request/detik).
 * Idealnya dipanggil satu-per-satu, HANYA saat:
 *   1. Alamat dari tag OSM ternyata kosong/generik
 *      (mis. "Lokasi: ATM UMY"), DAN
 *   2. Belum pernah di-resolve sebelumnya (dicek dari cache
 *      Firestore terlebih dahulu).
 *
 * HASIL SELALU DI-CACHE ke Firestore (field 'alamatResolved'
 * pada dokumen ATM) supaya panggilan berikutnya untuk ATM yang
 * sama tidak perlu hit Nominatim lagi.
 */
class GeocodingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _nominatimUrl =
      'https://nominatim.openstreetmap.org/reverse';

  /*
   * Ambil alamat untuk satu ATM. Urutan prioritas:
   *
   * 1. Cache Firestore (field 'alamatResolved') - kalau sudah
   *    pernah di-resolve sebelumnya, langsung pakai ini, TIDAK
   *    perlu hit Nominatim lagi.
   * 2. Kalau belum ada cache, panggil Nominatim, simpan hasilnya
   *    ke Firestore, lalu kembalikan.
   * 3. Kalau Nominatim gagal (network error, rate limit, dll),
   *    kembalikan null - caller tetap pakai alamat fallback
   *    dari OSM tags seperti sebelumnya.
   */
  Future<String?> resolveAddress({
    required String atmId,
    required double latitude,
    required double longitude,
  }) async {
    // ------------------------------------------------------
    // 1. CEK CACHE FIRESTORE DULU
    // ------------------------------------------------------
    try {
      final doc = await _db.collection('atms').doc(atmId).get();
      final cached = doc.data()?['alamatResolved'] as String?;

      if (cached != null && cached.trim().isNotEmpty) {
        return cached;
      }
    } catch (_) {
      // Kalau cache gagal dibaca (mis. dokumen belum ada),
      // tetap lanjut ke reverse geocoding di bawah.
    }

    // ------------------------------------------------------
    // 2. PANGGIL NOMINATIM
    // ------------------------------------------------------
    try {
      final uri = Uri.parse(_nominatimUrl).replace(queryParameters: {
        'format': 'jsonv2',
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'addressdetails': '1',
        'zoom': '18', // level detail setingkat nama jalan/bangunan
      });

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);

      final request = await client.getUrl(uri);

      /*
       * WAJIB set User-Agent yang jelas - ini syarat penggunaan
       * Nominatim (kebijakan mereka menolak request tanpa
       * identitas aplikasi yang jelas).
       */
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'ATM-Finder/1.0 (contact: your-email@example.com)',
      );

      final response =
          await request.close().timeout(const Duration(seconds: 10));

      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 10));

      client.close(force: true);

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      final formatted = _formatNominatimResult(data);

      if (formatted == null) {
        return null;
      }

      // --------------------------------------------------
      // 3. SIMPAN KE CACHE FIRESTORE
      // --------------------------------------------------
      try {
        await _db.collection('atms').doc(atmId).set(
          {'alamatResolved': formatted},
          SetOptions(merge: true),
        );
      } catch (_) {
        // Gagal simpan cache bukan masalah fatal - alamat
        // tetap dikembalikan ke caller, cuma nanti akan
        // di-resolve ulang di panggilan berikutnya.
      }

      return formatted;
    } catch (_) {
      return null;
    }
  }

  /*
   * Susun hasil JSON Nominatim jadi format alamat pendek yang
   * enak dibaca, mirip gaya penulisan Google Maps:
   * "Jl. Kaliurang KM 14, Sinduadi, Sleman"
   */
  String? _formatNominatimResult(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;

    if (address == null) return null;

    final parts = <String>[];

    final road = address['road']?.toString();
    final houseNumber = address['house_number']?.toString();

    if (road != null && road.isNotEmpty) {
      if (houseNumber != null && houseNumber.isNotEmpty) {
        parts.add('$road No. $houseNumber');
      } else {
        parts.add(road);
      }
    }

    final village = address['village']?.toString() ??
        address['suburb']?.toString() ??
        address['neighbourhood']?.toString();

    if (village != null && village.isNotEmpty) {
      parts.add(village);
    }

    final city = address['city']?.toString() ??
        address['town']?.toString() ??
        address['county']?.toString();

    if (city != null && city.isNotEmpty) {
      parts.add(city);
    }

    if (parts.isEmpty) {
      // Fallback terakhir: pakai display_name penuh dari Nominatim
      return data['display_name']?.toString();
    }

    return parts.join(', ');
  }
}