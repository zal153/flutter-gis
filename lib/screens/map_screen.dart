import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../algorithms/haversine.dart';
import '../models/posyandu_model.dart';
import '../core/api_service.dart';
import 'hasil_pencarian_screen.dart';
import 'rute_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _hasLocation = false;
  List<PosyanduModel> _posyanduList = [];
  bool _isSatellite = false;
  bool _showPosyandu = true;
  bool _isMapReady = false;
  LatLng? _pendingMapMove;

  // Aktifkan untuk testing lokasi pengguna acak di Kecamatan Arjasa.
  static const bool _useRandomArjasaLocationForTesting = true;

  // Default center Kecamatan Arjasa
  static const LatLng _defaultCenter = LatLng(-8.103, 113.736);

  // Bounding box kasar area Arjasa untuk simulasi lokasi pengguna.
  static const double _arjasaMinLat = -8.126;
  static const double _arjasaMaxLat = -8.088;
  static const double _arjasaMinLon = 113.696;
  static const double _arjasaMaxLon = 113.767;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _fetchPosyandu();
  }

  Future<void> _fetchPosyandu() async {
    try {
      final data = await ApiService.fetchPosyandus();
      setState(() {
        _posyanduList = data;
      });
    } catch (e) {
      if (mounted) _showSnackBar(e.toString(), isError: true);
    }
  }

  Future<void> _initLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      if (_useRandomArjasaLocationForTesting) {
        final position = _generateRandomArjasaPosition();

        setState(() {
          _currentPosition = position;
          _hasLocation = true;
          _isLoadingLocation = false;
        });

        if (_isMapReady) {
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            15.0,
          );
        } else {
          _pendingMapMove = LatLng(position.latitude, position.longitude);
        }

        _showSnackBar('Mode testing aktif: lokasi acak Arjasa digunakan');
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        _showSnackBar('Aktifkan layanan lokasi Anda', isError: true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          _showSnackBar('Izin lokasi ditolak', isError: true);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        _showSnackBar('Aktifkan izin lokasi di pengaturan', isError: true);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = position;
        _hasLocation = true;
        _isLoadingLocation = false;
      });

      if (_isMapReady) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15.0,
        );
      } else {
        _pendingMapMove = LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  Position _generateRandomArjasaPosition() {
    final random = Random();
    final latitude =
        _arjasaMinLat + ((_arjasaMaxLat - _arjasaMinLat) * random.nextDouble());
    final longitude =
        _arjasaMinLon + ((_arjasaMaxLon - _arjasaMinLon) * random.nextDouble());

    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 1,
      heading: 0,
      headingAccuracy: 1,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  void _cariPosyanduTerdekat() {
    if (!_hasLocation || _currentPosition == null) {
      _showSnackBar('Menunggu lokasi Anda...');
      _initLocation();
      return;
    }

    final posyanduDenganJarak = _posyanduList.map((p) {
      p.jarak = HaversineAlgorithm.hitungJarak(
        lat1: _currentPosition!.latitude,
        lon1: _currentPosition!.longitude,
        lat2: p.latitude,
        lon2: p.longitude,
      );
      return p;
    }).toList();

    posyanduDenganJarak.sort((a, b) => (a.jarak ?? 0).compareTo(b.jarak ?? 0));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HasilPencarianScreen(
          posyanduList: posyanduDenganJarak,
          currentPosition: _currentPosition!,
        ),
      ),
    );
  }

  void _showBantuan() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Bantuan',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _helpItem('1', 'Pastikan GPS aktif di perangkat Anda'),
            _helpItem(
                '2', 'Tekan tombol "Cari?" untuk mencari Posyandu terdekat'),
            _helpItem('3', 'Pilih Posyandu dari daftar hasil pencarian'),
            _helpItem('4', 'Ikuti rute yang ditampilkan di peta'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _helpItem(String no, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                no,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(msg, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: isError ? AppTheme.error : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // ── PETA PENUH LAYAR (sesuai mockup 3.12) ─────────────────────
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: 13.0,
                minZoom: 10,
                maxZoom: 18,
                onMapReady: () {
                  setState(() {
                    _isMapReady = true;
                  });
                  if (_pendingMapMove != null) {
                    _mapController.move(_pendingMapMove!, 15.0);
                    _pendingMapMove = null;
                  }
                },
              ),
              children: [
                // Tile peta (OSM / Satelit)
                TileLayer(
                  urlTemplate: _isSatellite
                      ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.posyandu_locator',
                  maxZoom: 18,
                ),

                // Marker semua posyandu (titik kecil di peta dengan label nama jika diaktifkan)
                if (_showPosyandu)
                  MarkerLayer(
                    markers: _posyanduList
                        .map(
                          (p) => Marker(
                            point: LatLng(p.latitude, p.longitude),
                            width: 120,
                            height: 60,
                            alignment: Alignment.center,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (!_hasLocation || _currentPosition == null) {
                                  _showSnackBar('Menunggu lokasi Anda...');
                                  _initLocation();
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RuteScreen(
                                      posyandu: p,
                                      currentPosition: _currentPosition!,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Badge nama posyandu
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: AppTheme.primary, width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.12),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      p.namaPosyandu,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  // Pin Ikon Posyandu
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              AppTheme.primary.withValues(alpha: 0.35),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.local_hospital_rounded,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                // Marker lokasi user — ikon orang sesuai mockup 3.12
                if (_hasLocation && _currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
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
                    ],
                  ),
              ],
            ),

            // ── STATUS BAR AREA (transparan, peta di bawahnya) ────────────
            // Hanya safe area atas

            // ── 2 TOMBOL FAB KANAN BAWAH sesuai mockup 3.12 ───────────────
            Positioned(
              right: 16,
              bottom: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Tombol "Cari?" (atas)
                  _buildFAB(
                    label: 'Cari?',
                    icon: Icons.search_rounded,
                    onTap: _isLoadingLocation ? null : _cariPosyanduTerdekat,
                    isLoading: _isLoadingLocation,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 300.ms)
                      .slideX(begin: 0.5),

                  const SizedBox(height: 12),

                  // Tombol "Bantuan" (bawah)
                  _buildFAB(
                    label: 'Bantuan',
                    icon: Icons.help_outline_rounded,
                    onTap: _showBantuan,
                    isPrimary: false,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 450.ms)
                      .slideX(begin: 0.5),

                  const SizedBox(height: 12),

                  // Tombol toggle Satelit/Peta
                  _buildFAB(
                    label: _isSatellite ? 'Peta' : 'Satelit',
                    icon: _isSatellite ? Icons.map_rounded : Icons.satellite_alt_rounded,
                    onTap: () => setState(() => _isSatellite = !_isSatellite),
                    isPrimary: false,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 600.ms)
                      .slideX(begin: 0.5),
                ],
              ),
            ),

            // ── Loading lokasi overlay kecil ───────────────────────────────
            if (_isLoadingLocation)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mendapatkan lokasi...',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // FAB bulat sesuai mockup 3.12
  Widget _buildFAB({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    bool isPrimary = true,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.primary : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isPrimary ? Colors.white : AppTheme.primary,
                    ),
                  )
                : Icon(
                    icon,
                    color: isPrimary ? Colors.white : AppTheme.textSecondary,
                    size: 22,
                  ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
