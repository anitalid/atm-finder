/*
 * Formatter untuk string opening_hours dari OpenStreetMap
 * (format resmi: https://wiki.openstreetmap.org/wiki/Key:opening_hours)
 *
 * OSM opening_hours punya spesifikasi yang sangat kompleks
 * (bisa ada exception, komentar dalam kutip, banyak grup
 * hari/jam dipisah koma-titik-koma, dsb). Formatter ini
 * SENGAJA hanya menangani pola paling umum yang biasa
 * dijumpai pada data ATM/bank di Indonesia:
 *
 * - "24/7"                        -> Buka 24 Jam
 * - "Mo-Su 00:00-24:00"           -> Buka 24 Jam
 * - "Mo-Su,PH 00:00+"             -> Buka 24 Jam
 * - "Mo-Fr 08:00-17:00"           -> Senin-Jumat, 08:00-17:00
 * - "Mo-Fr 08:00-17:00; Sa 08:00-13:00"
 *      -> Senin-Jumat, 08:00-17:00 / Sabtu, 08:00-13:00
 *
 * Kalau pola tidak dikenali, formatter mengembalikan string
 * asli apa adanya (fallback aman) daripada menampilkan hasil
 * yang salah.
 */
class OpeningHoursFormatter {
  static const Map<String, String> _dayNames = {
    'Mo': 'Senin',
    'Tu': 'Selasa',
    'We': 'Rabu',
    'Th': 'Kamis',
    'Fr': 'Jumat',
    'Sa': 'Sabtu',
    'Su': 'Minggu',
    'PH': 'Hari Libur',
  };

  static final RegExp _segmentPattern = RegExp(
    r'^([A-Za-z,\-]+)\s+(\d{2}:\d{2})-(\d{2}:\d{2})$',
  );

  static String format(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Jam operasional tidak tersedia';
    }

    final value = raw.trim();

    // ------------------------------------------------------
    // KASUS: BUKA 24 JAM
    // ------------------------------------------------------

    final normalized = value.toLowerCase();

    final is24Jam = normalized == '24/7' ||
        normalized.contains('00:00-24:00') ||
        normalized.endsWith('00:00+') ||
        normalized.contains('00:00+');

    if (is24Jam) {
      return 'Buka 24 Jam';
    }

    // ------------------------------------------------------
    // KASUS UMUM: "<hari> <jam_mulai>-<jam_selesai>"
    // bisa lebih dari satu, dipisah titik-koma (;)
    // ------------------------------------------------------

    try {
      final segments = value
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);

      final formattedParts = <String>[];
      var allRecognized = true;

      for (final segment in segments) {
        final match = _segmentPattern.firstMatch(segment);

        if (match == null) {
          allRecognized = false;
          break;
        }

        final daysRaw = match.group(1)!;
        final start = match.group(2)!;
        final end = match.group(3)!;

        final days = _formatDays(daysRaw);
        formattedParts.add('$days, $start-$end');
      }

      if (allRecognized && formattedParts.isNotEmpty) {
        return formattedParts.join(' / ');
      }
    } catch (_) {
      // abaikan, jatuh ke fallback di bawah
    }

    // ------------------------------------------------------
    // FALLBACK: pola tidak dikenali, tampilkan apa adanya
    // ------------------------------------------------------

    return value;
  }

  static String _formatDays(String raw) {
    // Range, misal "Mo-Fr"
    if (raw.contains('-') && !raw.contains(',')) {
      final range = raw.split('-');

      if (range.length == 2 &&
          _dayNames.containsKey(range[0]) &&
          _dayNames.containsKey(range[1])) {
        return '${_dayNames[range[0]]}-${_dayNames[range[1]]}';
      }
    }

    // List, misal "Mo,We,Fr" atau "Mo-Fr,PH"
    if (raw.contains(',')) {
      return raw
          .split(',')
          .map((d) {
            if (d.contains('-')) {
              final range = d.split('-');
              if (range.length == 2 &&
                  _dayNames.containsKey(range[0]) &&
                  _dayNames.containsKey(range[1])) {
                return '${_dayNames[range[0]]}-${_dayNames[range[1]]}';
              }
            }
            return _dayNames[d] ?? d;
          })
          .join(', ');
    }

    // Hari tunggal, misal "Sa"
    return _dayNames[raw] ?? raw;
  }
}