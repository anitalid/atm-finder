<<<<<<< HEAD
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' hide Haversine;
import 'package:url_launcher/url_launcher.dart';

=======
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Haversine;
import 'package:url_launcher/url_launcher.dart';
>>>>>>> da524fe57b48710086cc844bba328a8386fe1bd5
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/atm.dart';
import '../services/atm_service.dart';
import '../widgets/bank_logo.dart';
import '../widgets/primary_button.dart';

<<<<<<< HEAD
class RouteScreen extends StatefulWidget {
  final Atm atm;
  final LatLng user;
  final double jarakKm;

  const RouteScreen({
    super.key,
    required this.atm,
    required this.user,
    required this.jarakKm,
  });

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final MapController _mapController = MapController();

  List<LatLng> _routePoints = [];

  double? _routeDistanceKm;
  double? _routeDurationMinutes;

  bool _loadingRoute = true;
  String? _routeError;

  // Mode transportasi yang dipilih
  String _transportMode = 'Mobil';

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ============================================================
  // AMBIL RUTE DARI OSRM
  // ============================================================

  Future<void> _loadRoute() async {
    if (!mounted) return;

    setState(() {
      _loadingRoute = true;
      _routeError = null;
      _routePoints = [];
    });

    try {
      final start =
          '${widget.user.longitude},${widget.user.latitude}';

      final destination =
          '${widget.atm.longitude},${widget.atm.latitude}';

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '$start;$destination'
        '?overview=full'
        '&geometries=geojson'
        '&steps=true',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 20),
          );

