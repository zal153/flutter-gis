import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';
import '../models/posyandu_model.dart';
import '../algorithms/haversine.dart';
import '../core/api_service.dart';

class RuteScreen extends StatefulWidget {
  final PosyanduModel posyandu;
  final Position currentPosition;

  const RuteScreen({
    super.key,
    required this.posyandu,
    required this.currentPosition,
  });

  @override
  State<RuteScreen> createState() => _RuteScreenState();
}

class _RuteScreenState extends State<RuteScreen> {
  final MapController _mapController = MapController();
  List<RouteModel> _routes = [];
  int _selectedRouteIndex = 0;
  bool _isLoadingRute = true;
  bool _isSatellite = false;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _hitungRute();
  }

  Future<void> _hitungRute() async {
    setState(() => _isLoadingRute = true);

    try {
      List<RouteModel> fetchedRoutes = await ApiService.fetchRoute(
        widget.currentPosition.latitude,
        widget.currentPosition.longitude,
        widget.posyandu.latitude,
        widget.posyandu.longitude,
      );

      if (fetchedRoutes.isEmpty) {
        fetchedRoutes = [
          RouteModel(
            path: [
              LatLng(widget.currentPosition.latitude, widget.currentPosition.longitude),
              LatLng(widget.posyandu.latitude, widget.posyandu.longitude),
            ],
            distance: widget.posyandu.jarak ?? 0.0,
          )
        ];
      }

      setState(() {
        _routes = fetchedRoutes;
        _selectedRouteIndex = 0;
        _isLoadingRute = false;
      });

      _fitRouteBounds();
    } catch (e) {
      setState(() => _isLoadingRute = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _fitRouteBounds() {
    if (!_isMapReady || _routes.isEmpty) return;
    final allPoints = _routes.expand((r) => r.path).toList();
    if (allPoints.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(allPoints);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(50, 100, 50, 220),
        ),
      );
    }
  }

  double get _selectedDistance {
    if (_routes.isEmpty) return widget.posyandu.jarak ?? 0.0;
    return _routes[_selectedRouteIndex].distance;
  }

  String get _estimasiWaktu =>
      HaversineAlgorithm.estimasiWaktu(_selectedDistance);

  String get _waktuTiba =>
      HaversineAlgorithm.estimasiWaktuTiba(_selectedDistance);

  String get _jarakFormatted =>
      HaversineAlgorithm.formatJarak(_selectedDistance);

  List<Polyline> _buildPolylinesForRoute(RouteModel route, bool isActive) {
    final color = isActive ? AppTheme.primary : Colors.grey.withValues(alpha: 0.7);
    final strokeWidth = isActive ? 5.5 : 4.5;
    final borderColor = isActive ? Colors.white : Colors.white.withValues(alpha: 0.5);
    final borderStrokeWidth = isActive ? 1.5 : 1.0;

    final road = route.roadPath;
    // Jika tidak ada roadPath, gunakan path penuh sebagai solid
    if (road == null || road.length < 2) {
      return [
        Polyline(
          points: route.path,
          color: color,
          strokeWidth: strokeWidth,
          borderColor: borderColor,
          borderStrokeWidth: borderStrokeWidth,
        ),
      ];
    }

    final fullPath = route.path;
    final polylines = <Polyline>[];

    // fullPath = [startPoint, ...roadNodes..., endPoint]
    // roadNodes dimulai dari index 1, berakhir di index fullPath.length - 2

    // 1. Garis putus-putus: Titik Awal → Node jalan pertama
    polylines.add(
      Polyline(
        points: [fullPath.first, road.first],
        color: color,
        strokeWidth: strokeWidth * 0.8,
        borderColor: borderColor,
        borderStrokeWidth: borderStrokeWidth,
        pattern: StrokePattern.dashed(segments: const [8, 8]),
      ),
    );

    // 2. Garis solid: Sepanjang jalan raya (road nodes)
    polylines.add(
      Polyline(
        points: road,
        color: color,
        strokeWidth: strokeWidth,
        borderColor: borderColor,
        borderStrokeWidth: borderStrokeWidth,
      ),
    );

    // 3. Garis putus-putus: Node jalan terakhir → Posyandu
    polylines.add(
      Polyline(
        points: [road.last, fullPath.last],
        color: color,
        strokeWidth: strokeWidth * 0.8,
        borderColor: borderColor,
        borderStrokeWidth: borderStrokeWidth,
        pattern: StrokePattern.dashed(segments: const [8, 8]),
      ),
    );

    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── PETA PENUH (sesuai mockup 3.14) ─────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                (widget.currentPosition.latitude + widget.posyandu.latitude) /
                    2,
                (widget.currentPosition.longitude + widget.posyandu.longitude) /
                    2,
              ),
              initialZoom: 14,
              minZoom: 10,
              maxZoom: 18,
              onMapReady: () {
                setState(() {
                  _isMapReady = true;
                });
                _fitRouteBounds();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _isSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.posyandu_locator',
                maxZoom: 18,
              ),

              // Garis rute Dijkstra (Rute Utama & Rute Alternatif)
              if (_routes.isNotEmpty && !_isLoadingRute)
                PolylineLayer(
                  polylines: [
                    // Gambar rute non-aktif/alternatif di bawah
                    ..._routes.asMap().entries.where((entry) => entry.key != _selectedRouteIndex).expand((entry) {
                      return _buildPolylinesForRoute(entry.value, false);
                    }),
                    // Gambar rute aktif/terpilih di atas
                    ..._buildPolylinesForRoute(_routes[_selectedRouteIndex], true),
                  ],
                ),

              // Marker
              MarkerLayer(
                markers: [
                  // Marker user — ikon orang sesuai mockup 3.14
                  Marker(
                    point: LatLng(
                      widget.currentPosition.latitude,
                      widget.currentPosition.longitude,
                    ),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_pin_circle_rounded,
                        color: Colors.blue,
                        size: 36,
                      ),
                    ),
                  ),

                  // Marker posyandu tujuan — ikon lokasi merah
                  Marker(
                    point: LatLng(
                      widget.posyandu.latitude,
                      widget.posyandu.longitude,
                    ),
                    width: 40,
                    height: 50,
                    child: Column(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.error.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const CustomPaint(
                          size: Size(10, 7),
                          painter: _TriPainter(color: AppTheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Loading Dijkstra overlay ──────────────────────────────────────
          if (_isLoadingRute)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.2),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Menghitung Rute...',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Algoritma Dijkstra',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Tombol back ──────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),

          // ── Tombol toggle Satelit/Peta ─────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: GestureDetector(
              onTap: () => setState(() => _isSatellite = !_isSatellite),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isSatellite ? Icons.map_rounded : Icons.satellite_alt_rounded,
                      size: 16,
                      color: AppTheme.textPrimary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isSatellite ? 'Peta' : 'Satelit',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── SELECTOR RUTE ALTERNATIF (Pills) ─────────────────────────────
          if (!_isLoadingRute && _routes.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 96,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: _routes.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedRouteIndex;
                      final route = _routes[index];
                      final distText = HaversineAlgorithm.formatJarak(route.distance);
                      final label = index == 0 ? 'Rute Tercepat' : 'Alternatif $index';
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRouteIndex = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : Colors.grey.shade300,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.directions_car_filled_outlined,
                                  size: 14,
                                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$label ($distText)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ).animate().slideY(
                    begin: 0.5,
                    duration: 350.ms,
                    delay: 200.ms,
                    curve: Curves.easeOut,
                  ),
            ),

          // ── PANEL BAWAH KECIL sesuai mockup 3.14 ─────────────────────────
          // "Jarak : 1 km"  "Estimasi Tiba : 3 menit"  [▲ Mulai]
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: 16,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Info jarak & estimasi (kiri) — sesuai mockup 3.14
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Jarak
                        Row(
                          children: [
                            Text(
                              'Jarak',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '  :  ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              _jarakFormatted,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Estimasi Perjalanan
                        Row(
                          children: [
                            Text(
                              'Estimasi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '  :  ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              _estimasiWaktu,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Jam Tiba
                        Row(
                          children: [
                            Text(
                              'Tiba',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '  :  ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              'Pukul $_waktuTiba',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Tombol DETAIL/INFO — ikon info
                  GestureDetector(
                    onTap: _showDetailPosyandu,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.info_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          Text(
                            'Info',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().slideY(
                  begin: 0.5,
                  duration: 350.ms,
                  delay: 300.ms,
                  curve: Curves.easeOut,
                ),
          ),
        ],
      ),
    );
  }

  void _showDetailPosyandu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final posyandu = widget.posyandu;
        final isAktif = (posyandu.status?.toLowerCase() ?? 'aktif') == 'aktif';

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            top: 12,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          posyandu.namaPosyandu,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Desa ${posyandu.desa} • ${posyandu.alamat ?? "Tidak ada detail alamat"}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isAktif
                          ? AppTheme.success.withValues(alpha: 0.15)
                          : AppTheme.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      posyandu.status ?? 'Aktif',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isAktif ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppTheme.divider),
              const SizedBox(height: 12),
              Text(
                'Informasi Pelayanan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                posyandu.keterangan ??
                    'Menyediakan pelayanan imunisasi dasar balita, pemantauan status gizi (penimbangan berat badan dan pengukuran tinggi badan balita), pemberian makanan tambahan (PMT), KB, serta kesehatan ibu dan anak.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jarak Tempuh',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _jarakFormatted,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: AppTheme.divider,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimasi Waktu',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _estimasiWaktu,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Tutup',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TriPainter extends CustomPainter {
  final Color color;
  const _TriPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
