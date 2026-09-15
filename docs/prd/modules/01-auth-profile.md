# Autentikasi dan Profil

Status: kerangka awal, belum menjadi PRD final.
Acuan: [konteks utama](../../../mobile_cooperative_investment_app_context.md) · [indeks PRD](../README.md).
Cakupan rilis: rilis pertama. Detail modul menunggu pembahasan.

## Pengguna dan kebutuhan

Pengguna: Semua anggota.
Ruang lingkup awal: Login, membaca status investor dari API profile, profil anggota, rekening, keamanan, logout.

## Journey awal

Login → profile/capability dimuat → Home yang sesuai; Profil → perubahan data → hasil.

## Dependensi

Kontrak autentikasi/profile; dipakai semua modul.

## Keputusan terbuka saat modul dibahas

Siapa pembuat akun; perlu registrasi atau tidak; identitas login; key status investor; pemulihan akun; PIN; aturan edit profil.

## Kelengkapan sebelum desain dan implementasi

- Tujuan modul dan user stories disepakati.
- Kebutuhan fungsional dan kriteria penerimaan dapat diverifikasi.
- Struktur informasi, alur utama/alternatif, dan inventaris layar disepakati.
- Loading, empty, error, pending, success, disabled, dan konfirmasi dipetakan sesuai aksi.
- Kebutuhan data dicatat; kontrak API aktual dipisahkan dari data contoh.
- Keputusan terbuka yang menghalangi alur diselesaikan bersama pengguna.
- Setelah desain/prototipe ditinjau, implementasi dan hasil verifikasi dicatat.

Kontrak API dan cakupan lengkap modul masih menunggu pembahasan. Implementasi frontend login mengikuti desain Pen Dev dan permintaan pengguna pada 14 September 2026.


## Implementasi frontend — 14 September 2026

- Acuan visual: `basya_ui_canvas.pen`, frame `qa4o5` / `03 / AUTH-01 / Login`.
- Ikon launcher Android dan iOS memakai `assets/logo/basya-favicon.png`; logo horizontal pada login mengikuti desain, memakai `assets/logo/logo_basya.png`.
- Splash memutar `assets/animation/Scene-3-no-watermark.json` satu kali, lalu mengganti rute ke login. Fallback 8 detik mencegah startup tertahan ketika aset gagal dimuat.
- Login memakai username atau email dan kata sandi melalui `POST /app/login`. Validasi lokal mewajibkan kedua isian.
- Tombol tampil/sembunyikan kata sandi aktif. Layout dapat digulir saat keyboard terbuka atau teks diperbesar.
- Submit valid mengirim JSON melalui HTTPS. JWT disimpan dengan Android Keystore/iOS Keychain tanpa menyimpan kata sandi, dan sesi lokal berakhir mengikuti `expires_in` dari API.
- Bantuan membuka dialog untuk menghubungi pengurus; nomor/tautan kontak koperasi belum diberikan.
- Refresh token, registrasi, pemulihan akun, profil, dan routing berdasarkan status investor belum dapat diimplementasikan karena endpoint/kontraknya belum tersedia.
- Verifikasi: `flutter analyze` bersih; 3 widget test lulus. Tampilan pada perangkat fisik dan build iOS belum diverifikasi.

## Kontrak login API — 14 September 2026

- Endpoint produksi: `POST https://api.basyainvestama.id/app/login` tanpa Bearer token.
- Header: `Content-Type: application/json` dan `Accept: application/json`.
- Request wajib: `username` (username atau email) dan `password`.
- Respons 200: `status: true`, `message`, JWT di `token`, `token_type: Bearer`, dan `expires_in: 3600` detik.
- Respons 400 diperlakukan sebagai input tidak lengkap/tidak valid.
- Respons 401 menampilkan `messages.error`, termasuk pesan `Username atau password tidak valid`.
- Respons 500 menampilkan pesan gangguan layanan tanpa detail teknis server.
- JWT disimpan melalui secure storage. Password tidak disimpan atau ditulis ke log.
- Saat aplikasi dibuka, sesi lokal yang belum kedaluwarsa dipulihkan. Setelah kedaluwarsa, token lokal dihapus dan pengguna diarahkan ke login.
- Belum ada silent refresh karena dokumentasi yang tersedia belum menyediakan refresh-token endpoint.
