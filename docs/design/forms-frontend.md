# Form 16–24 — frontend lokal

Implementasi 26 September 2026 mengikuti frame aktif `basya_ui_canvas.pen` melalui MCP Pen Dev. Seluruh GET/POST dan mutasi data akun ditunda sesuai arahan pengguna. Form baru tidak melakukan request API. Integrasi yang sudah ada pada dashboard dan autentikasi tidak diubah.

## Halaman dan akses

| Frame | Halaman | Akses |
|---|---|---|
| 16 / ET3xX | Top Up Sukarela | Home → Top Up; Simpanan → Top Up |
| 17 / iVFKB | Top Up Buy Power | Home investor → Top Up → Buy Power; Investasi → Top Up |
| 18 / P1ctP | Bayar Simpanan Wajib | Simpanan → Bayar |
| 19 / L4i227 | Withdraw Sukarela | Home / Simpanan → Withdraw |
| 20 / Xawq5 | Mutasi Buy Power | Home → Mutasi; Investasi → Mutasi ke Sukarela |
| 21 / VCGzg | Bayar Cicilan | Multiguna → Bayar cicilan, dengan konteks kontrak |
| 22 / C66Fv | Pengajuan Multiguna | Home → Pinjam; Multiguna → Ajukan Multiguna |
| 23 / Fm6AU | Edit Profil | Profil → Edit profil |
| 24 / DxsIi | Ganti Password | Profil → Ganti password |

Home non-investor langsung membuka Top Up Sukarela. Home investor membuka pemilih tujuan. Form memakai route tersendiri sehingga navbar dashboard tidak menutupi isian. Keluar dengan isian berubah meminta konfirmasi; membatalkan review mempertahankan isian dan berkas.

## Struktur kode

- `lib/features/forms/domain/form_preview.dart`: jenis form, fixture demo, formatter rupiah.
- `lib/features/forms/presentation/basya_form_page.dart`: sembilan form dan validasi lokal, review, hasil demo.
- `lib/features/forms/presentation/form_widgets.dart`: pemilih tanggal/pilihan, upload berkas, nilai readonly, informasi, ringkasan review.
- `lib/features/forms/presentation/form_routes.dart`: route form dan pemilih tujuan Top Up.
- `BasyaActionButton`: tetap memakai gaya yang sudah ada, dengan dukungan keyboard, fokus, loading, pengurangan animasi, dan ukuran label khusus form.

## Penyesuaian canvas

- Plus Jakarta Sans, Material Icons, latar `AppTheme.loginCanvas`, warna dan radius bersama dipertahankan.
- Input 16 logical pixels; label dan catatan 12–14; nominal utama 26. Tinggi mengikuti isi, bukan tinggi frame canvas.
- Lebar konten maksimum 560; inset 20 atau 16 pada layar sempit. Semua form dapat digulir saat keyboard terbuka.
- Border input menggunakan `AppTheme.inputBorder`; readonly memakai permukaan abu-hijau yang berbeda dari field editable.
- Karena metode yang tersedia hanya transfer manual, metode tampil sebagai informasi tetap, bukan dropdown dengan satu pilihan.
- Simpanan Wajib memiliki periode bulan/tahun dan nominal readonly contoh.
- Tombol transaksi membuka review dahulu; konfirmasi akhir jelas berlabel demo.

## Perilaku demo

- Tidak ada transaksi, perubahan profil/password, atau perubahan saldo yang dikirim maupun disimpan permanen.
- Mode demo diberi label pada form dan review. Hasil akhir menyatakan pratinjau selesai, bukan pembayaran disahkan.
- Saldo, limit, rekening koperasi, nominal Wajib, pilihan tenor dan aturan validasi merupakan fixture lokal. Data profil/kontrak yang sudah diteruskan oleh halaman asal dapat digunakan tanpa GET baru.
- Simulasi Multiguna memakai plafon = harga − uang muka, margin contoh 10%, administrasi contoh Rp 50.000, dan estimasi cicilan dibulatkan ke atas. Ini hanya demonstrasi interaksi, bukan aturan produk atau penawaran.
- Validasi nominal positif, saldo/limit contoh, email, telepon, rekening, kelengkapan form, serta kecocokan password berjalan lokal. Password demo minimal 8 karakter; tidak ditampilkan di review dan tidak disimpan ke storage/log.
- Bukti: JPG/JPEG/PNG/PDF maksimal 5 MB. Foto: JPG/JPEG/PNG maksimal 5 MB. Akad: PDF maksimal 10 MB. Batas ini mengikuti pratinjau dan harus diselaraskan kembali saat integrasi.
- Pemilih berkas memakai [`file_selector`](https://pub.dev/packages/file_selector). Berkas dibaca lokal, dapat diganti/dihapus; gambar mendapat pratinjau, PDF ditampilkan sebagai nama/ukuran. Membatalkan pemilih mempertahankan berkas sebelumnya. Tidak ada upload jaringan. Jalankan ulang aplikasi sepenuhnya setelah memasang dependency native baru. Sandbox macOS diberi akses baca hanya untuk berkas yang dipilih pengguna.

## Integrasi berikutnya

Ganti fixture dengan kontrak resmi per modul: pilihan rekening, nominal/periode Wajib, saldo yang dapat ditarik/dimutasi, pembagian pembayaran cicilan, data identitas/alamat, pilihan pembiayaan/tenor, simulasi, dokumen wajib, aturan password dan respons submit. Status sukses finansial harus mengikuti backend, bukan hasil pemilih berkas atau validasi lokal.

## Verifikasi

Widget test berada di `test/features/forms/form_flow_test.dart`: sembilan layout, teks 200% pada lebar 320, keyboard pada lebar 360, route dari dashboard, validasi nominal/password, berkas lokal, simulasi, review dan pembatalan. Capture render opsional: `flutter test test/features/forms/form_flow_test.dart --dart-define=CAPTURE_FORM_PREVIEWS=true`, hasil di `.dart_tool/form-previews/` (tidak dikomit).

Pemilih berkas OS/browser nyata dan screen reader perangkat tetap perlu diuji pada perangkat target. Widget test memakai pemilih berkas terkontrol. Pengujian frontend tidak membuktikan integrasi API.

Hasil verifikasi 26 September 2026: seluruh 74 test proyek lulus; analyzer terfokus pada form, komponen bersama, dan test yang diperbarui melaporkan `No issues found`. Render form diperiksa pada ukuran 390, termasuk bagian bawah form panjang. Dua ekspektasi test FCM diperbarui menjadi string kosong sesuai klarifikasi kontrak backend; implementasi FCM tidak diubah. Analyzer seluruh proyek masih memiliki diagnostik lama di luar kode form, termasuk log `print` dan satu warning pada test notifikasi.
