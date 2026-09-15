# Basya V2 — acuan implementasi Flutter

Pembaruan kontrol: CMP-03 dan tab selected CMP-24 memakai LinearGradient dengan colors #004E50, #006A66, #008579 dan stops [0, 0.5, 1]. CMP-23 memakai gradient ringan #EDF7F5 → #D5F3E9. Orientasi dicocokkan dengan rotasi Pen Dev 110°. Gunakan BoxDecoration.gradient dan Material transparan/Ink untuk feedback tap; disabled dan secondary tetap berbeda. Tidak memerlukan shader tambahan.

Status: spesifikasi implementasi dari canvas, bukan implementasi atau bukti uji runtime. Arah Home dan navigasi mengikuti keputusan pengguna 14 September 2026. Data dan endpoint tetap mengikuti PRD serta kontrak API.

## Komponen dan widget

| Komponen | Bentuk Flutter yang disarankan | Input |
|---|---|---|
| IntegratedBalanceHero / CMP-26 | Gradient DecoratedBox + identity row + frosted elevated BackdropFilter panels | member, totalSaldo, panel saldo sesuai audience, visibility, notifications |
| BasyaBalanceCard / CMP-21 | DecoratedBox + BoxDecoration + LinearGradient + Padding + Column | isInvestor, totalSaldo, totalSimpanan, sukarela, buyPower, visibility, loading/error |
| BalanceSubpanel / CMP-22 | Expanded + DecoratedBox + Column; investor memakai Simpanan Sukarela dan Buy Power, non-investor memakai Simpanan Sukarela dan Simpanan Wajib | label, amount, semanticDescription |
| MainContainer | Scaffold + IndexedStack; memiliki tab aktif dan floating bottom navigation agar state tiap halaman tetap tersimpan | audience, selectedIndex, destinations |
| HomeShortcut / CMP-23 | Material + InkWell + Column | icon, label, callback, enabled, loading |
| BasyaFloatingNav / CMP-24 | SafeArea + Padding + Row + AnimatedContainer/AnimatedSize | destinations, selectedIndex, onSelected |
| TopUpDestinationSheet / CMP-25 | showModalBottomSheet dengan SafeArea, pilihan dan callback | pilihan yang diizinkan, onSelected, dismiss |

Gradient dan bayangan merupakan dekorasi Flutter biasa; tidak membutuhkan shader khusus, glass blur, HTML atau gambar screenshot sebagai latar UI. Ikon Lucide harus dipetakan ke aset SVG atau pustaka Flutter yang diverifikasi saat implementasi; jangan mengasumsikan nama ikon sama dengan Material Icons.

