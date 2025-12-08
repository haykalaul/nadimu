# Dokumentasi Kode Nadimu

Dokumen ini menjelaskan arsitektur, alur aplikasi, serta fungsi setiap berkas utama pada proyek Flutter Nadimu dengan bahasa yang mudah dipahami.

## Ringkasan Proyek
- Framework: Flutter, manajemen state dan navigasi dengan `GetX`.
- Data real-time: MQTT (`mqtt_client`) untuk menerima data sensor Pulse Oximeter.
- Penyimpanan riwayat: `SharedPreferences` via `HistoryService`.
- Visualisasi: `fl_chart` untuk grafik garis.
- Analisis AI: `google_generative_ai` (Gemini) untuk ringkasan dan saran.
- Tema: `AppTheme` mendukung mode terang/gelap.

## Alur Aplikasi
- Bootstrap: `lib/main.dart:15-23` menggunakan `GetMaterialApp` dengan tema dan routing.
- Routing: konstanta rute di `lib/routes/app_routes.dart`, peta halaman di `lib/routes/app_pages.dart:29-87`.
- Urutan layar:
  - Splash → Onboarding → Login/Register → Home (tab Dashboard, Statistics, History, Analysis).
  - Dari Dashboard dapat menuju koneksi IoT (`iotConnection`) lalu Monitoring real-time.
  - Monitoring dapat menyimpan pengukuran ke riwayat, yang ditampilkan di History dan dianalisis di Analysis.

## Alur Data Real‑time (MQTT)
- Koneksi: `lib/services/mqtt_service.dart:35-82` membuat klien, terhubung ke broker (`broker.mqtt.cool`), subscribe topik (`84-92`).
- Penerimaan pesan: handler di `94-125` mem-parsing payload dan memanggil callback.
- Integrasi controller: `lib/controllers/monitoring_controller.dart:24-38` men-setup callback untuk memperbarui `heartRate`, `spo2`, `quality`, `statusMessage`, serta buffer grafik `heartRateData`.
- Kontrol perangkat: kirim perintah via `publishCommand` di `lib/services/mqtt_service.dart:151-160`, dipanggil dari `lib/controllers/monitoring_controller.dart:112-126`.
- Simpan riwayat: pada berhenti monitoring, data dikemas dan disimpan via `HistoryService.saveMeasurement` (`lib/controllers/monitoring_controller.dart:128-166`, `lib/services/history_service.dart:24-41`).

## Analisis AI (Gemini)
- Sumber data: riwayat terbaru diambil dari `HistoryService.getRecentHistory` (`lib/services/history_service.dart:71-75`).
- Pengolahan prompt: bangun ringkasan input di `lib/controllers/analysis_controller.dart:223-291`, susun prompt di `206-221`.
- Panggilan model: `analyzeHealth` (`lib/controllers/analysis_controller.dart:93-170`) menggunakan `gemini-2.5-flash` dengan output JSON (summary, risk_assessments, activity_suggestions).
- Catatan keamanan: API key saat ini tertanam di `lib/controllers/analysis_controller.dart:48`. Disarankan pindahkan ke `--dart-define=GEMINI_API_KEY` atau penyimpanan aman.

## Statistik
- Agregasi metrik: `lib/controllers/statistics_controller.dart:23-81` menghitung rata‑rata, tertinggi, terendah, dan menyiapkan data grafik dari riwayat.
- Pergantian rentang waktu: `changeFilter` di `lib/controllers/statistics_controller.dart:83-89` memicu pemuatan ulang.

## Riwayat Pengukuran
- Memuat riwayat 7 hari: `lib/controllers/history_controller.dart:15-41`.
- Melihat detail: `viewDetails` di `lib/controllers/history_controller.dart:43-47` melakukan navigasi ke halaman detail.
- Memuat semua riwayat: `lib/controllers/history_controller.dart:54-79`.
- Layanan penyimpanan:
  - Ambil semua: `lib/services/history_service.dart:9-22`.
  - Simpan: `24-41` dengan batas maksimal item (`_maxHistoryItems`).
  - Hapus item: `44-58`.
  - Hapus semua: `61-69`.

