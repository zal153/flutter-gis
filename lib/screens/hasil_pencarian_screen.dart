import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../models/posyandu_model.dart';
import '../algorithms/haversine.dart';
import 'rute_screen.dart';

class HasilPencarianScreen extends StatefulWidget {
  final List<PosyanduModel> posyanduList;
  final Position currentPosition;

  const HasilPencarianScreen({
    super.key,
    required this.posyanduList,
    required this.currentPosition,
  });

  @override
  State<HasilPencarianScreen> createState() => _HasilPencarianScreenState();
}

class _HasilPencarianScreenState extends State<HasilPencarianScreen> {
  final MapController _mapController = MapController();
  bool _isMapReady = false;

  // Tampilkan 5 terdekat di peta
  List<PosyanduModel> get _topList => widget.posyanduList.take(5).toList();

  @override
  void initState() {
    super.initState();
  }

  void _centerOnClosest() {
    if (_isMapReady && widget.posyanduList.isNotEmpty) {
      _mapController.move(
        LatLng(
          widget.posyanduList.first.latitude,
          widget.posyanduList.first.longitude,
        ),
        14.5,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = screenHeight * 0.42; // ~42% layar untuk peta

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── BAGIAN ATAS: PETA (sesuai mockup 3.13) ─────────────────────
          SizedBox(
            height: mapHeight,
            child: Stack(
              children: [
                // Peta OSM
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      widget.currentPosition.latitude,
                      widget.currentPosition.longitude,
                    ),
                    initialZoom: 14.0,
                    onMapReady: () {
                      setState(() {
                        _isMapReady = true;
                      });
                      _centerOnClosest();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.posyandu_locator',
                    ),

                    // Marker posyandu terdekat dengan label A, B, C dst
                    MarkerLayer(
                      markers: [
                        // Marker user
                        Marker(
                          point: LatLng(
                            widget.currentPosition.latitude,
                            widget.currentPosition.longitude,
                          ),
                          width: 36,
                          height: 36,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_pin_circle_rounded,
                              color: Colors.blue,
                              size: 32,
                            ),
                          ),
                        ),

                        // Marker posyandu dengan nomor posyandu (misal: "33", "15 A")
                        ..._topList.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final p = entry.value;
                          
                          // Ekstrak nomor posyandu dari namanya (misal "Manggis 33" -> "33")
                          final numberMatch = RegExp(r'\d+\s*[A-Za-z]*').stringMatch(p.namaPosyandu);
                          final label = (numberMatch != null && numberMatch.trim().isNotEmpty)
                              ? numberMatch.trim()
                              : p.namaPosyandu;

                          // Warna berbeda: terdekat merah, lainnya hijau
                          final color =
                              idx == 0 ? AppTheme.error : AppTheme.primary;

                          return Marker(
                            point: LatLng(p.latitude, p.longitude),
                            width: 36,
                            height: 44,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RuteScreen(
                                      posyandu: p,
                                      currentPosition: widget.currentPosition,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  // Pin marker
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: label.length > 2 ? 9 : 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Segitiga penunjuk
                                  CustomPaint(
                                    size: const Size(10, 7),
                                    painter: _PinTriangle(color: color),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),

                // Tombol back di atas peta
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
              ],
            ),
          ),

          // ── BAGIAN BAWAH: PANEL HASIL PENCARIAN (sesuai mockup 3.13) ───
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header panel "Hasil Pencarian"
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppTheme.divider, width: 1),
                      ),
                    ),
                    child: Text(
                      'Hasil Pencarian',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),

                  // Daftar posyandu
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _topList.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: AppTheme.divider,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final p = _topList[index];
                        return _buildListItem(p, index).animate().fadeIn(
                              duration: 250.ms,
                              delay: Duration(milliseconds: 40 * index),
                            );
                      },
                    ),
                  ),

                  // Footer teks sesuai mockup 3.13
                  Container(
                    width: double.infinity,
                    color: Colors.grey.shade50,
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: MediaQuery.of(context).padding.bottom + 8,
                    ),
                    child: Text(
                      'Hasil ini ditampilkan berdasarkan lokasi pengguna saat ini',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Item list sesuai mockup 3.13:
  // [ikon rumah sakit] [Nama Posyandu]   [Jarak x km] [tombol arah]
  Widget _buildListItem(PosyanduModel p, int index) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RuteScreen(
            posyandu: p,
            currentPosition: widget.currentPosition,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Ikon rumah sakit/posyandu sesuai mockup
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            // Nama posyandu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.namaLengkap,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Desa ${p.desa}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Jarak sesuai mockup
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  HaversineAlgorithm.formatJarak(p.jarak ?? 0),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                // Tombol arah bulat sesuai mockup 3.13
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Segitiga pin marker peta
class _PinTriangle extends CustomPainter {
  final Color color;
  const _PinTriangle({required this.color});

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
