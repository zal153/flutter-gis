# Posyandu Locator - Flutter App
**Implementasi Algoritma Haversine & Dijkstra**
Kecamatan Arjasa, Kab. Jember

---

## 📦 Struktur Proyek

```
posyandu_locator/
├── lib/
│   ├── main.dart                          # Entry point
│   ├── core/
│   │   ├── theme.dart                     # Tema & warna aplikasi
│   │   └── constants.dart                 # Data posyandu & konstanta
│   ├── models/
│   │   └── posyandu_model.dart            # Model data
│   ├── algorithms/
│   │   ├── haversine.dart                 # Algoritma Haversine
│   │   └── dijkstra.dart                  # Algoritma Dijkstra
│   └── screens/
│       ├── splash_screen.dart             # Halaman splash
│       ├── map_screen.dart                # Halaman peta utama (OSM)
│       ├── hasil_pencarian_screen.dart    # Daftar posyandu terdekat
│       └── rute_screen.dart               # Rute & navigasi
├── android/
│   └── app/src/main/AndroidManifest.xml  # Permissions Android
└── pubspec.yaml                           # Dependencies
```

---

## 🚀 Cara Menjalankan

### 1. Pastikan Flutter terinstall (versi terbaru)
```bash
flutter --version
flutter doctor
```

### 2. Install dependencies
```bash
cd posyandu_locator
flutter pub get
```

### 3. Jalankan di emulator/device Android
```bash
flutter run
```

### 4. Build APK
```bash
flutter build apk --release
```

---

## 📦 Dependencies Utama

| Package | Versi | Fungsi |
|---|---|---|
| `flutter_map` | ^7.0.2 | Peta OpenStreetMap (gratis, tanpa API key) |
| `latlong2` | ^0.9.1 | Model koordinat lat/lng |
| `geolocator` | ^13.0.2 | Ambil lokasi GPS pengguna |
| `google_fonts` | ^6.2.1 | Font Plus Jakarta Sans |
| `flutter_animate` | ^4.5.0 | Animasi halus |
| `permission_handler` | ^11.3.1 | Manajemen izin Android |

---

## 🗺️ Peta - OpenStreetMap (OSM)

Aplikasi menggunakan **OpenStreetMap** via `flutter_map`:
- ✅ **Gratis** tanpa biaya & tanpa API key
- ✅ Tile URL: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- ✅ Tidak perlu konfigurasi tambahan

---

## 🧮 Algoritma

### Haversine (Perhitungan Jarak)
```dart
// lib/algorithms/haversine.dart
double jarak = HaversineAlgorithm.hitungJarak(
  lat1: userLat, lon1: userLon,
  lat2: posyanduLat, lon2: posyanduLon,
);
```
Menghitung jarak lurus antar dua koordinat GPS dalam km.

### Dijkstra (Rute Terpendek)
```dart
// lib/algorithms/dijkstra.dart
final rute = DijkstraAlgorithm.cariRuteTerpendek(
  titikAwal: titikUser,
  titikTujuan: titikPosyandu,
  semuaTitik: jaringanJalan,
  semuaRuas: ruasJalan,
);
```
Mencari jalur terpendek pada graf jaringan jalan berbobot.

---

## 🔌 Integrasi dengan Laravel Backend

Ganti data dummy di `lib/core/constants.dart` dengan API call:

```dart
// Contoh fetch dari Laravel API
final response = await http.get(
  Uri.parse('https://your-domain.com/api/posyandu'),
);
final data = jsonDecode(response.body);
final posyanduList = (data['data'] as List)
    .map((e) => PosyanduModel.fromJson(e))
    .toList();
```

### Endpoint Laravel yang dibutuhkan:
```
GET  /api/posyandu          → Daftar semua posyandu
GET  /api/titik-jalan       → Data titik jaringan jalan
GET  /api/jalan             → Data ruas jalan (bobot Dijkstra)
POST /api/cari-terdekat     → { lat, lng } → posyandu terdekat
```

---

## 📱 Fitur Aplikasi

| Halaman | Fitur |
|---|---|
| Splash Screen | Animasi pembuka, identitas aplikasi |
| Halaman Peta | Peta OSM, marker semua posyandu, marker GPS user |
| Hasil Pencarian | Daftar diurutkan Haversine, filter per desa |
| Halaman Rute | Rute Dijkstra di peta, pilih moda transportasi |

---

## ⚙️ Permissions yang Diperlukan (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

---

## 🎨 Design System

- **Warna Utama**: `#00695C` (Teal/Hijau Kesehatan)
- **Aksen**: `#FFB300` (Kuning Amber)
- **Font**: Plus Jakarta Sans (Google Fonts)
- **UI Style**: Material Design 3 + custom styling