## Struktur File Utama

### Entry & Routing
- `lib/main.dart`: Inisialisasi aplikasi, tema, dan registrasi rute (`15-23`).
- `lib/routes/app_routes.dart`: Konstanta nama rute (Splash, Onboarding, Login, Register, Home, Dashboard, Statistics, History, HistoryDetails, Analysis, Account, IoT Connection, Realtime Monitoring).
- `lib/routes/app_pages.dart`: Daftar halaman `GetPage` beserta `Bindings` untuk controller (`29-87`).

### Controllers
- `lib/controllers/dashboard_controller.dart`:
  - Memuat pengukuran terbaru pada `onInit` (`17-20`).
  - Aksi: `startMeasurement` navigasi ke IoT (`41-43`), `changeActivity` (`45-47`), `refresh` (`49-51`).
- `lib/controllers/history_controller.dart`:
  - Memuat riwayat (`15-41`), navigasi detail (`43-47`), muat semua (`54-79`).
- `lib/controllers/monitoring_controller.dart`:
  - Setup MQTT dan koneksi di `onInit` (`24-38`).
  - Callback data/status (`40-90`).
  - Koneksi: `connectMqtt` (`92-110`).
  - Kirim perintah: `sendCommand` (`112-126`).
  - Simpan dan keluar: `stopMonitoring` (`128-166`).
  - Bantuan status: `getStatusDisplay` (`172-188`), `getStatusColor` (`190-202`).
- `lib/controllers/analysis_controller.dart`:
  - Inisialisasi default di `onInit` (`51-55`), ` _initializeDefaultData` (`57-91`).
  - Analisis AI: `analyzeHealth` (`93-170`).
  - Konversi level risiko dan warna: `172-204`, `183-192`.
  - Bangun prompt dan input: `206-221`, `223-291`.
- `lib/controllers/statistics_controller.dart`:
  - Hitung statistik dan siapkan data grafik (`23-81`).
- `lib/controllers/connection_controller.dart`:
  - Pilih tipe koneksi, daftar perangkat, navigasi ke monitoring (`16-20`).
- `lib/controllers/auth_controller.dart`:
  - Navigasi sederhana ke `home` setelah login/register/skip (`6-16`).
- `lib/controllers/account_controller.dart`:
  - Data profil reaktif, keluar (`13-15`), ubah gender (`22-24`).
- `lib/controllers/onboarding_controller.dart`:
  - Data onboarding, navigasi ke login (`34-44`).

### Services
- `lib/services/mqtt_service.dart`:
  - `connect` (`35-82`), subscribe (`84-92`), handler pesan (`94-125`).
  - `ensureMessageHandlers` (`127-131`) untuk memastikan listener aktif.
  - Callback koneksi (`133-149`), kirim perintah (`151-160`), `disconnect` (`163-171`).
- `lib/services/history_service.dart`:
  - Pengelolaan riwayat di `SharedPreferences`: ambil, simpan, hapus, bersihkan, filter berdasarkan hari (`9-75`).

### Models
- `lib/models/pulseox_data.dart`:
  - Struktur data dari perangkat: `heartrate`, `spo2`, `quality`, `timestamp` (`1-31`).
- `lib/models/measurement_history.dart`:
  - Struktur riwayat pengukuran + helper label tanggal/waktu/status (`1-96`).

