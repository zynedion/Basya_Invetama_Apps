# Home dan Ringkasan Keuangan

Status: frontend Home investor/non-investor diterapkan dan ringkasan keuangan terhubung ke API.
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

## Kontrak API ringkasan

- `GET /app/summary` memakai bearer token sesi aktif.
- `scope: personal` menampilkan ringkasan milik anggota. Jenis Home mengikuti capability dari profile dan switch preview disembunyikan.
- `scope: global` dipakai root/admin/MGR dan mempertahankan switch Investor/Non-investor untuk kebutuhan development.
- Nilai API yang digunakan: total saldo, Buy Power, Simpanan Sukarela/Pokok/Wajib, dana aktif diinvestasikan, profit bulan berjalan, akumulasi profit, dan periode.
- Pada preview non-investor dengan scope global, Total Saldo dihitung dari jumlah tiga jenis simpanan agar Buy Power global tidak tercampur ke tampilan anggota non-investor.
- Multiguna dan aktivitas terakhir masih menggunakan data frontend sementara sampai endpoint masing-masing tersedia.

## Implementasi frontend sementara

- Versi investor menjadi Home default setelah login dan pemulihan sesi. Varian non-investor sudah tersedia sebagai mode frontend, tetapi belum dipilih otomatis dari API profile.
- Untuk preview sementara, Home menyediakan toggle Investor/Non-investor di layar agar dua mode dapat dibandingkan tanpa mengubah session.
- Acuan visual: frame Pen Dev `12 / HOME-02A / Investor / Integrated hero`.
- Hero atas memuat foto, sapaan, nama anggota, notifikasi, Total Saldo, dan panel saldo sesuai jenis anggota. Investor menampilkan Simpanan Sukarela + Buy Power agar dana yang dapat ditarik langsung terlihat; non-investor menampilkan Simpanan Sukarela + Simpanan Wajib.
- Navigasi utama dimiliki `MainContainer` dan mempertahankan halaman melalui `IndexedStack`. Ikon selalu terlihat; hanya tab aktif yang berbentuk pil dan menampilkan label.
- Pada viewport normal hero tetap di atas dan konten di bawahnya scroll mandiri. Layar pendek atau text scale besar melepas pin agar konten tetap dapat diakses.
- Panel saldo memakai permukaan frosted-elevated dengan nominal yang ikut disamarkan oleh kontrol visibilitas saldo.
- Aksi cepat investor: Top Up, Withdraw, Pinjam, dan Mutasi. Aksi cepat non-investor: Top Up, Withdraw, dan Pinjam.
- Konten Home investor memisahkan Investasi Anda dan Multiguna: investasi menampilkan dana diinvestasikan, profit bulan berjalan, dan akumulasi profit; Multiguna menampilkan cicilan berikutnya dan jadwal terkait. Konten Home non-investor tidak menampilkan section investasi.
- Navbar investor: Beranda, Simpanan, Investasi, Multiguna, Profil. Navbar non-investor: Beranda, Simpanan, Multiguna, Profil dengan pill lebih compact.
- Aktivitas terakhir menampilkan lima aktivitas contoh.
- Pill navbar mengambang di atas konten dengan gradient putih di bagian bawah; konten tetap terlihat di belakang dan memiliki ruang scroll aman.
- Nilai ringkasan keuangan berasal dari `/app/summary`; data demo hanya menjadi fallback preview dan sumber sementara untuk Multiguna serta aktivitas terakhir.
- Tujuan fitur yang belum dibuat menampilkan feedback sementara dan tidak menjalankan transaksi.
