# Multiguna

Status: keputusan bisnis dashboard awal disepakati; konsep Pen Dev dibuat, belum menjadi PRD final.
Acuan: [konteks utama](../../../mobile_cooperative_investment_app_context.md) · [indeks PRD](../README.md).
Cakupan rilis: rilis pertama. Detail modul menunggu pembahasan.

## Pengguna dan kebutuhan

Pengguna: Anggota sesuai kelayakan backend.
Ruang lingkup awal: Pengajuan, nominal/tenor, estimasi cicilan dan total, status, detail pinjaman aktif, jadwal dan pembayaran, riwayat.

## Journey awal

Multiguna → pengajuan → review → status; Pinjaman aktif → cicilan → pembayaran manual → status.

## Keputusan yang disepakati

- Satu anggota dapat memiliki lebih dari satu pinjaman aktif selama limit masih tersedia.
- Nilai limit berasal dari backend. Dasarnya adalah gaji bulanan + total simpanan, tetapi frontend tidak menghitungnya.
- Tidak ada batas maksimal terpisah di frontend; nominal pengajuan mengikuti limit yang diberikan backend.
- Dana yang disetujui dicairkan ke rekening bank anggota yang tersimpan di backend/admin.
- Frontend menampilkan status pengajuan dan pencairan dari backend, termasuk diproses, disetujui, atau ditolak.
- Cicilan dapat dibayar beberapa periode sekaligus dan pinjaman dapat dilunasi lebih awal.
- Tidak ada denda keterlambatan. Cicilan menunggak tetap ditampilkan dengan status, ikon, teks, dan visual yang jelas.
- Detail field dan dokumen formulir pengajuan dibahas saat mendesain formulir.

## Struktur dashboard awal

- Hero: total sisa kewajiban seluruh kontrak, limit tersedia, jumlah pinjaman aktif, dan aksi pengajuan.
- Tagihan terdekat: nominal, kontrak, jatuh tempo, status, dan aksi pembayaran.
- Pengajuan aktif: nominal, tenor, tanggal, dan status backend.
- Daftar pinjaman aktif: kontrak, sisa kewajiban, progres pembayaran, cicilan, jatuh tempo, dan status.
- Dashboard harus mendukung beberapa kontrak sekaligus serta membedakan pinjaman normal dan menunggak tanpa bergantung pada warna saja.

## Dependensi

Pembayaran, Profil, Home, Riwayat, Notifikasi.

## Keputusan terbuka saat modul dibahas

Kelayakan detail; dokumen dan field formulir; field estimasi dari API; nama status aktual; biaya/margin; aturan pembayaran beberapa periode dan pelunasan lebih awal.

## Kelengkapan sebelum desain dan implementasi

- Tujuan modul dan user stories disepakati.
- Kebutuhan fungsional dan kriteria penerimaan dapat diverifikasi.
- Struktur informasi, alur utama/alternatif, dan inventaris layar disepakati.
- Loading, empty, error, pending, success, disabled, dan konfirmasi dipetakan sesuai aksi.
- Kebutuhan data dicatat; kontrak API aktual dipisahkan dari data contoh.
- Keputusan terbuka yang menghalangi alur diselesaikan bersama pengguna.
- Setelah desain/prototipe ditinjau, implementasi dan hasil verifikasi dicatat.

Belum ada desain, kontrak API, atau implementasi modul yang disetujui melalui file kerangka ini.