### Views — Screens
- `lib/views/screens/splash_screen.dart`: Layar awal, masuk ke onboarding.
- `lib/views/screens/onboarding_screen.dart`: Serangkaian halaman onboarding (pakai `OnboardingPage`).
- `lib/views/screens/login_screen.dart` / `register_screen.dart`: Autentikasi UI sederhana, navigasi ke `home`.
- `lib/views/screens/home_screen.dart`: Tab bar 4 halaman (Dashboard, Statistics, History, Analysis) (`8-28`, nav item `86-129`).
- `lib/views/screens/dashboard_screen.dart`: Ringkasan metrik terbaru, selector aktivitas, pintasan ke koneksi IoT.
- `lib/views/screens/statistics_screen.dart`: Visualisasi tren dan angka agregat (pakai `LineChartWidget`).
- `lib/views/screens/history_screen.dart`: Daftar riwayat pengukuran, item dapat dibuka untuk detail.
- `lib/views/screens/history_details_screen.dart`: Detail satu pengukuran, grafik, insight.
- `lib/views/screens/analysis_screen.dart`: Tombol analisis AI (`126-160`), tampilan risiko & saran (`299-343`, ikon `472-486`).
- `lib/views/screens/iot_connection_screen.dart`: Pilih tipe koneksi/device, daftar topik MQTT (`_TopicCard` `444-501`).
- `lib/views/screens/realtime_monitoring_screen.dart`: Tampilan metrik real‑time, tombol kontrol perangkat, indikator kualitas.
- `lib/views/screens/account_screen.dart`: Data profil dan aksi update/logout (reactive card `260-311`).

### Views — Widgets
- `lib/views/widgets/line_chart_widget.dart`: Widget grafik garis generik (`1-64`).
- `lib/views/widgets/onboarding_page.dart`: Komponen halaman onboarding dengan `Lottie` dan tombol navigasi (`4-106`).
- `lib/views/widgets/custom_button.dart`: Saat ini kosong.
- `lib/views/widgets/custom_card.dart`: Saat ini kosong.

### Tema
- `lib/themes/app_theme.dart`: Palet warna dan tema Material untuk mode terang/gelap (`1-45`).

### Aset & Konfigurasi
- Aset: `assets/images`, `assets/icons`, `assets/fonts`, `assets/lottie` terdaftar di `pubspec.yaml:89-117`.
- Dependensi utama (digunakan di kode): `get`, `mqtt_client`, `shared_preferences`, `fl_chart`, `google_generative_ai`, `fluttertoast`, `lottie` (`pubspec.yaml:31-80`).

## Pola & Praktik Penting
- State reaktif: variabel `Rx` di controller (mis. `heartRate`, `spo2`) diobservasi di UI dengan `Obx`.
- Navigasi: gunakan `Get.toNamed`, `Get.offAllNamed` sesuai rute (`lib/routes/app_routes.dart`).
- Penyimpanan lokal: riwayat disimpan sebagai daftar JSON di `SharedPreferences` dengan batas ukuran.
- Keamanan: hindari menaruh API key langsung di kode; gunakan konfigurasi build atau penyimpanan aman.

## Cara Menambah Fitur
- Tambah layar: definisikan rute di `app_routes.dart`, daftarkan `GetPage` di `app_pages.dart` dengan `binding` controller bila perlu.
- Tambah sumber data: buat service baru, injeksikan ke controller, expose variabel `Rx` untuk diobservasi UI.
- Tambah grafik/visual: gunakan `LineChartWidget` atau buat widget serupa untuk dataset baru.

## Diagram Alur Ringkas
- Sensor → MQTT Broker → `MqttService` → `MonitoringController` → UI Monitoring.
- Monitoring berhenti → `HistoryService.saveMeasurement` → tampil di `History` & `HistoryDetails`.
- `HistoryService.getRecentHistory` → `StatisticsController` → UI Statistik.
- `HistoryService.getRecentHistory` → `AnalysisController.analyzeHealth` → UI Analisis.

---
Dokumentasi ini dirancang agar pengembang baru dapat cepat memahami struktur dan alur kerja aplikasi Nadimu. Rujukan `file_path:line_number` disediakan untuk navigasi cepat ke lokasi kode terkait.
