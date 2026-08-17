import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Haversine; // FIXED: hide Haversine
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/atm.dart';
import '../models/crowd_report.dart';
import '../services/atm_service.dart';
import '../services/crowd_service.dart';
import '../utils/haversine.dart';
import '../widgets/bank_logo.dart';
import '../widgets/crowd_badge.dart';
import '../widgets/primary_button.dart';
import 'route_screen.dart';

class DetailScreen extends StatefulWidget {
  final Atm atm;
  final LatLng user;
  const DetailScreen({super.key, required this.atm, required this.user});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _crowdService = CrowdService();
  late Future<CrowdLevel?> _crowdFuture;
  late Future<String?> _peakHourFuture;
  bool _submitting = false;

  Atm get atm => widget.atm;
  LatLng get user => widget.user;

  @override
  void initState() {
    super.initState();
    _crowdFuture = _crowdService.getCurrentCrowdLevel(atm.id);
    _peakHourFuture = _crowdService.getPeakHourSummary(atm.id);
  }

  Future<void> _refreshCrowd() {
    final future = _crowdService.getCurrentCrowdLevel(atm.id);
    setState(() { _crowdFuture = future; });
    return future;
  }

  Future<void> _reportCrowd() async {
    final selected = await showModalBottomSheet<CrowdLevel>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Seberapa ramai ATM ini sekarang?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 16),
            ...CrowdLevel.values.map((lvl) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(width: 12, height: 12,
                decoration: BoxDecoration(color: CrowdBadge.colorFor(lvl), shape: BoxShape.circle)),
              title: Text(lvl.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, lvl),
            )),
          ]),
        ),
      ),
    );
    if (selected == null) return;
    setState(() => _submitting = true);
    try {
      await _crowdService.submitReport(atm.id, selected);
      await _refreshCrowd();
      setState(() { _peakHourFuture = _crowdService.getPeakHourSummary(atm.id); });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terima kasih, laporan keramaian terkirim.')));
      }
    } catch (e) {
      debugPrint('CrowdReport error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim laporan, coba lagi.')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final km = Haversine.distanceKm(user.latitude, user.longitude, atm.latitude, atm.longitude);
    return Scaffold(appBar: AppBar(title: const Text('Detail ATM')),
      body: Column(children: [
        SizedBox(height: 220, child: FlutterMap(
          options: MapOptions(initialCenter: atm.latLng, initialZoom: 16,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
          children: [
            TileLayer(
              urlTemplate: AppConstants.mapTilerStreetsUrl,
              userAgentPackageName: 'com.example.atm_finder'),
            MarkerLayer(markers: [Marker(point: atm.latLng, width: 40, height: 40,
              child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 38))]),
          ])),
        Expanded(child: Container(width: double.infinity,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(atm.nama, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark))),
              BankLogo(bank: atm.bank),
            ]),
            const SizedBox(height: 16),
            _info(Icons.place_outlined, 'Alamat', atm.alamat),
            _info(Icons.near_me_rounded, 'Jarak', '${AtmService.formatKm(km)} dari lokasi Anda'),
            _info(Icons.access_time_rounded, 'Jam Operasional', atm.jamOperasional),
            const SizedBox(height: 12),
            const Text('Fasilitas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: atm.fasilitas.map((f) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
              child: Text(f, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)))).toList()),
            const SizedBox(height: 16),
            Row(children: [
              const Text('Keramaian Saat Ini', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const Spacer(),
              TextButton.icon(
                onPressed: _submitting ? null : _reportCrowd,
                icon: const Icon(Icons.campaign_outlined, size: 16),
                label: const Text('Lapor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 4),
            FutureBuilder<CrowdLevel?>(
              future: _crowdFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 24, width: 24,
                    child: Padding(padding: EdgeInsets.all(2), child: CircularProgressIndicator(strokeWidth: 2)));
                }
                return CrowdBadge(level: snap.data);
              },
            ),
            FutureBuilder<String?>(
              future: _peakHourFuture,
              builder: (context, snap) {
                final summary = snap.data;
                if (snap.connectionState == ConnectionState.waiting || summary == null) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    const Icon(Icons.insights_rounded, size: 14, color: AppColors.textGrey),
                    const SizedBox(width: 6),
                    Text(summary, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                  ]),
                );
              },
            ),
            const Spacer(),
            PrimaryButton(label: 'Rute', onPressed: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => RouteScreen(atm: atm, user: user, jarakKm: km)))),
            const SizedBox(height: 8),
          ]))),
      ]));
  }

  Widget _info(IconData icon, String title, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: AppColors.textGrey),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      ])),
    ]));
}