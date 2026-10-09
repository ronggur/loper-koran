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

## Cara memutar efek

1. Ketukan: `vfx_bel.png` diputar sekali (4 frame) di titik bel.
2. Satu frame kemudian teks muncul di titik bel + (3, −16), lalu naik 1 px tiap frame selama 4 frame. Frame terakhir memakai versi redup, lalu hilang. Total sekitar 0,4 detik, sama dengan panjang bunyi bel (`SOUND_DESIGN.md` 3.3).
3. Ketukan kedua selama teks masih tampil: garis getar diulang dan teks langsung diganti "KRING KRING!" lalu naik lagi dari awal.

Efek visual selalu tampil, juga saat suara mati, supaya pemain yang main tanpa suara tetap tahu belnya berbunyi.

**Titik bel per animasi** (sel 46×58 di `character/loper_agen/loper_agen.png`): baru dua yang ditentukan, santai_normal (33, 24) dan santai_kanan (28, 30). Titik untuk 13 animasi lain perlu ditambahkan ke `loper_agen.json` sebelum dipakai di Godot.

## Pratinjau (`preview/`)

| File | Isi |
|---|---|
| `tombol_bel_x4.png` | Tiga keadaan tombol ×4 |
| `vfx_bel_frames_x6.png`, `teks_kring_x6.png` | Frame garis getar dan dua teks ×6 |
| `kring_normal_x6.gif`, `kring_kanan_x6.gif` | Satu kali kring di atas sprite rute (santai, arah normal dan kanan), 12 fps |
| `kring_kring_normal_x6.gif` | Dua kali kring: teks berganti jadi "KRING KRING!" |
| `penempatan_hud.png` | Tombol di pojok kanan bawah mock HUD (`screens/hud-rute.png`) |
| `penempatan_kontrol.png` | Zona stick, zona swipe, dan zona tap bel (lingkaran putus-putus oranye) |
| `reaksi_ayam_x5.png` | Ikon "!" di atas ayam (`environment/detail_ayam.webp`) |

## Membuat ulang

```
python3 tools/ui_art/bel.py --out docs/design/bel
```

Hasilnya deterministik. Warna dari palet induk (`ART_DIRECTION.md` 2.4) dan token UI (`DESIGN_SPEC.md` 1.1).
