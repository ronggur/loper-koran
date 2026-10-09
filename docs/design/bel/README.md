# Bel "Kring Kring!" (usulan)

Aset bel sepeda: tombol di HUD, efek "kring" di atas setang, dan ikon "!" untuk warga atau hewan yang mendengar bel. Aturan mainnya di `docs/GDD.md` 5.4, ukuran tombol di `docs/design/DESIGN_SPEC.md` 3.8. Semua masih **usulan** sampai dicoba di HP. Mock di kanvas "Loper Koran — Kamera dan Kontrol", papan **Bel · Kring Kring!**.

## Isi (1x, yang dipakai di Godot)

| File | Ukuran | Isi |
|---|---|---|
| `tombol_bel.png` | 120×40 | Tiga keadaan 40×40 berjajar: **diam** (cincin `TEXT`), **ditekan** (cincin `ACCENT`, ikon turun 1 px, garis getar kecil), **jeda** (ikon redup, cincin `ACCENT` menunjukkan sisa jeda; contoh 50%) |
| `vfx_bel.png` | 64×16 | Garis getar ")" di sisi kanan bel, 4 frame 16×16, 12 fps. Titik jangkar (3, 12) = titik bel |
| `teks_kring.png` | 48×7 | Teks "KRING!", 2 frame 24×7 berjajar: terang, lalu redup |
| `teks_kring_kring.png` | 96×7 | Teks "KRING KRING!", 2 frame 48×7 berjajar: terang, lalu redup |
| `ikon_seru.png` | 11×13 | Ikon "!" di atas kepala warga atau hewan yang bereaksi. Titik jangkar (5, 12) |
| `bell_anchors.json` | — | Titik bel 15 animasi kayuh (3 kecepatan × 5 arah), usulan |

## Cara memutar efek

1. Ketukan: `vfx_bel.png` diputar sekali (4 frame) di titik bel.
2. Satu frame kemudian teks muncul di titik bel + (3, −16), lalu naik 1 px tiap frame selama 4 frame. Frame terakhir memakai versi redup, lalu hilang. Total sekitar 0,4 detik, sama dengan panjang bunyi bel (`SOUND_DESIGN.md` 3.3).
3. Ketukan kedua selama teks masih tampil: garis getar diulang dan teks langsung diganti "KRING KRING!" lalu naik lagi dari awal.

Efek visual selalu tampil, juga saat suara mati, supaya pemain yang main tanpa suara tetap tahu belnya berbunyi.

**Titik bel per animasi** (sel 46×58 di `character/loper_agen/loper_agen.png`): kelima belas animasi kayuh sekarang punya titik di `bell_anchors.json` (usulan, belum diuji di Godot). Yang belnya terlihat (serong kanan, 90° kanan) diambil dari piksel kuning bel; yang belnya tertutup badan (normal, serong kiri, 90° kiri) memakai ujung setang di sisi kanan pengendara. Titik ini adalah tempat sisi kiri garis getar ditempel, jadi nilainya **tidak sama** dengan dua titik lama (santai_normal (33, 24), santai_kanan (28, 30)) yang mengacu ke jangkar `vfx_bel.png` (3, 12). Pilih satu acuan sebelum dipasang di `loper_agen.json`.

**Posisi efek.** Sprite pemain digambar **di atas** efek, supaya garis getar dan teks tidak menutupi kepala atau badan. Garis getar digeser 3 px keluar dari titik bel, dan teks 11 px di kanan serta 12 px di atas titik, lalu naik 1 px per frame. Untuk arah 90° kiri (setang di sisi jauh) seluruh efek dicerminkan ke kiri, dan teks ditaruh di kiri titik.

## Pratinjau (`preview/`)

| File | Isi |
|---|---|
| `tombol_bel_x4.png` | Tiga keadaan tombol ×4 |
| `vfx_bel_frames_x6.png`, `teks_kring_x6.png` | Frame garis getar dan dua teks ×6 |
| `kring_normal_x6.gif`, `kring_kanan_x6.gif` | Satu kali kring di atas sprite rute (santai, arah normal dan kanan), 12 fps |
| `kring_kring_normal_x6.gif` | Dua kali kring: teks berganti jadi "KRING KRING!" |
| `kring_santai_normal_x3.gif`, `kring2_santai_normal_x3.gif` | Satu dan dua kali kring, santai arah normal, ×3, di atas latar abu |
| `kring_santai_kanan_x3.gif`, `kring_santai_kiri_x3.gif` | 90° kanan dan 90° kiri (dicerminkan) |
| `kring_santai_serong_kanan_x3.gif`, `kring_santai_serong_kiri_x3.gif`, `kring2_santai_serong_kiri_x3.gif` | Dua arah serong; yang terakhir dua kali kring |
| `kring_cepat_serong_kanan_x3.gif`, `kring_ngebut_serong_kiri_x3.gif` | Titik bel ikut pose saat cepat dan ngebut |
| `penempatan_hud.png` | Tombol di pojok kanan bawah mock HUD (`screens/hud-rute.png`) |
| `penempatan_kontrol.png` | Zona stick, zona swipe, dan zona tap bel (lingkaran putus-putus oranye) |
| `reaksi_ayam_x5.png` | Ikon "!" di atas ayam (`environment/detail_ayam.webp`) |

## Membuat ulang

```
python3 tools/ui_art/bel.py --out docs/design/bel
```

Hasilnya deterministik. Warna dari palet induk (`ART_DIRECTION.md` 2.4) dan token UI (`DESIGN_SPEC.md` 1.1).
