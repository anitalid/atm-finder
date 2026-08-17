import '../models/crowd_report.dart';

/// Bobot tiap kriteria dalam Weighted Scoring.
/// Total bobot tidak wajib 1.0, karena skor akhir dinormalisasi relatif antar ATM.
class ScoringWeights {
  final double jarak, fasilitas, keramaian;
  const ScoringWeights({this.jarak = 0.5, this.fasilitas = 0.2, this.keramaian = 0.3});
}

/// Menghitung skor gabungan satu ATM (semakin tinggi semakin direkomendasikan).
///
/// Kriteria:
/// - jarak: makin dekat makin baik (dinormalisasi terhadap [jarakMaksKm]).
/// - fasilitas: makin lengkap fasilitasnya (relatif terhadap ATM terlengkap di antara kandidat) makin baik.
/// - keramaian: makin sepi makin baik. ATM tanpa data keramaian diberi skor netral (0.5),
///   supaya tidak dirugikan atau diuntungkan hanya karena belum ada yang lapor.
double computeAtmScore({
  required double jarakKm,
  required double jarakMaksKm,
  required int jumlahFasilitas,
  required int jumlahFasilitasMaks,
  CrowdLevel? crowdLevel,
  ScoringWeights weights = const ScoringWeights(),
}) {
  final skorJarak = jarakMaksKm <= 0
      ? 1.0
      : (1 - (jarakKm / jarakMaksKm)).clamp(0.0, 1.0);

  final skorFasilitas = jumlahFasilitasMaks <= 0
      ? 1.0
      : (jumlahFasilitas / jumlahFasilitasMaks).clamp(0.0, 1.0);

  final skorKeramaian = crowdLevel == null
      ? 0.5
      : (1 - (crowdLevel.score / 3)).clamp(0.0, 1.0);

  return (skorJarak * weights.jarak) +
      (skorFasilitas * weights.fasilitas) +
      (skorKeramaian * weights.keramaian);
}
