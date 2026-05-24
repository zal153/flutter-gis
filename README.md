# Posyandu Locator - Aplikasi Android (Flutter)

Aplikasi klien Android berbasis **Flutter** untuk mendeteksi lokasi Posyandu terdekat di wilayah Kecamatan Arjasa, Kabupaten Jember. Aplikasi ini mendampingi sistem Web GIS dan mengimplementasikan algoritma **Haversine** (pencarian instan jarak terdekat) serta **Dijkstra** (visualisasi rute perjalanan berdasarkan jaringan jalan riil).

---

## 📱 Fitur Utama

- **Peta Navigasi OpenStreetMap:** Menampilkan visualisasi peta interaktif secara gratis tanpa memerlukan Google Maps API Key.
- **Pencarian Terdekat (Haversine):** Menghitung jarak lurus dari titik koordinat GPS pengguna secara dinamis ke seluruh Posyandu terdekat.
- **Rute Perjalanan Terpendek (Dijkstra):** Menggambar jalur navigasi di peta berdasarkan titik koordinat jalan yang terhubung satu sama lain.
- **Moda Perjalanan:** Estimasi durasi tiba berdasarkan moda transportasi yang dipilih (Jalan Kaki, Mobil, Motor).
- **Splash Screen Interaktif:** Layar pembuka beranimasi dengan logo resmi aplikasi.

---

## 📂 Struktur Proyek Utama

```text
posyandu_locator/
├── assets/
│   └── images/
│       └── logo.png                       # Logo resmi aplikasi
├── lib/
│   ├── main.dart                          # Entry point aplikasi
│   ├── core/
│   │   ├── theme.dart                     # Tema & skema warna UI
│   │   └── constants.dart                 # Data posyandu, titik, dan ruas jalan
│   ├── models/
│   │   └── posyandu_model.dart            # Model parsing JSON data
│   ├── algorithms/
│   │   ├── haversine.dart                 # Logika matematika jarak lurus
│   │   └── dijkstra.dart                  # Logika pencarian jalur terpendek
│   └── screens/
│       ├── splash_screen.dart             # Splash screen beranimasi
│       ├── map_screen.dart                # Halaman peta utama
│       ├── hasil_pencarian_screen.dart    # Daftar pencarian terdekat
│       └── rute_screen.dart               # Tampilan detail navigasi rute
└── pubspec.yaml                           # Konfigurasi dependensi Flutter
```

---

## 🛠️ Dependensi Utama

| Package | Versi | Fungsi |
|---|---|---|
| `flutter_map` | ^7.0.2 | Integrasi peta OpenStreetMap (OSM) |
| `latlong2` | ^0.9.1 | Menangani tipe data geografis (Latitude, Longitude) |
| `geolocator` | ^13.0.2 | Membaca sensor GPS perangkat Android secara real-time |
| `permission_handler` | ^11.3.1 | Mengelola izin akses lokasi di Android |
| `google_fonts` | ^6.2.1 | Pemuatan font dinamis Plus Jakarta Sans |
| `flutter_animate` | ^4.5.0 | Menambahkan micro-animations pada komponen UI |

---

## 🚀 Cara Menjalankan Aplikasi

### 1. Prasyarat
Pastikan Flutter SDK (versi >= 3.0.0) telah terinstal dan terkonfigurasi dengan baik:
```bash
flutter doctor
```

### 2. Pemasangan Dependensi
Masuk ke direktori proyek Flutter lalu jalankan:
```bash
flutter pub get
```

### 3. Menjalankan di Device/Emulator
Hubungkan perangkat Android Anda atau aktifkan emulator, lalu ketik:
```bash
flutter run
```

### 4. Build APK Release
Untuk menghasilkan file installer APK final:
```bash
flutter build apk --release
```

---

## 🔒 Izin Akses Android (AndroidManifest.xml)
Aplikasi membutuhkan izin akses lokasi agar fitur GPS dapat berjalan dengan baik:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```
