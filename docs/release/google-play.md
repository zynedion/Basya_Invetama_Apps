# Persiapan Google Play — Basya Investama

Audit sumber: 9 November 2026. Status: persiapan repository; belum ada AAB bertanda tangan atau upload Play Console yang diverifikasi.

## Identitas dan konfigurasi

| Item | Nilai |
| --- | --- |
| Nama aplikasi | Basya Investama |
| Application ID / namespace | `id.basyainvestama.app` |
| Versi awal repository | `1.0.0+1` |
| API utama | `https://api.basyainvestama.id` |
| Target / compile SDK | Minimal 36; mengikuti Flutter bila lebih tinggi |
| SDK Flutter lokal yang diperiksa | Default target/compile 36, NDK `28.2.13676358` |
| Android Gradle Plugin | 8.11.1 |
| Signing release | Upload key dari `android/key.properties`; tidak memakai debug key |
| Izin manifest utama | INTERNET, POST_NOTIFICATIONS |
| Backup aplikasi | `allowBackup=false` |

Jangan mengganti application ID untuk update aplikasi yang sudah terdaftar. Periksa package Firebase Android juga cocok. Manifest gabungan dan dependensi di AAB final tetap perlu diperiksa untuk izin tambahan.

## 1. Lengkapi informasi pemilik

Konfirmasi pemilik pada 9 November 2026:

- Package `id.basyainvestama.app` belum pernah diupload. Rilis pertama dapat memakai `1.0.0+1` selama belum ada upload lain setelah konfirmasi ini.
- Akun Play Console saat ini **pribadi**. Persyaratan akun organisasi untuk layanan keuangan masih perlu diselesaikan sebelum publikasi.
- Upload keystore menurut pemilik kemungkinan belum ada; `android/key.properties` juga belum tersedia saat audit. Keberadaan key di lokasi lain belum dipastikan.
- URL kebijakan privasi belum tersedia. Email dukungan dan identitas badan hukum belum diberikan.

- [x] Konfirmasi riwayat upload package: belum pernah diupload.
- [ ] Pastikan tidak ada upload keystore existing; jika belum ada, buat key baru secara lokal dan backup.
- [ ] Nama badan hukum, alamat, kontak, dan identitas developer terverifikasi.
- [ ] Akun organisasi dan informasi D-U-N-S yang sesuai. Google mensyaratkan akun organisasi untuk penyedia produk/layanan keuangan; cocokkan klasifikasi layanan Basya dengan kebijakan resmi.
- [ ] Email dukungan yang aktif, website resmi, negara distribusi, dan keputusan kategori Finance.
- [ ] URL publik kebijakan privasi yang benar-benar tersedia; tampilkan pula aksesnya di aplikasi.
- [ ] Proses permintaan penghapusan data, ketentuan retensi transaksi, dan penanggung jawabnya.
- [ ] Akun reviewer khusus dengan data uji dan akses fitur yang memadai, termasuk instruksi login. Masukkan kredensial di App access pada Console, bukan di Git.
- [ ] Verifikasi perizinan dan pengungkapan layanan simpanan/investasi/Multiguna oleh pemilik bisnis. Jangan mengklaim izin OJK atau status legal tertentu tanpa bukti.

