# Project Context — Mobile Cooperative & Investment App

## Keputusan terbaru — 12 September 2026

Bagian ini adalah acuan utama apabila uraian awal di bawah berbeda. Keputusan eksplisit pengguna berikutnya dapat memperbaruinya. Dokumen per modul mengacu ke file ini, bukan menggandakan aturan global.

- Rilis pertama mencakup semua fitur. Label P0/P1/P2 di uraian awal menunjukkan pengelompokan prioritas, bukan persetujuan untuk mengecualikan fitur dari rilis pertama. Detail fitur lanjutan tetap dirinci saat modul terkait dibahas.
- Akun: pengguna menyatakan "akun disediakan sendiri". Pihak pembuat akun dan kebutuhan registrasi belum diperjelas; tentukan saat membahas autentikasi.
- Status investor ditentukan backend melalui salah satu key API profile saat login. Nama key dan nilai pembeda menunggu kontrak API. UI investasi mengikuti status tersebut.
- Profit dan pendapatan investasi adalah hal yang sama. Tampilkan **Profit Bulan Ini** dan **Total Akumulasi Profit**, bukan dua jenis keuntungan yang berbeda. Definisi periode dan field API dirinci pada modul investasi.
- Hasil penjualan investasi dan pembagian pendapatan masuk ke **Buy Power**. Buy Power dapat dimutasi ke **Simpanan Sukarela**, kemudian ditarik melalui alur withdrawal Simpanan Sukarela. Jangan mengasumsikan mutasi arah sebaliknya atau withdrawal langsung dari Buy Power.
- Profit sebagai metrik tidak ditambahkan lagi ke Total Saldo. Hasil yang sudah dikreditkan ke Buy Power sudah tercakup dalam komponen Buy Power.
- Nominal Simpanan Wajib tetap dan bersumber dari API. Aturan periode, tunggakan, pembayaran beberapa bulan, dan pembayaran di muka belum diputuskan.
- Metode pembayaran hanya **transfer manual dengan upload bukti pada form**. Status finansial mengikuti API; keberhasilan upload/pengiriman form tidak otomatis berarti pembayaran sudah disahkan.
- Kerjakan satu modul per satu. Detail bisnis yang belum diputuskan dibahas ketika modul terkait dikerjakan, bukan dianggap sebagai aturan final.
- Tahapan PRD → struktur informasi → user flow → inventaris layar → desain → prototipe → implementasi diterapkan per modul, dengan konteks dan konsistensi lintas modul tetap dijaga.

Peta dokumen dan modul: [docs/prd/README.md](docs/prd/README.md).

### Klarifikasi hasil desain

Keputusan 14 September 2026: Home investor memiliki shortcut Top Up, Withdraw, Pinjam, Mutasi. Tidak ada shortcut Invest; Investasi tetap destinasi tengah navbar. Top Up investor membuka pilihan Simpanan Sukarela / Buy Power sebelum formulir. Non-investor memiliki Top Up (Sukarela), Withdraw, Pinjam. Withdraw mengarah ke formulir penarikan Sukarela; Pinjam ke pengajuan; Mutasi dari Buy Power ke Sukarela. Halaman Investasi menyediakan akses Produk dan Portofolio.

Kartu Total Saldo V2 memakai gradient Basya. Investor memiliki panel Total Simpanan dan Buy Power di dalam kartu. Non-investor memiliki satu panel Sukarela sebagai bagian total, bukan saldo tambahan. Navbar mengambang pada tema putih; hanya tab aktif memperlihatkan judul. Semua tab tetap memiliki ikon dan label aksesibilitas. Spesifikasi implementasi: [docs/design/flutter-handoff.md](docs/design/flutter-handoff.md).

Koreksi pengguna 13 September 2026: bottom navigation investor terdiri dari **Beranda, Simpanan, Investasi, Multiguna, Profil**. Investasi berada di posisi tengah, dan posisi Riwayat diganti Multiguna. Riwayat transaksi tetap diperlukan; akses dari aktivitas Home tersedia pada eksplorasi. Navigasi non-investor tidak berubah.

Pengguna hanya memerlukan seluruh desain screen untuk dilihat pada canvas Pen Dev. HTML dan simulasi interaktif bukan hasil yang diperlukan pada tahap ini. Usulan arah visual berada di [docs/design/DESIGN.md](docs/design/DESIGN.md), dengan katalog komponen di [docs/design/components.md](docs/design/components.md); keduanya masih draft untuk ditinjau. Dokumen Stitch di docs/prd/DESIGN.md tetap menjadi referensi pembanding.