      if (response.statusCode != 200) {
        throw Exception(
          'Server routing mengembalikan status '
          '${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);

      if (data['code'] != 'Ok') {
        throw Exception(
          data['message'] ??
              'Rute tidak ditemukan',
        );
      }

      final routes = data['routes'];

      if (routes == null || routes.isEmpty) {
        throw Exception(
          'Tidak ditemukan rute jalan menuju ATM.',
        );
      }

      final route = routes[0];

      final geometry = route['geometry'];
      final coordinates = geometry['coordinates'];

      final List<LatLng> points = [];

      for (final coordinate in coordinates) {
        if (coordinate is List &&
            coordinate.length >= 2) {
          final longitude =
              (coordinate[0] as num).toDouble();

          final latitude =
              (coordinate[1] as num).toDouble();

          points.add(
            LatLng(
              latitude,
              longitude,
            ),
          );
        }
      }

      if (points.length < 2) {
        throw Exception(
          'Data jalur dari server tidak valid.',
        );
      }

      final distanceMeters =
          (route['distance'] as num).toDouble();

      final durationSeconds =
          (route['duration'] as num).toDouble();

      if (!mounted) return;

      setState(() {
        _routePoints = points;

        _routeDistanceKm =
            distanceMeters / 1000;

        _routeDurationMinutes =
            durationSeconds / 60;

        _loadingRoute = false;
      });

      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (!mounted ||
            _routePoints.isEmpty) {
          return;
        }

        _fitRoute();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingRoute = false;
        _routeError = e.toString();
      });
    }
  }

  // ============================================================
  // FIT MAP
  // ============================================================

  void _fitRoute() {
    if (_routePoints.length < 2) return;

    double minLat =
        _routePoints.first.latitude;

    double maxLat =
        _routePoints.first.latitude;

    double minLng =
        _routePoints.first.longitude;

    double maxLng =
        _routePoints.first.longitude;

    for (final point in _routePoints) {
      minLat =
          min(minLat, point.latitude);

      maxLat =
          max(maxLat, point.latitude);

      minLng =
          min(minLng, point.longitude);

      maxLng =
          max(maxLng, point.longitude);
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(
            40,
            40,
            40,
            330,
          ),
          maxZoom: 17,
        ),
      );
    } catch (_) {}
  }

  // ============================================================
  // GOOGLE MAPS
  // ============================================================

  Future<void> _mulaiNavigasi() async {
    String travelMode = 'driving';

    if (_transportMode == 'Motor') {
      travelMode = 'two-wheeler';
    } else if (_transportMode == 'Jalan Kaki') {
      travelMode = 'walking';
    }

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${widget.user.latitude},${widget.user.longitude}'
      '&destination=${widget.atm.latitude},${widget.atm.longitude}'
      '&travelmode=$travelMode',
    );

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  // ============================================================
  // JARAK
  // ============================================================

  double get _distanceKm {
    return _routeDistanceKm ??
        widget.jarakKm;
  }

  String get _displayDistance {
    return AtmService.formatKm(
      _distanceKm,
    );
  }

  // ============================================================
  // WAKTU
  // ============================================================

  int get _estimatedMinutes {
    final distance = _distanceKm;

    if (_transportMode == 'Mobil') {
      if (_routeDurationMinutes != null) {
        return max(
          1,
          _routeDurationMinutes!.round(),
        );
      }

      return max(
        1,
        (distance / 25 * 60).round(),
      );
    }

    if (_transportMode == 'Motor') {
      return max(
        1,
        (distance / 30 * 60).round(),
      );
    }

    // Jalan kaki ±5 km/jam
    return max(
      1,
      (distance / 5 * 60).round(),
    );
  }

  String get _displayDuration {
    return '$_estimatedMinutes menit';
  }

  // ============================================================
  // BIAYA TRANSPORTASI
  // ============================================================

  int get _transportCost {
    final distance = _distanceKm;

    if (_transportMode == 'Mobil') {
      // Perkiraan Rp2.500/km
      return (distance * 2500).round();
    }

    if (_transportMode == 'Motor') {
      // Perkiraan Rp1.000/km
      return (distance * 1000).round();
    }

    // Jalan kaki gratis
    return 0;
  }

  String get _displayCost {
    if (_transportCost == 0) {
      return 'Gratis';
    }

    return 'Rp ${_formatRupiah(_transportCost)}';
  }

  String _formatRupiah(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 &&
          (text.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(text[i]);
    }

    return buffer.toString();
  }

  // ============================================================
  // GANTI MODE TRANSPORTASI
  // ============================================================

  void _changeTransportMode(String mode) {
    setState(() {
      _transportMode = mode;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final center = LatLng(
      (widget.user.latitude +
              widget.atm.latitude) /
          2,
      (widget.user.longitude +
              widget.atm.longitude) /
          2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rute ke Lokasi',
        ),
      ),
      body: Stack(
        children: [
          // ======================================================
          // MAP
          // ======================================================

          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    AppConstants.mapTilerStreetsUrl,
                userAgentPackageName:
                    'com.example.atm_finder',
              ),

              // ==================================================
              // RUTE
              // ==================================================

              if (_routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 6,
                      color:
                          AppColors.primary,
                      borderStrokeWidth: 2,
                      borderColor:
                          Colors.white,
                    ),
                  ],
                ),

              // ==================================================
              // MARKER
              // ==================================================

              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.user,
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.primary,
                        shape:
                            BoxShape.circle,
                        border:
                            Border.all(
                          color:
                              Colors.white,
                          width: 3,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color:
                                Colors.black26,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Marker(
                    point:
                        widget.atm.latLng,
                    width: 42,
                    height: 42,
                    child: const Icon(
                      Icons
                          .location_on_rounded,
                      color:
                          AppColors.primary,
                      size: 40,
                    ),
                  ),
                ],
              ),

              // ==================================================
              // ATTRIBUTION
              // ==================================================

              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'MapTiler',
                  ),
                  TextSourceAttribution(
                    'OpenStreetMap',
                  ),
                ],
              ),
            ],
          ),

          // ======================================================
          // LOADING
          // ======================================================

          if (_loadingRoute)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.white
                      .withOpacity(0.45),
                  child: const Center(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding:
                            EdgeInsets
                                .symmetric(
                          horizontal: 22,
                          vertical: 18,
                        ),
                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(width: 14),
                            Text(
                              'Menghitung rute...',
                              style:
                                  TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ======================================================
          // ERROR
          // ======================================================

          if (!_loadingRoute &&
              _routeError != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 3,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    14,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Icon(
                        Icons
                            .warning_amber_rounded,
                        color:
                            Colors.orange,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Text(
                              'Rute tidak dapat dihitung',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              _routeError!,
                              maxLines: 3,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 11,
                                color:
                                    AppColors
                                        .textGrey,
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            TextButton(
                              onPressed:
                                  _loadRoute,
                              child:
                                  const Text(
                                'Coba Lagi',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ======================================================
          // PANEL BAWAH
          // ======================================================

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding:
                  const EdgeInsets.all(16),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.08),
                    blurRadius: 12,
                    offset:
                        const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  // =================================================
                  // INFO ATM
                  // =================================================

                  Row(
                    children: [
                      BankLogo(
                        bank:
                            widget.atm.bank,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              widget.atm.nama,
                              style:
                                  const TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight
                                        .w700,
                                color:
                                    AppColors
                                        .textDark,
                              ),
                            ),
                            Text(
                              widget.atm.alamat,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 11,
                                color:
                                    AppColors
                                        .textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // =================================================
                  // PILIH TRANSPORTASI
                  // =================================================

                  Align(
                    alignment:
                        Alignment.centerLeft,
                    child: const Text(
                      'Transportasi',
                      style:
                          TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            AppColors
                                .textDark,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child:
                            _transportButton(
                          icon: Icons
                              .directions_car_rounded,
                          label: 'Mobil',
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child:
                            _transportButton(
                          icon: Icons
                              .two_wheeler_rounded,
                          label: 'Motor',
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child:
                            _transportButton(
                          icon: Icons
                              .directions_walk_rounded,
                          label:
                              'Jalan Kaki',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // =================================================
                  // JARAK / WAKTU / BIAYA
                  // =================================================

                  Row(
                    children: [
                      Expanded(
                        child: _stat(
                          _displayDistance,
                          'Jarak',
                        ),
                      ),

                      Container(
                        width: 1,
                        height: 42,
                        color:
                            AppColors
                                .border,
                      ),

                      Expanded(
                        child: _stat(
                          _displayDuration,
                          'Waktu',
                        ),
                      ),

                      Container(
                        width: 1,
                        height: 42,
                        color:
                            AppColors
                                .border,
                      ),

                      Expanded(
                        child: _stat(
                          _displayCost,
                          'Perkiraan Biaya',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  const Text(
                    'Biaya merupakan estimasi dan dapat berbeda '
                    'tergantung kendaraan, harga BBM, dan kondisi perjalanan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color:
                          AppColors.textGrey,
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // =================================================
                  // BUTTON
                  // =================================================

                  PrimaryButton(
                    label:
                        'Mulai Navigasi',
                    onPressed:
                        _mulaiNavigasi,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUTTON TRANSPORTASI
  // ============================================================

  Widget _transportButton({
    required IconData icon,
    required String label,
  }) {
    final selected =
        _transportMode == label;

    return GestureDetector(
      onTap: () =>
          _changeTransportMode(label),
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 4,
        ),
        decoration:
            BoxDecoration(
          color: selected
              ? AppColors.primary
              : Colors.grey.shade100,
          borderRadius:
              BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? Colors.white
                  : AppColors.textGrey,
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    FontWeight.w600,
                color: selected
                    ? Colors.white
                    : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STAT
  // ============================================================

  Widget _stat(
    String value,
    String label,
  ) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight:
                FontWeight.w800,
            color:
                AppColors.textDark,
          ),
        ),
        const SizedBox(
          height: 3,
        ),
        Text(
          label,
          textAlign:
              TextAlign.center,
          style: const TextStyle(
            fontSize: 9,
            color:
                AppColors.textGrey,
          ),
        ),
      ],
    );
  }
=======
class RouteScreen extends StatelessWidget {
  final Atm atm;
  final LatLng user;
  final double jarakKm;
  const RouteScreen({super.key, required this.atm, required this.user, required this.jarakKm});

  int get _menit => max(1, (jarakKm / 20 * 60).round());

  Future<void> _mulaiNavigasi() => launchUrl(Uri.parse(
    'https://www.google.com/maps/dir/?api=1&origin=${user.latitude},${user.longitude}'
    '&destination=${atm.latitude},${atm.longitude}&travelmode=driving'),
    mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final center = LatLng((user.latitude + atm.latitude) / 2, (user.longitude + atm.longitude) / 2);
    return Scaffold(appBar: AppBar(title: const Text('Rute ke Lokasi')),
      body: Stack(children: [
        FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 15),
          children: [
            TileLayer(
              urlTemplate: AppConstants.mapTilerStreetsUrl,
              userAgentPackageName: 'com.example.atm_finder'),
            PolylineLayer(polylines: [Polyline(points: [user, atm.latLng], strokeWidth: 4, color: AppColors.primary)]),
            MarkerLayer(markers: [
              Marker(point: user, width: 18, height: 18, child: Container(
                decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)))), // FIXED: Hapus const
              Marker(point: atm.latLng, width: 38, height: 38,
                child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 36)),
            ]),
          ]),
        Positioned(left: 16, right: 16, bottom: 16, child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              BankLogo(bank: atm.bank),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(atm.nama, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                Text(atm.alamat, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
              ])),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _stat(AtmService.formatKm(jarakKm), 'Jarak')),
              Container(width: 1, height: 34, color: AppColors.border),
              Expanded(child: _stat('$_menit menit', 'Estimasi Waktu')),
            ]),
            const SizedBox(height: 14),
            PrimaryButton(label: 'Mulai Navigasi', onPressed: _mulaiNavigasi),
          ]))),
      ]));
  }

  Widget _stat(String v, String l) => Column(children: [
    Text(v, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
    const SizedBox(height: 2),
    Text(l, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
  ]);
>>>>>>> da524fe57b48710086cc844bba328a8386fe1bd5
}