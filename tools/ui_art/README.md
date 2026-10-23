# ui_art — aset HUD dan efek kecil

Pixel art untuk HUD dan efek yang tidak dirender dari model pemain. Ukuran dan token warna mengikuti `docs/design/DESIGN_SPEC.md`, palet mengikuti `docs/ART_DIRECTION.md` 2.4.

## Menjalankan

```
pip install numpy pillow
python3 tools/ui_art/bel.py --out docs/design/bel     # tombol bel, efek "kring", ikon "!" (usulan)
python3 tools/ui_art/bel.py --salin                   # juga aset game 1x ke assets/sprites/ui/ (ui_bel_tombol, ui_bel_getar, ui_ikon_seru + ui_bel.json)
python3 tools/ui_art/hud_ikon.py --salin              # ikon HUD, penanda radar, 9-slice ke assets/sprites/ui/ (usulan)
python3 tools/ui_art/lencana.py --salin               # lencana milestone perunggu/perak/emas 14x14 ke assets/sprites/ui/ (run 6A2, usulan)
python3 tools/tests_cek/uji_ui_lencana.py             # bukti lencana di assets/ = keluaran skrip, palet induk, tingkat terbaca tanpa warna
```

## File

| File | Isi |
|---|---|
| `hud_ikon.py` | Ikon HUD 14×14 (koin, reputasi, ban, rem, rantai, misi kucing), penanda radar 8×6 dan versi masuk jangkauan 10×8, bingkai strip radar dan panel HUD 9-slice, contoh radar di atas layar `tools/env_art/fase3.py`. Penjelasan di `docs/design/hud/README.md` |
| `lencana.py` | Lencana milestone 14×14 (run fase6a2 bagian C, AC-15): medali bergantung pita biru, perunggu/perak/emas; tingkat dibedakan warna DAN jumlah garis di tengah (1, 2, 3). Hanya palet induk, deterministik, tanpa numpy. `--salin` menulis `ui_lencana_<tingkat>.png` ke `assets/sprites/ui/` |
| `bel.py` | Bel "Kring Kring!" (GDD 5.4): tombol bel 40×40 tiga keadaan, garis getar 4 frame, teks "KRING!" dan "KRING KRING!", ikon "!", pratinjau GIF di atas sprite rute dan penempatan di mock HUD. Penjelasan aset di `docs/design/bel/README.md`. `--salin` (run fase3b-rintangan-skor) menulis aset game ke `assets/sprites/ui/`: `ui_bel_tombol.png` (diam, ditekan, lalu 8 frame jeda dengan cincin berkurang 8/8 sampai 1/8), `ui_bel_getar.png`, `ui_ikon_seru.png`, dan `ui_bel.json`; teks "KRING!" tidak disalin karena di game teksnya kunci terjemahan |