---

## 1. Gambaran Produk

Kami sedang merancang sebuah **aplikasi mobile untuk anggota koperasi**, dengan dua tipe utama pengguna:

1. **Anggota Non-Investor**
2. **Anggota Investor**

Aplikasi digunakan untuk mengelola keuangan keanggotaan koperasi, simpanan, investasi, serta fasilitas pinjaman multiguna.

Fokus saat ini adalah **UI/UX mobile application**. Detail implementasi backend belum menjadi fokus desain; nantinya frontend akan menggunakan endpoint API yang disediakan oleh backend.

---

## 2. Struktur Keuangan Anggota

### Anggota Non-Investor

Saldo anggota terdiri dari:

- **Simpanan Pokok** — dibayarkan ketika pertama kali menjadi anggota. Tidak perlu memiliki halaman transaksi khusus.
- **Simpanan Wajib** — iuran bulanan anggota.
- **Simpanan Sukarela** — simpanan bebas yang dapat disetor kapan saja dan nantinya dapat ditarik/withdraw.

### Anggota Investor

Anggota investor memiliki seluruh komponen anggota biasa:

- Simpanan Pokok
- Simpanan Wajib
- Simpanan Sukarela

Ditambah:

- **Buy Power**
- **Dana yang sedang diinvestasikan**
- **Pendapatan/hasil investasi**
- **Profit investasi**

---

## 3. Konsep Total Saldo

**Total Saldo tidak sama dengan total seluruh kekayaan anggota.**

### Non-Investor

> Total Saldo = Simpanan Pokok + Simpanan Wajib + Simpanan Sukarela

### Investor

> Total Saldo = Simpanan Pokok + Simpanan Wajib + Simpanan Sukarela + Buy Power

Sedangkan:

- Dana yang sedang diinvestasikan **tidak dimasukkan ke Total Saldo**
- Profit investasi ditampilkan terpisah
- Pendapatan/hasil investasi ditampilkan terpisah

Dashboard harus membedakan:

**Saldo yang tersedia/tersimpan** vs. **Dana yang sedang diinvestasikan** vs. **Hasil investasi**

---

## 4. Dashboard / Home

Dashboard adalah halaman utama aplikasi.

Tujuannya memberikan **financial overview yang mudah dipahami**, bukan menampilkan semua informasi sekaligus.

### Semua anggota

- Total Saldo
- Simpanan Pokok
- Simpanan Wajib
- Simpanan Sukarela

### Investor

Tambahkan:

- Buy Power
- Dana Aktif Diinvestasikan
- Profit
- Pendapatan/hasil investasi

Hierarki visual yang disarankan:

**Total Saldo → saldo tersedia → investasi → performa investasi**

Jangan membuat semua angka memiliki tingkat kepentingan visual yang sama.

---

## 5. Simpanan Pokok

Simpanan Pokok **tidak perlu dibuat sebagai fitur/halaman transaksi tersendiri** karena berkaitan dengan proses awal keanggotaan dan bukan aktivitas finansial rutin.

Informasinya cukup ditampilkan sebagai bagian dari saldo/rekap keuangan anggota.

---

## 6. Simpanan Wajib

Simpanan Wajib merupakan **iuran bulanan anggota**.

Fitur:

- Melihat kewajiban iuran
- Melakukan pembayaran/setoran
- Melihat status pembayaran
- Melihat riwayat pembayaran

Flow sederhana:

**Nominal → periode/bulan → metode pembayaran → konfirmasi**

---

## 7. Simpanan Sukarela

Simpanan Sukarela adalah saldo yang dapat digunakan anggota secara fleksibel.

### Setor / Top Up

- Pilih Simpanan Sukarela
- Masukkan nominal
- Pilih metode pembayaran
- Buat pembayaran
- Lihat status transaksi

### Withdraw

- Lihat saldo Simpanan Sukarela
- Pilih Tarik Dana
- Masukkan nominal
- Pilih rekening/tujuan dana
- Konfirmasi
- Lihat status withdrawal

### Riwayat

- Setoran
- Penarikan
- Status transaksi
- Tanggal
- Nominal
- Reference/transaction ID bila diperlukan

> **Simpanan Sukarela harus terasa seperti saldo yang benar-benar dapat digunakan anggota, bukan sekadar angka laporan.**

---

## 8. Buy Power

Buy Power hanya relevan untuk anggota investor.