Sumber: [jenis akun developer](https://support.google.com/googleplay/android-developer/answer/13634885?hl=en), [Financial Services](https://support.google.com/googleplay/android-developer/answer/9876821?hl=en).

## 2. Upload key dan build

Jika aplikasi sudah terdaftar, gunakan upload key yang cocok dengan sertifikat pada Console. Jangan membuat pengganti tanpa prosedur reset upload key. Untuk aplikasi baru, jalankan contoh berikut di terminal pribadi; keytool meminta password secara interaktif. Ganti lokasi dan data identitas sesuai pemilik aplikasi.

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE/private-keys"
keytool -genkeypair -v -keystore "$env:USERPROFILE/private-keys/basya-upload.jks" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
Copy-Item android/key.properties.example android/key.properties
```

Isi `storeFile`, `storePassword`, `keyAlias`, `keyPassword` secara lokal. Gunakan forward slash untuk path Windows. Path relatif dihitung dari `android/`. File memakai format Java Properties; escape karakter khusus pada password sesuai format tersebut. Jangan mengirim isi file atau password melalui chat/log. Backup keystore dan password secara terpisah di penyimpanan organisasi yang aman. File rahasia telah diabaikan Git.

```powershell
# BuildNumber wajib lebih tinggi daripada seluruh versionCode yang pernah diupload.
./scripts/build-play-release.ps1 -BuildNumber 1 -BuildName 1.0.0
```

Script menjalankan pub get, analyze, seluruh test, kemudian build release; berhenti jika ada kegagalan. Output: `build/app/outputs/bundle/release/app-release.aab`, disertai hash SHA-256. Ini tidak mengupload apa pun. Gradle menolak release tanpa konfigurasi keystore; debug tetap menggunakan konfigurasi debug biasa.

Aktifkan Play App Signing saat membuat release pertama. Bedakan **upload certificate** dengan **app signing certificate** yang dipakai Google untuk distribusi. Daftarkan fingerprint app signing di integrasi yang membutuhkan sertifikat (misalnya layanan autentikasi tertentu), lalu uji build yang diinstal dari Play.

Sumber: [Flutter Android release](https://docs.flutter.dev/deployment/android).

## 3. Pekerjaan produk sebelum produksi

Temuan ini berasal dari kode saat audit, bukan hasil pengujian API/perangkat:

- `BasyaFormPage` masih melakukan simulasi submit lokal dan menampilkan Mode demo. Termasuk jalur edit profil/ganti password dari Profil. Selesaikan integrasi atau keluarkan aksi yang belum tersedia dari rilis produksi; deskripsi toko tidak boleh menjanjikan transaksi yang belum berfungsi.
- Investasi sekarang menerima session serta memiliki API ringkasan, peluang dan portofolio. Jangan menganggap seluruh halaman masih dummy hanya karena nilai default demo; uji jalur login nyata dan periksa aksi detail/placeholder yang tersisa.
- Profil belum menyediakan tautan kebijakan privasi atau jalur penghapusan akun. URL dan proses backend harus disediakan pemilik sebelum diintegrasikan.
- Token dan password disimpan melalui `flutter_secure_storage` untuk pemulihan sesi. Kebijakan privasi harus menjelaskan autentikasi dan pengelolaan sesi secara benar. README telah diselaraskan dengan kode.
- Log token FCM dan body backend dihapus dalam persiapan ini; diagnostik startup, FCM dan logout dibatasi ke mode debug dengan jenis error saja.

Jangan memperlakukan build yang berhasil sebagai persetujuan produksi. Mulai dari Internal testing dengan tester yang memahami fitur demo dan gunakan akun uji.

## 4. Store listing (draf)

Bahasa: Indonesia. Nama: **Basya Investama** (15 karakter; batas 30).

Deskripsi singkat (batas 80):

> Pantau simpanan, investasi, dan informasi keanggotaan Basya Investama.

Deskripsi lengkap (di bawah batas 4.000; cocokkan dengan hasil QA sebelum dipakai):

> Basya Investama membantu anggota mengakses informasi keanggotaan dalam satu aplikasi.
>
> Lihat ringkasan akun, informasi simpanan, riwayat aktivitas, serta informasi investasi dan portofolio sesuai akses akun Anda. Informasi Multiguna tersedia sesuai layanan dan akun yang terdaftar.
>
> Gunakan akun anggota yang telah diberikan oleh pengelola Basya Investama untuk masuk. Ketersediaan data dan layanan mengikuti status keanggotaan Anda.
>
> Untuk bantuan terkait akun dan layanan, hubungi pengelola melalui kontak dukungan pada halaman aplikasi ini.

Jangan menambahkan klaim imbal hasil pasti, transaksi instan, keamanan absolut, atau persetujuan regulator. Draf ini tidak menjanjikan pengajuan/pembayaran dari formulir demo.

Aset yang perlu disiapkan dari build aktual:

- [ ] Ikon toko 512 × 512 PNG 32-bit, maksimal 1 MB; periksa hasil ekspor logo yang sudah ada di `assets/logo/basya-favicon.png`.
- [ ] Feature graphic 1024 × 500, JPEG atau PNG 24-bit tanpa alpha.
- [ ] Minimal 2 screenshot aplikasi; siapkan 4–6 gambar layar login, beranda, simpanan, aktivitas, investasi/portofolio menggunakan akun uji. Jangan tampilkan data anggota nyata.
- [ ] Screenshot JPEG/PNG 24-bit tanpa alpha, sisi 320–3840 px dan rasio sisi panjang maksimal 2 kali sisi pendek. Contoh aman: 1080 × 1920.
- [ ] Jangan memakai gambar canvas/mockup desain sebagai bukti fitur yang belum tersedia pada build.

Sumber: [preview assets](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en).

Catatan rilis untuk **internal testing**, setelah fitur terkait benar-benar diuji:

```text
<id-ID>
Versi pengujian awal Basya Investama untuk evaluasi akses akun, informasi simpanan, aktivitas, dan investasi. Beberapa formulir masih berupa demo.
</id-ID>
```

## 5. App content dan Data safety

Isi App access, Ads, content rating, target audience, Data safety, privacy policy, Financial features, dan deklarasi lain yang diminta Console. Belum ada SDK iklan dalam dependensi langsung yang diperiksa; konfirmasi keseluruhan build sebelum memilih No ads. Jawab kuesioner rating menurut fungsi nyata, jangan menetapkan rating secara perkiraan.

Inventaris awal berikut **bukan jawaban final Data safety**. Cocokkan backend, seluruh SDK, pemrosesan sementara, data wajib/opsional, tujuan, serta pengecualian sharing resmi bersama pengelola data.

| Area | Bukti di sumber | Yang perlu dikonfirmasi |
| --- | --- | --- |
| Autentikasi | Username/password dikirim ke endpoint login HTTPS | Kategori identitas, tujuan account management, retensi server |
| Profil anggota | Data profil ditampilkan setelah login | Nama, ID anggota, email/telepon/alamat dan field nyata yang diproses |
| Data keuangan | API ringkasan, simpanan, aktivitas, investasi, Multiguna | Financial info, purchase/transaction history sesuai data nyata |
| Identitas perangkat/notifikasi | Firebase Messaging dan pengiriman token FCM ke backend | Device or other IDs, pemrosesan Firebase, tujuan notifikasi |
| Penyimpanan lokal | Secure storage token/kredensial dan tujuan navigasi terakhir | Beda data lokal dengan data yang dikirim keluar perangkat |
| Berkas formulir | Dependensi file_selector dan formulir demo | Apakah rilis final mengupload dokumen; jangan menyatakan upload hanya dari keberadaan dependency |

HTTPS terlihat pada endpoint aplikasi; ini belum membuktikan seluruh SDK/server memenuhi deklarasi enkripsi. Jangan memilih “tidak mengumpulkan data” hanya karena aplikasi tidak memakai analytics. Audit retensi, penerima data, dan mekanisme penghapusan di backend.

Kebijakan privasi final perlu memuat identitas badan hukum/kontak, kategori data dan tujuan, penyedia layanan, keamanan, retensi, penghapusan, hak pengguna, serta tanggal berlaku. Publikasikan halaman yang dapat dibuka tanpa login dan tautkan di aplikasi. Dokumen legal final belum dibuat karena fakta badan hukum dan praktik backend belum tersedia.

Jika aplikasi memungkinkan pembuatan akun (termasuk alur pendaftaran yang diarahkan keluar aplikasi), evaluasi kewajiban jalur penghapusan dalam aplikasi dan URL web permintaan penghapusan. Untuk akun yang dibuat pengelola, pastikan jawaban Console sesuai alur aktual; jangan menyamakan logout dengan hapus akun.

Sumber: [persiapan review](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en), [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en), [penghapusan akun](https://support.google.com/googleplay/android-developer/answer/13327111).

## 6. Upload dan QA

1. Verifikasi akun developer; buat aplikasi atau buka aplikasi existing dengan package yang sama.
2. Lengkapi listing dan App content, termasuk Financial features sesuai layanan sebenarnya.
3. Buat release di Internal testing, konfigurasi Play App Signing, upload AAB dan catatan rilis.
4. Periksa laporan App Bundle Explorer: package, versionCode, target API, permissions, signing dan kompatibilitas native 16 KB.
5. Tambahkan tester dan buka opt-in link. Install dari Google Play, bukan hanya APK lokal.
6. Uji login benar/salah, pemulihan sesi, logout/login akun lain, koneksi putus, data kosong/error, saldo/riwayat, portofolio, navigasi Android back, dan semua tombol/formulir. Pastikan tidak ada saldo demo yang tampil sebagai data anggota nyata.
7. Uji notifikasi saat foreground/background/aplikasi ditutup, izin ditolak/diberikan, serta pelepasan token pada logout.
8. Uji perangkat Android minimum yang didukung dan Android 16, edge-to-edge, keyboard, ukuran teks, serta emulator/perangkat 16 KB. SDK/AGP baru saja tidak membuktikan seluruh library native kompatibel.
9. Selesaikan crash/ANR dan temuan pre-launch report bila tersedia; catat hasil serta versi build yang diuji.
10. Ajukan closed testing/production sesuai akses akun setelah seluruh blocker selesai. Untuk akun pribadi baru yang terkena syarat testing, Google menyebut 12 tester opted-in selama 14 hari berturut-turut sebelum pengajuan akses produksi; ini tidak menggantikan persyaratan akun organisasi untuk layanan keuangan.

Sumber: [target API](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en), [16 KB](https://developer.android.com/guide/practices/page-sizes), [testing akun pribadi](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en).

## Catatan validasi persiapan

- Inspeksi konfigurasi Android, sumber Flutter, dan kebijakan resmi dilakukan.
- Pemeriksaan awal `flutter --version` tidak menghasilkan output dan dihentikan pada sesi tersebut. Formatter Dart kemudian berhasil setelah akses cache diberikan.
- Dua file test notifikasi dicoba, tetapi Windows Application Control memblokir `flutter_tester.exe`; tidak ada test yang berhasil dijalankan. Jalankan ulang pada lingkungan yang mengizinkan executable tersebut. Jangan menganggap kegagalan lingkungan ini sebagai hasil test lulus.
- Pemeriksaan sintaks PowerShell script berhasil. Aturan ignore keystore/key.properties dan diff whitespace telah diperiksa.
- `flutter analyze` pada empat file Dart yang diubah menghasilkan **No issues found**. Ini bukan hasil full-project analysis atau test perangkat.
- Gradle `:app:validateUploadSigning --offline` berhasil memuat konfigurasi Kotlin lalu gagal sesuai harapan dengan pesan `Release requires android/key.properties`. Pengaman konfigurasi kosong terverifikasi; signing dengan key valid dan build AAB belum diuji.
- `android/key.properties` belum tersedia saat audit. AAB signed belum dibuat; fingerprint, manifest gabungan, ukuran bundle, library native dan perilaku perangkat belum diverifikasi.
- Belum ada tindakan di Play Console dan belum ada publikasi.
