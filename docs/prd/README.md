# PRD Modular — Basya Investama

Status: kerangka pembagian modul untuk ditinjau; bukan PRD final atau persetujuan desain.

## Acuan dan cara kerja

1. Baca [konteks utama](../../mobile_cooperative_investment_app_context.md), terutama keputusan terbaru.
2. Baca file modul yang sedang dikerjakan dan dependensinya saja.
3. Klarifikasi keputusan terbuka yang memengaruhi modul tersebut.
4. Lengkapi PRD dengan kebutuhan teruji, struktur informasi, user flow, inventaris layar, state, kebutuhan data API, dan kriteria penerimaan.
5. Sepakati modul, lanjutkan desain/prototipe, kemudian implementasi dan verifikasi modul itu.
6. Perbarui status modul dan keputusan lintas modul pada konteks utama sebelum berpindah.

Instruksi terbaru pengguna mengungguli dokumen. Konteks utama mengungguli draft modul. Perubahan aturan bisnis lintas modul harus disinkronkan, bukan diputuskan sepihak dalam implementasi.

Semua fitur termasuk cakupan rilis pertama. Nomor di bawah adalah usulan urutan kerja berdasarkan dependensi, bukan tahapan rilis yang mengecualikan fitur. Pilihan modul pertama belum dikunci.

## Daftar modul

| Modul | Status |
|---|---|
| [Autentikasi dan Profil](modules/01-auth-profile.md) | Kerangka; belum dibahas |
| [Home dan Ringkasan Keuangan](modules/02-home.md) | Kerangka; belum dibahas |
| [Transfer Manual dan Bukti Pembayaran](modules/03-payments.md) | Kerangka; belum dibahas |
| [Simpanan dan Simpanan Wajib](modules/04-simpanan-wajib.md) | Kerangka; belum dibahas |
| [Simpanan Sukarela](modules/05-simpanan-sukarela.md) | Kerangka; belum dibahas |
| [Buy Power dan Mutasi](modules/06-buy-power.md) | Kerangka; belum dibahas |
| [Investasi dan Portofolio](modules/07-investasi.md) | Kerangka; belum dibahas |
| [Multiguna](modules/08-multiguna.md) | Kerangka; belum dibahas |
| [Riwayat Transaksi Terpusat](modules/09-riwayat.md) | Kerangka; belum dibahas |
| [Notifikasi](modules/10-notifikasi.md) | Kerangka; belum dibahas |

## Aturan bersama

- Nilai, capability, status dan aturan finansial bersumber dari API; endpoint dan field yang belum diberikan tetap terbuka.
- Total Saldo tidak menghitung dana investasi aktif atau menambahkan metrik profit lagi.
- Semua pembayaran eksternal menggunakan transfer manual dan bukti pada form; bukan VA/QRIS/payment gateway.
- Pengiriman form berhasil harus dibedakan dari status transaksi finansial.
- Desain mencakup loading, kosong, error/API failure, pending, sukses, disabled, konfirmasi dan detail; pagination jika diperlukan.
- Gunakan data contoh yang jelas ditandai saat membuat prototipe; jangan menganggapnya kontrak API.
- Tidak perlu menuntaskan semua keputusan sebelum mulai mendalami satu modul.

## Temuan skill

Katalog resmi openai/skills yang diperiksa pada 12 September 2026 belum memuat skill PRD khusus.
Kandidat komunitas: [deliver-prd](https://github.com/product-on-purpose/pm-skills/blob/main/skills/deliver-prd/SKILL.md).
Skill tersebut menjelaskan penyusunan PRD dan acuan eksekusi agent, tetapi tidak menetapkan struktur satu konteks utama dengan file per modul secara otomatis. Struktur di folder ini merupakan pengaturan proyek. Skill belum diinstal atau dijadikan aturan proyek.