Buy Power adalah **saldo yang digunakan untuk membeli produk investasi**.

Flow:

**Top Up → Buy Power bertambah → pilih produk investasi → beli investasi → Buy Power berkurang**

Fitur:

- Melihat saldo Buy Power
- Top Up Buy Power
- Melihat riwayat Top Up
- Melihat transaksi penggunaan Buy Power

Buy Power harus dibedakan secara visual dari Simpanan Sukarela karena fungsi keduanya berbeda.

---

## 9. Investasi

### Explore / Produk Investasi

- Daftar produk investasi
- Informasi dasar produk
- Harga/nilai per unit
- Informasi ketersediaan
- Informasi return/performa jika tersedia

### Pembelian

**Pilih produk → lihat detail → tentukan jumlah → review → konfirmasi pembelian**

### Portofolio

- Produk yang dimiliki
- Jumlah/unit/lot
- Nilai investasi
- Modal
- Profit/loss
- Performa investasi

### Penjualan

**Pilih investasi → Jual → tentukan jumlah → review → konfirmasi**

Nilai hasil penjualan mengikuti mekanisme finansial yang diberikan backend.

---

## 10. Profit & Performa Investasi

Profit tidak boleh dicampur dengan saldo kas.

Investor harus dapat memahami:

> "Berapa uang saya yang tersedia?"

> "Berapa uang saya yang sedang diinvestasikan?"

> "Berapa keuntungan investasi saya?"

Ketiganya harus memiliki representasi UI berbeda.

Contoh:

**Total Saldo**  
Rp xxx.xxx.xxx

**Dana Diinvestasikan**  
Rp xxx.xxx.xxx

**Profit**  
+Rp xx.xxx.xxx

Jika data historis tersedia, dapat ditambahkan grafik performa investasi.

---

## 11. Multiguna / Pinjaman

**Multiguna** adalah fasilitas pinjaman kepada anggota koperasi.

### Pengajuan

- Melihat fasilitas Multiguna
- Mengajukan pinjaman
- Memasukkan nominal
- Memilih tenor/cicilan
- Melihat estimasi cicilan
- Melihat total pembayaran
- Mengajukan pinjaman

### Status Pengajuan

Contoh status:

- Draft
- Diajukan
- Dalam proses
- Disetujui
- Ditolak
- Aktif
- Lunas

Status aktual mengikuti API/backend.

### Pinjaman Aktif

- Sisa pokok
- Sisa margin/bunga/biaya sesuai model bisnis
- Total outstanding
- Cicilan per bulan
- Cicilan berikutnya
- Jatuh tempo
- Riwayat pembayaran

### Pembayaran Cicilan

Anggota dapat melihat dan melakukan pembayaran cicilan.

---

## 12. Dashboard Multiguna

Jika anggota memiliki pinjaman aktif, dashboard dapat menampilkan **financial obligation** secara ringkas.

Contoh:

**Pinjaman Aktif**  
Rp 3.208.333 tersisa

**Cicilan berikutnya**  
Rp 344.167

**Jatuh tempo**  
XX September 2026

Tujuannya agar anggota tidak perlu masuk terlalu dalam ke halaman Multiguna hanya untuk mengetahui kewajiban terdekat.

---

## 13. Transaksi & Riwayat

Aplikasi membutuhkan **riwayat transaksi terpusat**.

Transaksi dapat berasal dari:

- Simpanan Wajib
- Simpanan Sukarela
- Withdrawal Simpanan Sukarela
- Top Up Buy Power
- Pembelian investasi
- Penjualan investasi
- Pembayaran pinjaman
- Pencairan/penerimaan pinjaman

Setiap transaksi idealnya memiliki:

- Tanggal
- Jenis transaksi
- Nominal
- Status
- Reference
- Detail transaksi

Gunakan filter berdasarkan jenis transaksi bila jumlah transaksi cukup banyak.

---

## 14. Notifikasi

Notification center diperlukan untuk:

- Pembayaran berhasil
- Top Up berhasil
- Investasi berhasil dibeli
- Investasi berhasil dijual
- Status pengajuan investasi
- Status pengajuan Multiguna
- Cicilan mendekati jatuh tempo
- Pembayaran cicilan berhasil
- Withdrawal berhasil/gagal
- Informasi penting dari koperasi

Notifikasi yang berkaitan dengan action sebaiknya dapat membawa user langsung ke halaman terkait.

---

## 15. Profil Anggota

Profil minimal:

- Nama
- Foto/avatar
- Nomor anggota
- Nomor identitas bila diperlukan
- Nomor HP
- Email
- Informasi rekening
- Data keanggotaan

Fungsi:

- Edit profil
- Pengaturan keamanan
- PIN/password
- Logout

Data sensitif tidak perlu ditampilkan berlebihan di dashboard.

---

## 16. Experience Non-Investor vs Investor

Jangan membuat dua aplikasi berbeda.

Gunakan **satu aplikasi dengan progressive disclosure**.

### Non-Investor

Menu utama dapat berfokus pada:

- Home
- Simpanan
- Multiguna
- Riwayat
- Profil

### Investor

Tambahkan:

- Investasi

User non-investor tidak perlu dibebani fitur investasi yang belum relevan.

Jika status investor berasal dari API/account capability, UI dapat menampilkan fitur investasi secara conditional.

---

## 17. Prinsip UX Utama

Desain harus terasa seperti **mobile financial application**, bukan aplikasi administrasi koperasi.

Prioritas:

1. Financial information mudah dipahami
2. Saldo tersedia mudah ditemukan
3. Action utama jelas
4. Transaksi finansial memiliki confirmation step
5. Status transaksi sangat jelas
6. Investor dan non-investor mendapatkan experience yang relevan
7. Informasi kompleks menggunakan progressive disclosure
8. Jangan membanjiri dashboard dengan terlalu banyak angka
9. Setiap transaksi memiliki feedback yang jelas
10. Desain siap menerima data dinamis dari API

---

## 18. Scope UI/UX

Fokus proyek adalah **frontend/mobile UI & UX**.

Backend, database, accounting logic, dan business rules detail akan disediakan melalui API.

Desain harus mempertimbangkan:

- Dynamic data
- Loading state
- Empty state
- Error state
- Success state
- Pending state
- Disabled state
- API failure
- Confirmation modal/screen
- Transaction detail
- Pagination/infinite scrolling bila diperlukan

Untuk fitur finansial, **status state harus menjadi bagian dari desain sejak awal**, bukan ditambahkan belakangan.

---

## 19. Prioritas MVP

### P0 — Core

- Login/authentication
- Home/dashboard
- Profile
- Simpanan
- Simpanan Wajib
- Simpanan Sukarela
- Top Up
- Transaction history
- Notifications

### P1 — Investment

- Investment dashboard
- Product list
- Product detail
- Buy
- Portfolio
- Sell
- Buy Power
- Investment transaction history
- Profit/performance

### P1 — Multiguna

- Loan dashboard
- Loan application
- Loan detail
- Installment information
- Payment
- Loan history/status

### P2

- Advanced analytics
- Advanced investment charts
- Additional financial insights
- Additional convenience features

---

## 20. Batasan Konteks

Project ini harus dipahami sebagai:

> **Aplikasi mobile koperasi + investment platform untuk anggota koperasi.**

Sistem harus dirancang berdasarkan **kebutuhan bisnis dan UX yang dijelaskan di atas**.

Tujuan desain adalah menghasilkan pengalaman mobile yang sederhana, modern, dan user-oriented.

---

# Starting Point untuk Design Phase

Jangan langsung coding.

Urutan kerja:

**Project Context → PRD → Information Architecture → User Flow → UX Wireframe → UI Design → Design System → Prototype → Frontend Implementation**

Seluruh screen sebaiknya diturunkan dari **user journey**, bukan dari daftar menu semata.

## Core User Journeys

1. **Login → Home → melihat kondisi keuangan**
2. **Home → Simpanan Sukarela → Setor**
3. **Home → Simpanan Sukarela → Withdraw**
4. **Home → Simpanan Wajib → Bayar iuran**
5. **Home → Investasi → pilih produk → beli**
6. **Home → Investasi → Portfolio → jual**
7. **Home → Buy Power → Top Up**
8. **Home → Multiguna → Ajukan pinjaman**
9. **Home → Multiguna → lihat cicilan → bayar**
10. **Home → Riwayat → lihat detail transaksi**

## Next Step

Gunakan context ini sebagai **single source of truth** untuk menyusun PRD dan Information Architecture.

Jangan langsung mengimplementasikan UI sebelum:

1. PRD disepakati
2. Struktur informasi ditentukan
3. User flow utama dipetakan
4. Screen inventory ditentukan
5. Prioritas MVP dikonfirmasi

Setelah itu baru masuk ke UX/UI design dan prototyping.
