# ui_art — aset HUD dan efek kecil

Pixel art untuk HUD dan efek yang tidak dirender dari model pemain. Ukuran dan token warna mengikuti `docs/design/DESIGN_SPEC.md`, palet mengikuti `docs/ART_DIRECTION.md` 2.4.

## Menjalankan

```
pip install numpy pillow
python3 tools/ui_art/bel.py --out docs/design/bel     # tombol bel, efek "kring", ikon "!" (usulan)
python3 tools/ui_art/hud_ikon.py --salin              # ikon HUD, penanda radar, 9-slice ke assets/sprites/ui/ (usulan)
```

## File

| File | Isi |
|---|---|
| `hud_ikon.py` | Ikon HUD 14×14 (koin, reputasi, ban, rem, rantai, misi kucing), penanda radar 8×6 dan versi masuk jangkauan 10×8, bingkai strip radar dan panel HUD 9-slice, contoh radar di atas layar `tools/env_art/fase3.py`. Penjelasan di `docs/design/hud/README.md` |
| `bel.py` | Bel "Kring Kring!" (GDD 5.4): tombol bel 40×40 tiga keadaan, garis getar 4 frame, teks "KRING!" dan "KRING KRING!", ikon "!", pratinjau GIF di atas sprite rute dan penempatan di mock HUD. Penjelasan aset di `docs/design/bel/README.md` |
