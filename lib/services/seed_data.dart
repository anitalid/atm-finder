/// Data awal ATM Kota Yogyakarta (koordinat perkiraan).
/// Otomatis di-seed ke Firestore jika koleksi `atms` kosong.
final List<Map<String, dynamic>> seedAtmList = [
  {'nama': 'ATM BCA Malioboro', 'bank': 'BCA', 'alamat': 'Jl. Malioboro No. 52, Yogyakarta', 'latitude': -7.79787, 'longitude': 110.36725, 'fasilitas': ['Tarik Tunai', 'Setor Tunai', 'Cek Saldo', '24 Jam'], 'jamOperasional': '24 Jam'},
  {'nama': 'ATM Mandiri Tugu', 'bank': 'Mandiri', 'alamat': 'Jl. Mangkubumi No. 11, Yogyakarta', 'latitude': -7.79260, 'longitude': 110.36720, 'fasilitas': ['Tarik Tunai', 'Cek Saldo', '24 Jam'], 'jamOperasional': '24 Jam'},
  {'nama': 'ATM BNI Sudirman', 'bank': 'BNI', 'alamat': 'Jl. Jend. Sudirman No. 8, Yogyakarta', 'latitude': -7.78272, 'longitude': 110.36863, 'fasilitas': ['Tarik Tunai', 'Setor Tunai', 'Cek Saldo'], 'jamOperasional': '07.00 - 22.00'},
  {'nama': 'ATM BRI UGM', 'bank': 'BRI', 'alamat': 'Jl. C. Simanjuntak No. 1, Yogyakarta', 'latitude': -7.77013, 'longitude': 110.36571, 'fasilitas': ['Tarik Tunai', 'Setor Tunai', 'Cek Saldo', '24 Jam'], 'jamOperasional': '24 Jam'},
  {'nama': 'ATM BCA Kotabaru', 'bank': 'BCA', 'alamat': 'Jl. Cik Di Tiro No. 30, Yogyakarta', 'latitude': -7.78620, 'longitude': 110.37130, 'fasilitas': ['Tarik Tunai', 'Cek Saldo'], 'jamOperasional': '08.00 - 15.00'},
  {'nama': 'ATM Mandiri Galeria', 'bank': 'Mandiri', 'alamat': 'Mall Galeria, Jl. Jend. Sudirman, Yogyakarta', 'latitude': -7.78459, 'longitude': 110.37227, 'fasilitas': ['Tarik Tunai', 'Setor Tunai', 'Cek Saldo', '24 Jam'], 'jamOperasional': '24 Jam'},
  {'nama': 'ATM BNI Alun-Alun Kidul', 'bank': 'BNI', 'alamat': 'Jl. Alun-Alun Kidul No. 2, Yogyakarta', 'latitude': -7.80872, 'longitude': 110.36491, 'fasilitas': ['Tarik Tunai', 'Cek Saldo'], 'jamOperasional': '07.00 - 22.00'},
  {'nama': 'ATM BSI Ahmad Dahlan', 'bank': 'BSI', 'alamat': 'Jl. Ahmad Dahlan No. 128, Yogyakarta', 'latitude': -7.80294, 'longitude': 110.35527, 'fasilitas': ['Tarik Tunai', 'Setor Tunai', 'Cek Saldo'], 'jamOperasional': '08.00 - 15.00'},
  {'nama': 'ATM BRI Prawirotaman', 'bank': 'BRI', 'alamat': 'Jl. Parangtritis No. 25, Yogyakarta', 'latitude': -7.81210, 'longitude': 110.36350, 'fasilitas': ['Tarik Tunai', 'Cek Saldo', '24 Jam'], 'jamOperasional': '24 Jam'},
  {'nama': 'ATM BCA Stasiun Tugu', 'bank': 'BCA', 'alamat': 'Jl. Pasar Kembang, Yogyakarta', 'latitude': -7.78996, 'longitude': 110.36261, 'fasilitas': ['Tarik Tunai', 'Setor Tunai', 'Cek Saldo', '24 Jam'], 'jamOperasional': '24 Jam'},
];