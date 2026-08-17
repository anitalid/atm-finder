import 'package:cloud_firestore/cloud_firestore.dart';

/// Tingkat keramaian yang bisa dilaporkan pengguna.
enum CrowdLevel { sepi, sedang, ramai, sangatRamai }

extension CrowdLevelX on CrowdLevel {
  /// Label yang ditampilkan ke pengguna.
  String get label => switch (this) {
    CrowdLevel.sepi => 'Sepi',
    CrowdLevel.sedang => 'Sedang',
    CrowdLevel.ramai => 'Ramai',
    CrowdLevel.sangatRamai => 'Sangat Ramai',
  };

  /// Skor numerik 0-3, dipakai untuk agregasi & weighted scoring.
  /// Semakin besar = semakin ramai.
  int get score => index;

  static CrowdLevel fromScore(num s) {
    final i = s.round().clamp(0, CrowdLevel.values.length - 1);
    return CrowdLevel.values[i];
  }

  static CrowdLevel fromLabel(String label) => CrowdLevel.values.firstWhere(
    (e) => e.label == label,
    orElse: () => CrowdLevel.sedang,
  );
}

/// Satu laporan keramaian dari seorang pengguna untuk satu ATM.
class CrowdReport {
  final String id, atmId, userId;
  final CrowdLevel level;
  final DateTime createdAt;

  const CrowdReport({
    required this.id,
    required this.atmId,
    required this.userId,
    required this.level,
    required this.createdAt,
  });

  /// Jam (0-23) saat laporan dibuat, dipakai untuk analisis pola waktu.
  int get hour => createdAt.hour;

  /// Hari dalam seminggu (1 = Senin ... 7 = Minggu), dipakai untuk pola waktu.
  int get dayOfWeek => createdAt.weekday;

  factory CrowdReport.fromMap(String id, Map<String, dynamic> m) => CrowdReport(
    id: id,
    atmId: m['atmId'] ?? '',
    userId: m['userId'] ?? '',
    level: CrowdLevelX.fromScore(m['levelScore'] ?? CrowdLevel.sedang.score),
    createdAt: (m['createdAt'] is Timestamp)
        ? (m['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'atmId': atmId,
    'userId': userId,
    'levelScore': level.score,
    'levelLabel': level.label,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
