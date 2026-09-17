# Investasi dan Portofolio

Status: keputusan bisnis awal disepakati; konsep dashboard Pen Dev dibuat, belum menjadi PRD final.
Acuan: [konteks utama](../../../mobile_cooperative_investment_app_context.md) · [indeks PRD](../README.md).
Cakupan rilis: rilis pertama. Detail modul menunggu pembahasan.

## Pengguna dan kebutuhan

Pengguna: Investor.
Ruang lingkup awal: Produk/detail, harga dan ketersediaan, beli dengan Buy Power, portofolio, jual, profit bulan ini dan akumulasi, performa.

## Journey awal

Produk → detail → jumlah → review → beli; Portofolio → posisi → jual → review → hasil ke Buy Power.

## Keputusan yang disepakati

- Produk investasi dibeli dan dijual dalam satuan lot.
- Pembelian: pilih produk → isi jumlah lot → review → kirim pengajuan → menunggu persetujuan admin.
- Penjualan pada prinsipnya dapat diajukan kapan saja, tetapi pencairannya tetap menunggu persetujuan admin.
- Hasil penjualan yang disetujui masuk ke Buy Power.
- Total Nilai Investasi merupakan Modal Aktif + Akumulasi Profit.
- Hero performa memakai bar chart bulanan. Grafik hanya menggunakan data historis yang diberikan backend.
- Frontend tidak menghitung atau menahan Buy Power. Saldo, dana tertahan bila tersedia, dan seluruh status pengajuan ditampilkan dari respons backend.
- Status transaksi harus tetap terlihat setelah submit; keberhasilan submit bukan persetujuan transaksi.

## Struktur dashboard awal

- Hero: Total Nilai Investasi, Modal Aktif, Profit Bulan Ini, Akumulasi Profit, dan performa bulanan.
- Buy Power: saldo tersedia serta aksi Top Up dan Mutasi ke Simpanan Sukarela.
- Pengajuan aktif: pembelian atau penjualan yang masih menunggu keputusan admin.
- Segmented content: Peluang dan Portofolio.
- Peluang: gambar, nama produk, lokasi/kategori, harga per lot, kuota, progres alokasi, dan akses ke detail.
- Portofolio: produk dimiliki, jumlah lot, modal, nilai saat ini, profit/loss, status, dan akses ke detail/penjualan.

## Dependensi

Buy Power, profile investor, Riwayat, Notifikasi.

## Keputusan terbuka saat modul dibahas

Jenis produk; unit/lot; harga eksekusi; status pengajuan; field nilai/modal/profit; periode profit; grafik/analitik lanjutan; waktu kredit.

## Kelengkapan sebelum desain dan implementasi

- Tujuan modul dan user stories disepakati.
- Kebutuhan fungsional dan kriteria penerimaan dapat diverifikasi.
- Struktur informasi, alur utama/alternatif, dan inventaris layar disepakati.
- Loading, empty, error, pending, success, disabled, dan konfirmasi dipetakan sesuai aksi.
- Kebutuhan data dicatat; kontrak API aktual dipisahkan dari data contoh.
- Keputusan terbuka yang menghalangi alur diselesaikan bersama pengguna.
- Setelah desain/prototipe ditinjau, implementasi dan hasil verifikasi dicatat.

Belum ada desain, kontrak API, atau implementasi modul yang disetujui melalui file kerangka ini.
