# Basya ? komponen aktif

Acuan visual: [DESIGN.md](DESIGN.md). Implementasi: [flutter-handoff.md](flutter-handoff.md). Lokasi canvas: [README.md](README.md).

## Master yang digunakan

| ID | Komponen | Node master | Board |
|---|---|---|---|
| CMP-03 | Primary button / gradient | hMfe5 | Core |
| CMP-04 | Text field | yvJaU | Core |
| CMP-07 | Upload bukti | PlD9D | Core |
| CMP-12 | Transaction row | o90NGc | Core |
| CMP-13 | Status badge | PvcE2 | Core |
| CMP-21 | Gradient balance | Kmg8n | Home |
| CMP-22 | Balance subpanel | OaBFg | Home |
| CMP-23 | Shortcut | FurB3 | Home |
| CMP-24 | Floating navigation | TlUY0 | Home |
| CMP-25 | Top Up destination sheet | t8gKy | Home |

Core: HhPLV. Home: EisN4. Master dipakai melalui instance dan override; jangan membuat salinan master per layar. ID lama yang sudah dipensiunkan tidak dipakai ulang.

## Variasi yang tersedia

- Tombol: primary gradient, secondary, disabled; master primary dipakai Login.
- Field: ID anggota dan kata sandi pada Login, masih usulan autentikasi.
- Status: pending, berhasil, gagal. Upload bukti tetap acuan untuk modul pembayaran manual.
- Kartu saldo: investor dengan Simpanan Sukarela + Buy Power; non-investor dengan Simpanan Sukarela + Simpanan Wajib sebagai rincian dari Total Saldo.
- Shortcut: Top Up, Withdraw, Pinjam; investor memiliki tambahan Mutasi.
- Navbar: Beranda pada master; Simpanan j1M7kN, Investasi gvkMG, Multiguna InvKp, Profil qR0EF. Non-investor memiliki destinasi sesuai konteks bisnis.
- Sheet: investor memilih Sukarela atau Buy Power sebelum membuka form.

## Aturan konsistensi

Font Plus Jakarta Sans dan ikon Lucide. Warna, radius dan gradient mengikuti DESIGN.md. Tampilan loading/error/hidden yang belum digambar diselesaikan pada modul terkait. Bukti terkirim tidak sama dengan pembayaran disahkan. Total Saldo tidak menjumlahkan investasi aktif atau metrik profit.

Rincian simpanan, investasi terbuka dan pengingat cicilan mengikuti layar Home aktif; master kartu V1 untuk bagian tersebut sudah dihapus. Komponen lain yang diperlukan nantinya ditambahkan setelah modul dibahas, bukan menggunakan kembali desain lama.
