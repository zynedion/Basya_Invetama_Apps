# Basya Investama

Flutter frontend untuk aplikasi Basya Investama.

## Menjalankan

```sh
flutter pub get
flutter run
```

Startup menampilkan animasi splash lalu login mengikuti desain Pen Dev. Login terhubung ke API produksi Basya; token dan kredensial untuk pemulihan sesi disimpan melalui secure storage.

## Rilis Google Play

Panduan signing, build AAB, listing, deklarasi, dan pekerjaan sebelum publikasi ada di [docs/release/google-play.md](docs/release/google-play.md).

## Aset

- Ikon aplikasi: `assets/logo/basya-favicon.png`.
- Logo login: `assets/logo/logo_basya.png`.
- Animasi splash: `assets/animation/Scene-3-no-watermark.json`.
- Font lokal: Plus Jakarta Sans, dengan lisensi `assets/fonts/OFL.txt`.

Setelah mengganti ikon, jalankan `dart run flutter_launcher_icons`.

## Verifikasi

```sh
flutter analyze
flutter test
```

Detail cakupan frontend ada di `docs/prd/modules/01-auth-profile.md`.
