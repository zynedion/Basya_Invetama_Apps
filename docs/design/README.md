# Basya ? indeks desain aktif

Canvas: `basya_ui_canvas.pen` di root proyek. Akses melalui MCP Pen Dev.

## Susunan canvas

Board komponen di atas; layar di bawah dari kiri ke kanan.

| Urutan | Frame | Node |
|---|---|---|
| 01 | Core components | HhPLV |
| 02 | Home components & states | EisN4 |
| 03 | Login | qa4o5 |
| 04 | Home non-investor / viewport | gUAzS |
| 05 | Home investor / viewport | N0I4H |
| 06 | Home non-investor / seluruh konten | E01tAT |
| 07 | Home investor / seluruh konten | RcdKD |

Viewport 390 ? 844 menunjukkan navbar tetap di bawah layar. Frame seluruh konten menunjukkan isi scroll lengkap; keduanya representasi desain yang sama, bukan alternatif versi.

## Acuan

- [Konteks bisnis](../../mobile_cooperative_investment_app_context.md)
- [Arah visual dan token](DESIGN.md)
- [Komponen aktif](components.md)
- [Spesifikasi Flutter](flutter-handoff.md)
- [PRD modular](../prd/README.md)

## Status dan verifikasi

Home V1, board lama beserta komponen yang sudah diganti, dan welcome bawaan dihapus pada 14 September 2026. Master yang masih dipakai dipindahkan terlebih dahulu dengan ID tetap. Pemeriksaan setelah penghapusan tidak menemukan ref yang kehilangan master.

Desain aktif memakai gradient Basya, shortcut formulir, dan navbar mengambang. Nilai keuangan dan identitas adalah contoh. Detail autentikasi serta kontrak API tetap perlu dibahas per modul. Animasi dan performa Flutter belum diuji.
