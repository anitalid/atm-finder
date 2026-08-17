import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' hide Haversine;

import '../models/atm.dart';
import '../models/crowd_report.dart';
import '../models/filter.dart';
import '../utils/haversine.dart';
import '../utils/weighted_scoring.dart';
import 'crowd_service.dart';
import 'seed_data.dart';

class AtmService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CrowdService _crowdService = CrowdService();

  static const double _dedupeRadiusMeter = 30;

  Future<List<Atm>> getNearbyAtmsFromOSM({
    required LatLng user,
    int radiusMeter = 10000,
  }) async {
    const firstRadius = 5000;
    final secondRadius = radiusMeter > 5000 ? radiusMeter : 10000;

    final firstResults = await _queryOverpass(user: user, radiusMeter: firstRadius);

    if (firstResults.length >= 15) {
      return _sortByDistance(firstResults, user);
    }

    final secondResults = await _queryOverpass(user: user, radiusMeter: secondRadius);

    final allResults = <Atm>[...firstResults, ...secondResults];
    final deduped = _dedupeByDistance(allResults);

    return _sortByDistance(deduped, user);
  }

  Future<List<Atm>> _queryOverpass({
    required LatLng user,
    required int radiusMeter,
  }) async {
    const endpoints = [
      'https://overpass-api.de/api/interpreter',
      'https://overpass.kumi.systems/api/interpreter',
    ];

    final query = '''
[out:json][timeout:45];

(
  nwr["amenity"="atm"]
    (around:$radiusMeter,${user.latitude},${user.longitude});
  nwr["atm"="yes"]
    (around:$radiusMeter,${user.latitude},${user.longitude});
  nwr["amenity"="bank"]["atm"="yes"]
    (around:$radiusMeter,${user.latitude},${user.longitude});
  nwr["amenity"="atm"]["cash_withdrawal"="yes"]
    (around:$radiusMeter,${user.latitude},${user.longitude});
  nwr["amenity"="vending_machine"]["vending"="cash"]
    (around:$radiusMeter,${user.latitude},${user.longitude});
  nwr["amenity"="bank"]
    (around:$radiusMeter,${user.latitude},${user.longitude});
  nwr["office"="financial"]
    (around:$radiusMeter,${user.latitude},${user.longitude});
);

out center tags;
''';

    Object? lastError;

    for (final endpoint in endpoints) {
      HttpClient? client;

      try {
        client = HttpClient()..connectionTimeout = const Duration(seconds: 12);

        final request = await client.postUrl(Uri.parse(endpoint)).timeout(const Duration(seconds: 15));

        request.headers.contentType = ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');
        request.headers.set(HttpHeaders.userAgentHeader, 'ATM-Finder/1.0');
        request.write('data=${Uri.encodeComponent(query)}');

        final response = await request.close().timeout(const Duration(seconds: 50));
        final body = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 50));

        if (response.statusCode != 200) {
          throw Exception('Overpass ${response.statusCode}');
        }

        final data = jsonDecode(body) as Map<String, dynamic>;
        final elements = (data['elements'] as List?) ?? [];

        final results = <Atm>[];
        final usedIds = <String>{};

        for (final raw in elements) {
          final element = Map<String, dynamic>.from(raw as Map);
          final tags = element['tags'] == null
              ? <String, dynamic>{}
              : Map<String, dynamic>.from(element['tags'] as Map);

          double? latitude;
          double? longitude;

          if (element['lat'] != null && element['lon'] != null) {
            latitude = (element['lat'] as num).toDouble();
            longitude = (element['lon'] as num).toDouble();
          }

          final center = element['center'];
          if ((latitude == null || longitude == null) && center is Map) {
            if (center['lat'] != null && center['lon'] != null) {
              latitude = (center['lat'] as num).toDouble();
              longitude = (center['lon'] as num).toDouble();
            }
          }

          if (latitude == null || longitude == null) continue;

          final atmTag = tags['atm']?.toString().toLowerCase();
          final amenity = tags['amenity']?.toString();

          if ((amenity == 'bank' || tags['office'] == 'financial') && atmTag == 'no') {
            continue;
          }

          final id = 'osm_${element['type']}_${element['id']}';
          if (usedIds.contains(id)) continue;
          usedIds.add(id);

          final distance = Haversine.distanceKm(user.latitude, user.longitude, latitude, longitude);
          if (distance > radiusMeter / 1000) continue;

          final name = _getAtmName(tags);
          final bank = _detectBank(tags);
          final address = _getAddress(tags);
          final facilities = _getFacilities(tags);

          results.add(Atm(
            id: id,
            nama: name,
            bank: bank,
            alamat: address,
            latitude: latitude,
            longitude: longitude,
            fasilitas: facilities,
            jamOperasional: tags['opening_hours']?.toString() ?? '24 Jam',
          ));
        }

        // DEBUG SEMENTARA — hapus lagi setelah masalah data kosong ketemu.
        debugPrint('✅ OSM OK ($endpoint): ${results.length} elemen dari ${elements.length} raw elements');

        return _sortByDistance(results, user);
      } catch (e) {
        lastError = e;
        // DEBUG SEMENTARA — hapus lagi setelah masalah data kosong ketemu.
        debugPrint('❌ OSM ENDPOINT GAGAL ($endpoint): $e');
      } finally {
        client?.close(force: true);
      }
    }

    throw Exception('Gagal mengambil data ATM dari OpenStreetMap.\n$lastError');
  }

  List<Atm> _sortByDistance(List<Atm> atms, LatLng user) {
    atms.sort((a, b) {
      final distanceA = Haversine.distanceKm(user.latitude, user.longitude, a.latitude, a.longitude);
      final distanceB = Haversine.distanceKm(user.latitude, user.longitude, b.latitude, b.longitude);
      return distanceA.compareTo(distanceB);
    });
    return atms;
  }

  List<Atm> _dedupeByDistance(List<Atm> atms) {
    final result = <Atm>[];

    for (final candidate in atms) {
      final isDuplicate = result.any((existing) {
        final distanceMeter = Haversine.distanceKm(
              candidate.latitude,
              candidate.longitude,
              existing.latitude,
              existing.longitude,
            ) *
            1000;

        if (distanceMeter > _dedupeRadiusMeter) return false;

        final sameBank = candidate.bank == existing.bank ||
            candidate.bank == 'Lainnya' ||
            existing.bank == 'Lainnya';

        return sameBank;
      });

      if (!isDuplicate) result.add(candidate);
    }

    return result;
  }

  String _getAtmName(Map<String, dynamic> tags) {
    final names = [tags['name'], tags['branch'], tags['description']];
    for (final value in names) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    final operator = tags['operator']?.toString().trim();
    if (operator != null && operator.isNotEmpty) return 'ATM $operator';
    final brand = tags['brand']?.toString().trim();
    if (brand != null && brand.isNotEmpty) return 'ATM $brand';
    return 'ATM';
  }

  String _detectBank(Map<String, dynamic> tags) {
    final values = [
      tags['operator'],
      tags['brand'],
      tags['name'],
      tags['branch'],
      tags['description'],
    ].where((e) => e != null).map((e) => e.toString().toLowerCase()).join(' ');

    if (values.contains('bank central asia') || values.contains('bca')) return 'BCA';
    if (values.contains('bank negara indonesia') || values.contains('bni')) return 'BNI';
    if (values.contains('bank rakyat indonesia') || values.contains('bri')) return 'BRI';
    if (values.contains('bank mandiri') || values.contains('mandiri')) return 'Mandiri';
    if (values.contains('bank syariah indonesia') || values.contains('bsi')) return 'BSI';
    if (values.contains('cimb niaga') || values.contains('cimb')) return 'CIMB Niaga';
    if (values.contains('danamon')) return 'Danamon';
    if (values.contains('permata')) return 'Permata';
    if (values.contains('btn')) return 'BTN';
    if (values.contains('maybank')) return 'Maybank';

    return 'Lainnya';
  }

  String _getAddress(Map<String, dynamic> tags) {
    final parts = <String>[];
    final street = tags['addr:street']?.toString();
    final number = tags['addr:housenumber']?.toString();
    final village = tags['addr:village']?.toString();
    final suburb = tags['addr:suburb']?.toString();
    final city = tags['addr:city']?.toString();

    if (street != null && street.isNotEmpty) {
      parts.add(number != null && number.isNotEmpty ? '$street No. $number' : street);
    }
    if (village != null && village.isNotEmpty) parts.add(village);
    if (suburb != null && suburb.isNotEmpty) parts.add(suburb);
    if (city != null && city.isNotEmpty) parts.add(city);

    if (parts.isNotEmpty) return parts.join(', ');

    final name = tags['name']?.toString();
    if (name != null && name.isNotEmpty) return 'Lokasi: $name';

    return 'Lokasi ATM dari OpenStreetMap';
  }

  List<String> _getFacilities(Map<String, dynamic> tags) {
    final facilities = <String>['Tarik Tunai', 'Cek Saldo', 'Transfer'];

    final text = [
      tags['description'],
      tags['note'],
      tags['operator'],
      tags['name'],
      tags['atm'],
      tags['cash_withdrawal'],
    ].where((e) => e != null).map((e) => e.toString().toLowerCase()).join(' ');

    final cashIn = tags['cash_in']?.toString().toLowerCase();
    final hasCashInTag = cashIn == 'yes';

    if (hasCashInTag || text.contains('setor') || text.contains('deposit') || text.contains('cash deposit')) {
      facilities.add('Setor Tunai');
    }

    return facilities;
  }

  Future<List<Atm>> getCombinedAtms({
    required LatLng user,
    int radiusMeter = 10000,
  }) async {
    List<Atm> firestoreAtms = [];
    List<Atm> osmAtms = [];
    List<Atm> allFirestoreAtms = [];

    try {
      allFirestoreAtms = await getAllAtms();

      firestoreAtms = allFirestoreAtms.where((atm) {
        final distanceKm = Haversine.distanceKm(user.latitude, user.longitude, atm.latitude, atm.longitude);
        return distanceKm <= radiusMeter / 1000;
      }).toList();

      // DEBUG SEMENTARA — hapus lagi setelah masalah data kosong ketemu.
      debugPrint('✅ FIRESTORE OK: ${allFirestoreAtms.length} dokumen total, ${firestoreAtms.length} dalam radius');
    } catch (e) {
      // DEBUG SEMENTARA — hapus lagi setelah masalah data kosong ketemu.
      debugPrint('❌ FIRESTORE ERROR: $e');
      firestoreAtms = [];
    }

    try {
      osmAtms = await getNearbyAtmsFromOSM(user: user, radiusMeter: radiusMeter);
    } catch (e) {
      // DEBUG SEMENTARA — hapus lagi setelah masalah data kosong ketemu.
      debugPrint('❌ OSM ERROR (total gagal, semua endpoint): $e');
      osmAtms = [];
    }

    // Auto-cache ATM baru dari OSM ke koleksi 'atms' di Firestore, supaya:
    // 1. Ke depannya app makin gak tergantung Overpass API yang kadang
    //    down/timeout — data yang udah pernah ditemukan tetap ada di
    //    Firestore walau Overpass lagi bermasalah.
    // 2. Crowd report bisa nge-link ke ATM manapun (termasuk asal OSM),
    //    karena ID Firestore-nya konsisten sama Atm.id (mis. osm_node_123).
    // Dijalankan TANPA await (fire-and-forget) supaya gak bikin loading
    // beranda lebih lama; kalau gagal, cukup di-log, gak ganggu UI.
    _syncNewOsmAtmsToFirestore(osmAtms, allFirestoreAtms);

    final combined = <Atm>[...firestoreAtms, ...osmAtms];
    final deduped = _dedupeByDistance(combined);

    return _sortByDistance(deduped, user);
  }

  // Cuma nulis ATM OSM yang ID-nya BELUM ada di Firestore — biar gak
  // nulis ulang (dan gak kena biaya write) tiap kali user buka app di
  // lokasi yang sama, dan aman dipanggil berkali-kali (idempotent).
  void _syncNewOsmAtmsToFirestore(List<Atm> osmAtms, List<Atm> existingFirestoreAtms) {
    if (osmAtms.isEmpty) return;

    final existingIds = existingFirestoreAtms.map((a) => a.id).toSet();
    final newOnes = osmAtms.where((a) => !existingIds.contains(a.id)).toList();
    if (newOnes.isEmpty) return;

    () async {
      try {
        // Batas 1 batch Firestore = 500 write; radius pencarian ATM
        // biasanya jauh di bawah itu, jadi belum perlu di-chunk.
        final batch = _db.batch();
        for (final atm in newOnes) {
          batch.set(_db.collection('atms').doc(atm.id), atm.toMap(), SetOptions(merge: true));
        }
        await batch.commit();
        // DEBUG SEMENTARA — hapus lagi setelah dirasa cukup stabil.
        debugPrint('✅ AUTO-SYNC: ${newOnes.length} ATM baru dari OSM disimpan ke Firestore');
      } catch (e) {
        debugPrint('❌ AUTO-SYNC GAGAL: $e');
      }
    }();
  }

  Future<List<Atm>> getAllAtms() async {
    var snap = await _db.collection('atms').get();

    if (snap.docs.isEmpty) {
      final batch = _db.batch();
      for (final m in seedAtmList) {
        batch.set(_db.collection('atms').doc(m['nama'].toString().replaceAll(' ', '_')), m);
      }
      await batch.commit();
      snap = await _db.collection('atms').get();
    }

    return snap.docs.map((d) => Atm.fromMap(d.id, d.data())).toList();
  }

  List<AtmResult> _filterCandidates({
    required List<Atm> atms,
    required LatLng user,
    required AtmFilter filter,
    String query = '',
  }) {
    final q = query.trim().toLowerCase();
    final out = <AtmResult>[];

    for (final atm in atms) {
      if (filter.bank != 'Semua' && atm.bank != filter.bank) continue;
      if (!filter.fasilitas.every(atm.fasilitas.contains)) continue;

      if (q.isNotEmpty && !'${atm.nama} ${atm.alamat} ${atm.bank}'.toLowerCase().contains(q)) {
        continue;
      }

      final distance = Haversine.distanceKm(user.latitude, user.longitude, atm.latitude, atm.longitude);
      if (distance > filter.jarakMaksKm) continue;

      out.add(AtmResult(atm, distance));
    }

    return out;
  }

  List<AtmResult> nearestNeighbor({
    required List<Atm> atms,
    required LatLng user,
    required AtmFilter filter,
    String query = '',
  }) {
    final results = _filterCandidates(atms: atms, user: user, filter: filter, query: query);
    results.sort((a, b) => a.jarakKm.compareTo(b.jarakKm));
    return results;
  }

  Future<List<AtmResult>> rankAtms({
    required List<Atm> atms,
    required LatLng user,
    required AtmFilter filter,
    String query = '',
    ScoringWeights weights = const ScoringWeights(),
  }) async {
    final candidates = _filterCandidates(atms: atms, user: user, filter: filter, query: query);
    if (candidates.isEmpty) return candidates;

    final crowdLevels = await _crowdService.getCurrentCrowdLevels(candidates.map((c) => c.atm.id).toList());

    final jumlahFasilitasMaks = candidates.map((c) => c.atm.fasilitas.length).reduce((a, b) => a > b ? a : b);

    final scored = candidates.map((c) {
      final level = crowdLevels[c.atm.id];
      final score = computeAtmScore(
        jarakKm: c.jarakKm,
        jarakMaksKm: filter.jarakMaksKm,
        jumlahFasilitas: c.atm.fasilitas.length,
        jumlahFasilitasMaks: jumlahFasilitasMaks,
        crowdLevel: level,
        weights: weights,
      );
      return AtmResult(c.atm, c.jarakKm, score: score, crowdLevel: level);
    }).toList();

    scored.sort((a, b) => b.score!.compareTo(a.score!));
    return scored;
  }

  static String formatKm(double km) {
    return '${km.toStringAsFixed(2).replaceAll('.', ',')} km';
  }
}