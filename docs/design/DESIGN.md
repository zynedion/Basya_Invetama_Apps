# Basya — arah desain mobile

### Gradient kontrol — pembaruan 14 September 2026

Tombol utama CMP-03 dan kapsul tab aktif CMP-24 memakai gradient linear #004E50 → #006A66 → #008579, stops 0 / 0.5 / 1, rotasi Pen Dev 110°. Teks dan ikon putih. Kontras putih pada stop paling terang sekitar 4.53:1; periksa kembali pada render Flutter. Mint terang tidak ditempatkan di belakang label putih. Shortcut CMP-23 memakai gradient ringan #EDF7F5 → #D5F3E9 dengan teks gelap dan ikon teal. Secondary, disabled, dan tab tidak aktif mempertahankan pembedaan visualnya.

## Arah V2 — 14 September 2026

Ini adalah acuan saldo dan navigasi aktif. Gunakan gradient kartu dari #004E50 → #006A66 → #08A39E → #5FDEA9, dengan bagian gelap di belakang teks putih dan mint di tepi bawah. Stops: 0, 0.55, 0.82, 1; sudut Pen Dev 145 derajat, orientasi Flutter dicocokkan secara visual karena konvensi koordinat berbeda. Panel putih solid di dalam kartu menjaga keterbacaan angka.

Kartu luar radius 28, inset 8, subpanel radius 20. Panel nominal 14 semibold/bold agar contoh nominal tetap utuh pada lebar 360; nominal Total Saldo 32 bold. Layar putih, daftar simpanan dan bagian investasi memakai layout terbuka; hanya kewajiban terdekat memakai permukaan aksen. Buy Power tidak diulang sebagai kartu terpisah di bawah saldo.

Navbar putih mengambang dengan shadow #17324A18 (offset 0,6; blur 24) dan backdrop gradasi putih transparan → #EDF7F5 → putih. Tab terpilih berupa kapsul teal dengan ikon dan judul. Tab lain ikon saja; judul tetap tersedia secara semantik. Detail widget, state, ukuran dan batas verifikasi ada di [flutter-handoff.md](flutter-handoff.md).

Status: usulan untuk ditinjau, belum ditetapkan sebagai desain final.
Acuan bisnis: [konteks utama](../../mobile_cooperative_investment_app_context.md).
Referensi awal: [desain Stitch](../prd/DESIGN.md). Aturan komponen: [components.md](components.md).

## Tujuan dan hasil

Seluruh layar dan variasi state yang diperlukan ditampilkan sebagai frame yang dapat ditinjau di canvas Pen Dev. HTML dan prototipe interaktif bukan deliverable yang diperlukan saat ini. Desain dilakukan per modul setelah kebutuhan modul disepakati.

## Karakter visual

Aplikasi keuangan anggota yang terang, tenang, ramah, dan mudah dibaca. Pertahankan teal–mint logo Basya, tipografi Plus Jakarta Sans, serta sudut membulat. Utamakan nominal, tujuan transaksi, dan status yang jelas. Gunakan ruang kosong dan pengelompokan untuk membentuk hierarki.

Logo lengkap digunakan pada pembuka/autentikasi; simbol dapat digunakan ketika ruang sempit. Gunakan aset asli dengan rasio terjaga, tanpa menggambar ulang atau mengubah warna. Warna UI di bawah adalah usulan turunan, bukan hasil ekstraksi warna resmi logo.

## Token warna tunggal

| Token | Nilai | Peran |
|---|---|---|
| canvas | #F5F7F9 | Latar layar |
| surface | #FFFFFF | Permukaan utama |
| surface-soft | #EDF7F5 | Kelompok informasi ringan |
| text-primary | #17324A | Judul dan nominal |
| text-secondary | #5F6B76 | Label dan informasi pendukung |
| border | #E2E8F0 | Pemisah dekoratif |
| border-input | #6D7A78 | Batas field yang perlu dikenali |
| action-primary | #006A66 | Tombol utama dan elemen aktif |
| action-pressed | #00504D | Tombol ditekan |
| on-action | #FFFFFF | Teks tombol utama |
| brand-teal | #08A39E | Aksen merek |
| brand-mint | #5FDEA9 | Aksen lembut |
| success-text | #166534 | Status berhasil |
| success-surface | #ECFDF5 | Latar status berhasil |
| pending-text | #92400E | Status menunggu |
| pending-surface | #FFFBEB | Latar status menunggu |
| error-text | #B42318 | Gagal, invalid, kerugian |
| error-surface | #FEF2F2 | Latar error |
| info-text | #1D4ED8 | Informasi |
| info-surface | #EFF6FF | Latar informasi |

Jangan memperkenalkan hex lokal per layar. Tambahkan kebutuhan baru ke token bersama terlebih dahulu. Warna status harus disertai label/ikon; warna merek bukan indikator transaksi berhasil.

