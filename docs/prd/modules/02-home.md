# Home dan Ringkasan Keuangan

Status: prototipe frontend investor diterapkan; PRD bisnis dan kontrak API belum final.
Acuan: [konteks utama](../../../mobile_cooperative_investment_app_context.md) · [indeks PRD](../README.md).
Cakupan rilis: rilis pertama. Detail modul menunggu pembahasan.

## Pengguna dan kebutuhan

Pengguna: Semua anggota; informasi investasi khusus investor.
Ruang lingkup awal: Total Saldo, rincian simpanan, Buy Power, dana diinvestasikan, profit bulan ini dan akumulasi, ringkasan Multiguna untuk kewajiban terdekat.

## Journey awal

Login → Home → pahami kondisi keuangan → aksi modul terkait.

## Dependensi

Autentikasi/profile, Simpanan, Buy Power, Investasi, Multiguna.

## Keputusan terbuka saat modul dibahas

Susunan navigasi; field ringkasan; definisi saldo dapat digunakan; periode profit.

## Kelengkapan sebelum desain dan implementasi

- Tujuan modul dan user stories disepakati.
- Kebutuhan fungsional dan kriteria penerimaan dapat diverifikasi.
- Struktur informasi, alur utama/alternatif, dan inventaris layar disepakati.
- Loading, empty, error, pending, success, disabled, dan konfirmasi dipetakan sesuai aksi.
- Kebutuhan data dicatat; kontrak API aktual dipisahkan dari data contoh.
- Keputusan terbuka yang menghalangi alur diselesaikan bersama pengguna.
- Setelah desain/prototipe ditinjau, implementasi dan hasil verifikasi dicatat.

Kontrak API Home belum tersedia; data contoh tidak dianggap sebagai kontrak backend.

## Implementasi frontend sementara

- Versi investor menjadi Home default setelah login dan pemulihan sesi. Varian non-investor sudah tersedia sebagai mode frontend, tetapi belum dipilih otomatis dari API profile.
- Untuk preview sementara, Home menyediakan toggle Investor/Non-investor di layar agar dua mode dapat dibandingkan tanpa mengubah session.
- Acuan visual: frame Pen Dev `12 / HOME-02A / Investor / Integrated hero`.
- Hero atas memuat foto, sapaan, nama anggota, notifikasi, Total Saldo, dan panel saldo sesuai jenis anggota. Investor menampilkan Simpanan Sukarela + Buy Power agar dana yang dapat ditarik langsung terlihat; non-investor menampilkan Simpanan Sukarela + Simpanan Wajib.
- Pada viewport normal hero tetap di atas dan konten di bawahnya scroll mandiri. Layar pendek atau text scale besar melepas pin agar konten tetap dapat diakses.
- Panel saldo memakai permukaan frosted-elevated dengan nominal yang ikut disamarkan oleh kontrol visibilitas saldo.
- Aksi cepat investor: Top Up, Withdraw, Pinjam, dan Mutasi. Aksi cepat non-investor: Top Up, Withdraw, dan Pinjam.
- Konten Home investor memisahkan Investasi Anda dan Multiguna: investasi menampilkan dana diinvestasikan, profit bulan berjalan, dan akumulasi profit; Multiguna menampilkan cicilan berikutnya dan jadwal terkait. Konten Home non-investor tidak menampilkan section investasi.
- Navbar investor: Beranda, Simpanan, Investasi, Multiguna, Profil. Navbar non-investor: Beranda, Simpanan, Multiguna, Profil dengan pill lebih compact.
- Aktivitas terakhir menampilkan lima aktivitas contoh.
- Pill navbar mengambang di atas konten dengan gradient putih di bagian bawah; konten tetap terlihat di belakang dan memiliki ruang scroll aman.
- Seluruh nilai Home masih berasal dari `InvestorHomeData.demo` dan `MemberHomeData.demo`; belum ada endpoint Home atau profile capability yang dihubungkan.
- Tujuan fitur yang belum dibuat menampilkan feedback sementara dan tidak menjalankan transaksi.
