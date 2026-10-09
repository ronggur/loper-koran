# ui_art — aset HUD dan efek kecil

Pixel art untuk HUD dan efek yang tidak dirender dari model pemain. Ukuran dan token warna mengikuti `docs/design/DESIGN_SPEC.md`, palet mengikuti `docs/ART_DIRECTION.md` 2.4.

## Menjalankan

```
pip install numpy pillow
python3 tools/ui_art/bel.py --out docs/design/bel     # tombol bel, efek "kring", ikon "!" (usulan)
```

## File

| File | Isi |
|---|---|
| `bel.py` | Bel "Kring Kring!" (GDD 5.4): tombol bel 40×40 tiga keadaan, garis getar 4 frame, teks "KRING!" dan "KRING KRING!", ikon "!", pratinjau GIF di atas sprite rute dan penempatan di mock HUD. Penjelasan aset di `docs/design/bel/README.md` |