## Saldo dan aksen

Kartu Total Saldo memakai gradient dan subpanel sesuai acuan aktif di atas. Rincian simpanan, investasi dan transaksi menggunakan permukaan putih dengan layout terbuka.

Perhitungan kontras pasangan warna solid: putih/#08A39E sekitar 3,11:1; putih/#5FDEA9 sekitar 1,68:1; putih/#006A66 sekitar 6,45:1. Ini pemeriksaan pasangan warna, bukan sertifikasi aksesibilitas seluruh desain. Teks pada gradient, opacity, dan gambar tetap perlu diperiksa setelah dirender.

## Tipografi dan ukuran

Font: Plus Jakarta Sans. Jika belum tersedia di Pen Dev, verifikasi penggantinya sebelum membuat seluruh layar.

| Peran | Ukuran/line height | Weight |
|---|---|---|
| Saldo utama | 32/40 | 700 |
| Nominal sekunder | 24/32 | 700 |
| Judul layar | 22/28 | 700 |
| Judul bagian | 18/24 | 600 |
| Body dan field | 16/24 | 400 |
| Tombol | 16/24 | 600 |
| Detail pendukung | 14/20 | 400 |
| Label ringkas | 12/16 | 600 |

Gunakan angka tabular jika tersedia. Nominal harus diuji dengan angka panjang; jangan memotong angka uang dengan ellipsis atau mengecilkannya menjadi sulit dibaca. Format contoh: Rp 12.500.000; desimal mengikuti kebutuhan API. Jangan menyamakan nilai belum dimuat dengan Rp 0.

## Layout, bentuk, dan kedalaman

- Frame awal 390 × 844 sebagai ukuran review; periksa layar padat juga pada lebar 360. Ukuran ini usulan desain, bukan batas perangkat.
- Margin horizontal 20; pada frame 360 gunakan 16. Spasi dasar 4, 8, 12, 16, 20, 24, 32.
- Radius: field/tombol 12; kartu 16; sheet 24 pada sudut atas; badge pill.
- Area sentuh kontrol minimum desain 48 × 48; ikon umumnya 24. Label transaksi dan informasi penting tidak menggunakan caption 11px.
- Satu aksi utama per konteks. Area aksi dan navigasi memperhitungkan safe area dan tidak menutupi isi.
- Kartu biasa cukup border atau perbedaan permukaan. Shadow ringan dibatasi pada elemen mengambang. Glass/blur bukan syarat navigasi atau modal.
- Gunakan satu keluarga ikon yang tersedia di Pen Dev, lalu dokumentasikan pilihannya pada components.md.

## Hierarki finansial wajib

1. Total Saldo: Pokok + Wajib + Sukarela, ditambah Buy Power untuk investor.
2. Komponen simpanan dan dana yang dapat digunakan memiliki label eksplisit; Total Saldo bukan saldo bebas tarik.
3. Dana Diinvestasikan terpisah dari Total Saldo.
4. Profit Bulan Ini dan Total Akumulasi Profit adalah dua periode dari metrik yang sama.
5. Kewajiban pinjaman terdekat ditampilkan ringkas tanpa mendominasi seluruh Home.

Hindari label "Total Simpanan & Investasi" untuk Total Saldo. Jangan menambahkan klaim yield tetap atau persentase contoh seolah merupakan janji produk. Grafik hanya memakai data contoh yang ditandai atau data API yang tersedia.

## Navigasi dan makna transaksi

Investor: Beranda, Simpanan, Investasi, Multiguna, Profil. Non-investor: Beranda, Simpanan, Multiguna, Profil. Navbar aktif mengikuti CMP-24.

Transaksi keluar normal seperti cicilan atau penarikan menggunakan nominal netral dengan tanda/label arah. Merah untuk error, kerugian, atau kondisi yang membutuhkan perhatian. Mutasi Buy Power ke Sukarela adalah perpindahan internal, bukan profit baru.

## Peninjauan di canvas

Kelompokkan board Foundations, Components, lalu modul. Beri frame ID stabil seperti AUTH-01 / Default atau PAY-03 / Pending. Layar panjang mendapat frame konten lengkap; sheet, keyboard, error, dan konfirmasi mendapat variasi yang dapat dilihat secara terpisah jika relevan.

Sebelum memperluas desain, tinjau login, Home non-investor, dan Home investor untuk menilai arah visual. Tidak perlu menyelesaikan PRD modul lain untuk menguji arah ini, tetapi layar tersebut tetap berstatus eksplorasi sampai kebutuhan disepakati.

## Belum diputuskan

Keluarga ikon Lucide dan susunan tab mengikuti komponen aktif. Dukungan dark mode, perangkat tambahan dan detail modul masih ditentukan bertahap. Jangan menganggap usulan visual sebagai aturan bisnis baru.
