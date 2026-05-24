// lib/models/posyandu_model.dart
import 'package:latlong2/latlong.dart';

class PosyanduModel {
  final int id;
  final String namaPosyandu;
  final String? alamat;
  final String? status;
  final String? keterangan;
  final String desa;
  final double latitude;
  final double longitude;
  double? jarak; // dalam km, dihitung oleh Haversine

  PosyanduModel({
    required this.id,
    required this.namaPosyandu,
    this.alamat,
    this.status,
    this.keterangan,
    required this.desa,
    required this.latitude,
    required this.longitude,
    this.jarak,
  });

  String get namaLengkap => namaPosyandu;

  factory PosyanduModel.fromJson(Map<String, dynamic> json) {
    return PosyanduModel(
      id: json['id'],
      namaPosyandu: json['nama_posyandu'] ?? 'Posyandu Tanpa Nama',
      alamat: json['alamat'],
      status: json['status'],
      keterangan: json['keterangan'],
      desa: json['desa'] != null ? json['desa']['nama_desa'] : 'Tidak ada',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
    );
  }
}

class TitikJalan {
  final String id;
  final String nama;
  final double latitude;
  final double longitude;

  TitikJalan({
    required this.id,
    required this.nama,
    required this.latitude,
    required this.longitude,
  });
}

class RuasJalan {
  final String titikAwalId;
  final String titikAkhirId;
  final double jarak;

  RuasJalan({
    required this.titikAwalId,
    required this.titikAkhirId,
    required this.jarak,
  });
}

class RouteModel {
  final List<LatLng> path;
  final double distance;
  final List<LatLng>? roadPath;

  RouteModel({
    required this.path,
    required this.distance,
    this.roadPath,
  });
}
