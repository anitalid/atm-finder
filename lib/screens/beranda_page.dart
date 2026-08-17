import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Haversine;
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/atm.dart';
import '../models/filter.dart';
import '../services/atm_service.dart';
import '../services/history_service.dart';
import '../services/location_service.dart';
import '../widgets/bank_chips.dart';
import '../widgets/bank_logo.dart';
import '../widgets/primary_button.dart';
import 'detail_screen.dart';
import 'filter_screen.dart';
import 'results_screen.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});
  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final _atmService = AtmService();
  final _mapController = MapController();
  final _search = TextEditingController();
  LatLng? _user;
  List<Atm> _atms = [];
  AtmFilter _filter = const AtmFilter();
  bool _loading = true;

  bool _mapReady = false;
  bool _hasError = false;

  bool _navigating = false;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _search.dispose(); _mapController.dispose(); super.dispose(); }

  Future<void> _load({bool isRetry = false}) async {
    // PENTING: jangan setState() di sini kalau dipanggil dari initState()
    // secara langsung (tanpa await sebelumnya) — Flutter melarang setState()
    // synchronous sebelum widget selesai di-build pertama kali, dan karena
    // _load() dipanggil tanpa `await` di initState, exception dari situ jadi
    // silently gagal (gak ada data, gak ada pesan error sama sekali).
    // _loading & _hasError sudah punya default aman dari deklarasi field,
    // jadi setState di sini cuma perlu buat retry manual (dipanggil dari
    // tombol, bukan dari initState, jadi aman).
    if (isRetry) setState(() { _loading = true; _hasError = false; });
    try {
      final loc = await LocationService.getCurrentLocation();
      final atms = await _atmService.getCombinedAtms(user: loc, radiusMeter: 10000);
      if (!mounted) return;
      setState(() {
        _user = loc;
        _atms = atms;
        _loading = false;
        _hasError = false;
      });
      // DEBUG SEMENTARA — hapus lagi setelah masalah data kosong ketemu.
      // Nunjukin jumlah ATM yang berhasil kedapet, biar ketauan apakah
      // getCombinedAtms() beneran kosong (bukan exception yang ketutup).
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DEBUG: dapat ${atms.length} ATM (radius 10km)'),
            duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (!isRetry) {
        // Percobaan pertama gagal (misal Overpass API lagi timeout) —
        // coba sekali lagi otomatis sebelum nampilin pesan error ke user,
        // soalnya kegagalan sesaat kayak gini cukup sering terjadi.
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        return _load(isRetry: true);
      }
      setState(() {
        _loading = false;
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengambil data ATM: $e')));
    }
  }

  List<AtmResult> get _results {
    if (_user == null) return [];
    return _atmService.nearestNeighbor(atms: _atms, user: _user!, filter: _filter);
  }

  Future<void> _openResults() async {
    if (_user == null) return;
    if (_navigating) return; // sudah ada navigasi berjalan, abaikan tap/submit tambahan
    _navigating = true;
    try {
      if (_search.text.trim().isNotEmpty) {
        HistoryService().addHistory(_search.text.trim(), _filter.bank);
      }
      await Navigator.push(context, MaterialPageRoute(builder: (_) =>
        ResultsScreen(user: _user!, filter: _filter, query: _search.text)));
    } finally {
      // Reset setelah user kembali dari ResultsScreen, biar bisa search lagi.
      _navigating = false;
    }
  }

  Future<void> _openFilter() async {
    final r = await Navigator.push(context, MaterialPageRoute(builder: (_) => FilterScreen(initial: _filter)));
    if (r != null) setState(() => _filter = r as AtmFilter);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          Expanded(child: TextField(controller: _search, onSubmitted: (_) => _openResults(),
            onChanged: (v) {
              // Kalau ada Bank Chip yang lagi aktif dan user mulai ngetik query
              // sendiri, reset ke "Semua" — soalnya filter chip + search box
              // sebelumnya jalan pakai AND, jadi kombinasi "chip=BRI" +
              // "ketik BCA" selalu hasilnya kosong walau ATM BCA-nya ada.
              if (v.trim().isNotEmpty && _filter.bank != 'Semua') {
                setState(() => _filter = _filter.copyWith(bank: 'Semua'));
              }
            },
            decoration: const InputDecoration(hintText: 'Cari ATM atau lokasi...', prefixIcon: Icon(Icons.search, color: AppColors.textGrey), isDense: true))),
          const SizedBox(width: 8),
          IconButton(onPressed: _openFilter,
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            style: IconButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: AppColors.border))),
        ])),
      BankChips(banks: AppConstants.banks, selected: _filter.bank,
        onSelect: (b) => setState(() => _filter = _filter.copyWith(bank: b))),
      const SizedBox(height: 8),
      Expanded(child: Stack(children: [
        if (_loading || _user == null)
          if (_hasError)
            Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textGrey),
                const SizedBox(height: 12),
                const Text('Gagal memuat data ATM',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 4),
                const Text('Server peta sedang tidak bisa diakses, atau koneksi internet bermasalah.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _load(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Coba Lagi'),
                ),
              ]),
            ))
          else
            const Center(child: CircularProgressIndicator())
        else
          FlutterMap(
             mapController: _mapController,
             options: MapOptions(
               initialCenter: _user!,
               initialZoom: 14,
               onMapReady: () {
                 if (mounted) setState(() => _mapReady = true);
               },
             ),
            children: [
          TileLayer(
              urlTemplate: AppConstants.mapTilerStreetsUrl,
              userAgentPackageName: 'com.example.atm_finder',
            ),
              CircleLayer(circles: [CircleMarker(point: _user!, radius: 120,
                color: AppColors.primary.withOpacity(0.12), borderColor: AppColors.primary.withOpacity(0.3), borderStrokeWidth: 1)]),
              MarkerLayer(markers: [
                Marker(point: _user!, width: 20, height: 20, child:
                  Container(decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3)))),
                ..._results.map((r) => Marker(point: r.atm.latLng, width: 36, height: 36, child:
                  GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => DetailScreen(atm: r.atm, user: _user!))),
                    child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 34)))),
              ]),
              RichAttributionWidget(
              attributions: [
                TextSourceAttribution('MapTiler',),
                TextSourceAttribution('OpenStreetMap',),
              ],
            ),
            ],
          ),
        Positioned(right: 16, bottom: 170, child: FloatingActionButton.small(
          backgroundColor: Colors.white, foregroundColor: AppColors.primary, elevation: 3,
          onPressed: () {
            if (_user != null && _mapReady) {
              _mapController.move(_user!, 15);
            }
          },
          child: const Icon(Icons.navigation_rounded))),
        if (!_loading && _results.isNotEmpty)
          Positioned(left: 16, right: 16, bottom: 16, child:
            Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                const Text('ATM Terdekat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textGrey)),
                const SizedBox(height: 8),
                Row(children: [
                  BankLogo(bank: _results.first.atm.bank),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_results.first.atm.nama, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    Text(_results.first.atm.alamat, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                  ])),
                  Text(AtmService.formatKm(_results.first.jarakKm),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ]),
                const SizedBox(height: 12),
                PrimaryButton(label: 'Lihat Semua', onPressed: _openResults),
              ]))),
      ])),
    ]));
  }
}