Dokumentasi resmi yang diperiksa: [LinearGradient](https://api.flutter.dev/flutter/painting/LinearGradient-class.html), [AnimatedSize](https://api.flutter.dev/flutter/widgets/AnimatedSize-class.html), [SafeArea](https://api.flutter.dev/flutter/widgets/SafeArea-class.html).

## Dimensi dan penyesuaian

- Satuan canvas menjadi logical pixels sebagai titik awal, bukan ukuran yang dikunci untuk seluruh perangkat.
- Layar contoh 390 × 844. Konten horizontal inset 20; lebar 360 diuji secara visual di canvas.
- Kartu luar radius 28; inset 8; panel radius 20; panel padding 14. Teks panel 14, total utama 32. Gradient mengikuti token pada DESIGN.md.
- Shortcut tinggi 78 dengan ikon 22 dan label 12. Investor empat kolom, non-investor tiga. Pada text scale besar gunakan dua kolom atau tinggi adaptif; jangan memotong label.
- Nav tinggi isi 60: padding 6 dan item tinggi 48. Item aktif lebar awal 112, item lain membagi sisa ruang; tidak ada gap antaritem. Dengan lebar nav 320, empat item lain masing-masing 49.
- Navbar investor mengikuti lebar layar dengan inset 20; navbar non-investor memakai pill lebih compact dan tetap center karena hanya memiliki empat destinasi. Pada teks besar, ukur label aktual dan gunakan varian ikon-atas/label-bawah dengan tinggi adaptif bila kapsul tidak muat; jangan mengecilkan teks atau area sentuh untuk memaksakan animasi.
- Navbar memakai pill mengambang di atas konten dengan gradient scrim putih menuju gesture area. Scrim memakai `IgnorePointer`; hanya pill yang menerima input. Beri padding bawah pada konten agar baris terakhir dapat digulir sepenuhnya di atas pill.
- Hero saldo dipertahankan di atas sementara konten Home scroll pada viewport normal. Pada layar pendek atau text scale besar, gunakan satu scroll agar aksesibilitas tidak dikorbankan.
- Scroll Home memakai physics memantul ala iOS dan indikator overscroll glow dimatikan agar mentok atas/bawah terasa elastis.
- Konten setelah shortcut dipisahkan menjadi section Investasi Anda dan Multiguna. Multiguna memiliki header sendiri serta jarak inter-section lebih besar agar cicilan tidak terbaca sebagai metrik investasi.
- Jangan menyalin tinggi frame konten penuh sebagai tinggi layar Flutter. Frame viewport di canvas menunjukkan crop scroll yang disengaja.
- Nilai uang panjang: layout dapat membesar atau subpanel menjadi vertikal pada ruang sempit. Nilai tidak di-ellipsis. Nilai belum tersedia tidak ditampilkan sebagai nol. Visibilitas disamarkan konsisten pada seluruh nominal sensitif.

## Navigasi dan route intents

Nama di bawah adalah intent, bukan endpoint atau path router final.

| Pemicu | Tujuan |
|---|---|
| Top Up non-investor | form setoran Sukarela |
| Top Up investor | sheet pilihan → form Sukarela atau form Buy Power |
| Withdraw | form tarik Simpanan Sukarela |
| Pinjam | form pengajuan Multiguna |
| Mutasi investor | form Buy Power → Sukarela |
| Tab Investasi investor | halaman investasi dengan Produk dan Portofolio |
| Lihat jadwal Multiguna | jadwal cicilan Multiguna |
| Lihat semua aktivitas | riwayat transaksi terpusat |

Tidak ada shortcut Invest. Non-investor: Beranda, Simpanan, Multiguna, Profil. Investor: Beranda, Simpanan, Investasi, Multiguna, Profil.

Sheet ditutup setelah tujuan dipilih; tombol back/dismiss tidak mengirim transaksi. Tujuan diteruskan sebagai argumen bertipe agar form tidak menebak asal dana. Semua pembayaran tetap transfer manual dengan upload bukti.

## State dan animasi

- Tap tab mengubah tab aktif dan menampilkan labelnya; label tetap terlihat hingga tab lain dipilih. Ini bukan hover sementara.
- Usulan transisi lebar/label 150 ms, Cubic(0.2, 0, 0, 1); transisi dapat dibalik saat pengguna mengetuk cepat. Ikon tab tidak perlu blur atau animasi dekoratif.
- Reduced motion: ubah selected state langsung tanpa animasi. Tidak ada entrance animation pada pemuatan awal.
- Setiap tab memiliki Semantics label dan selected, juga Tooltip untuk kontrol ikon. Fokus keyboard dan indikator fokus disediakan bila platform mendukungnya.
- Saldo: loaded, hidden, loading skeleton, error dengan retry. Shortcut: enabled/disabled sesuai capability; form sedang dikirim mencegah submit ganda. Navbar selected state tidak bergantung hanya pada gerak.
- State loading/error/hidden kartu belum seluruhnya digambar di canvas V2. Lengkapi saat modul Home dibahas; jangan menganggap spesifikasi sebagai bukti state sudah diuji.

## Checklist sebelum frontend dinyatakan selesai

- Cocokkan screenshot Flutter dengan frame V2 pada 390 dan 360, serta layar lebih lebar.
- Uji text scale besar, nominal panjang, semua lima tab, tap cepat, back, sheet dismiss, keyboard, dan safe area Android/iOS.
- Uji screen reader untuk tab tanpa label visual, tombol visibilitas saldo, dan fokus sheet.
- Pastikan data investasi aktif/profit tidak ditambahkan ke Total Saldo; mutasi internal tidak dihitung sebagai pendapatan.
- Verifikasi contrast pada hasil render gradient aktual, bukan hanya pasangan warna token.
- Profilkan animasi pada perangkat; pemeriksaan dokumen ini belum membuktikan performa atau kesamaan piksel Flutter.
