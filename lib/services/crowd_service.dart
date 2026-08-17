import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/crowd_report.dart';

/// Rata-rata keramaian pada satu jam tertentu (0-23), hasil agregasi laporan historis.
class CrowdPatternPoint {
  final int hour;
  final double avgScore;
  final int reportCount;
  const CrowdPatternPoint({required this.hour, required this.avgScore, required this.reportCount});

  CrowdLevel get level => CrowdLevelX.fromScore(avgScore);
}

class CrowdService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Jendela waktu yang dianggap "saat ini" saat menghitung level keramaian.
  static const _currentWindow = Duration(hours: 2);

  /// Pengguna melaporkan tingkat keramaian sebuah ATM.
  Future<void> submitReport(String atmId, CrowdLevel level) async {
    final uid = _uid;
    if (uid == null || atmId.trim().isEmpty) return;
    final report = CrowdReport(
      id: '', // diisi Firestore
      atmId: atmId,
      userId: uid,
      level: level,
      createdAt: DateTime.now(),
    );
    await _db.collection('crowd_reports').add(report.toMap());
  }

  /// Mengambil laporan keramaian dalam [_currentWindow] jam terakhir untuk satu ATM.
  Future<List<CrowdReport>> _recentReports(String atmId) async {
    final since = DateTime.now().subtract(_currentWindow);
    final snap = await _db
        .collection('crowd_reports')
        .where('atmId', isEqualTo: atmId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(since))
        .get();
    return snap.docs.map((d) => CrowdReport.fromMap(d.id, d.data())).toList();
  }

  /// Level keramaian ATM saat ini, dihitung dari rata-rata laporan terbaru.
  /// Return null jika belum ada laporan dalam jendela waktu tersebut.
  Future<CrowdLevel?> getCurrentCrowdLevel(String atmId) async {
    final reports = await _recentReports(atmId);
    if (reports.isEmpty) return null;
    final avg = reports.map((r) => r.level.score).reduce((a, b) => a + b) / reports.length;
    return CrowdLevelX.fromScore(avg);
  }

  /// Level keramaian saat ini untuk banyak ATM sekaligus (mis. untuk hasil pencarian).
  /// Key = atmId, value = null jika belum ada laporan.
  Future<Map<String, CrowdLevel?>> getCurrentCrowdLevels(List<String> atmIds) async {
    final result = <String, CrowdLevel?>{};
    for (final id in atmIds) {
      result[id] = await getCurrentCrowdLevel(id);
    }
    return result;
  }

  /// Stream laporan terbaru sebuah ATM, untuk tampilan real-time di detail_screen.
  Stream<List<CrowdReport>> watchReports(String atmId) {
    return _db
        .collection('crowd_reports')
        .where('atmId', isEqualTo: atmId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CrowdReport.fromMap(d.id, d.data())).toList());
  }

  /// Jumlah laporan historis minimum sebelum pola waktu dianggap cukup dipercaya untuk ditampilkan.
  static const _minReportsForPattern = 5;

  /// Ambil semua laporan historis sebuah ATM (dibatasi 500 laporan terbaru untuk efisiensi),
  /// lalu kelompokkan rata-rata level keramaian per jam (0-23).
  Future<List<CrowdPatternPoint>> getCrowdPattern(String atmId) async {
    final snap = await _db
        .collection('crowd_reports')
        .where('atmId', isEqualTo: atmId)
        .orderBy('createdAt', descending: true)
        .limit(500)
        .get();
    final reports = snap.docs.map((d) => CrowdReport.fromMap(d.id, d.data())).toList();

    // Kelompokkan skor per jam (0-23).
    final byHour = <int, List<int>>{};
    for (final r in reports) {
      byHour.putIfAbsent(r.hour, () => []).add(r.level.score);
    }

    return byHour.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return CrowdPatternPoint(hour: e.key, avgScore: avg, reportCount: e.value.length);
    }).toList()
      ..sort((a, b) => a.hour.compareTo(b.hour));
  }

  /// Ringkasan jam paling ramai dalam bentuk teks siap tampil, mis. "Biasanya ramai jam 12.00".
  /// Return null jika data historis belum cukup untuk disimpulkan.
  Future<String?> getPeakHourSummary(String atmId) async {
    final pattern = await getCrowdPattern(atmId);
    final totalReports = pattern.fold<int>(0, (sum, p) => sum + p.reportCount);
    if (totalReports < _minReportsForPattern) return null;

    final busiest = pattern.reduce((a, b) => a.avgScore >= b.avgScore ? a : b);
    if (busiest.level.score < CrowdLevel.sedang.score) return null; // pola belum jelas ramai

    final jam = busiest.hour.toString().padLeft(2, '0');
    return 'Biasanya ${busiest.level.label.toLowerCase()} sekitar jam $jam.00';
  }
}
