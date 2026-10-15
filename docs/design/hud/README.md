# Ikon HUD dan radar (usulan)

Aset HUD untuk Fase 3: ikon uang dan kondisi sepeda, penanda radar, dan bingkai 9-slice. Ukuran dan token warna mengikuti `docs/design/DESIGN_SPEC.md` 1.1, 1.3, 3.3, dan 3.4, palet `docs/ART_DIRECTION.md` 2.4. Dibuat oleh `tools/ui_art/hud_ikon.py`; PNG 1× yang dipakai Godot ada di `assets/sprites/ui/`. Semua masih **usulan** sampai dicoba di HP. Mock di kanvas "Loper Koran — Kamera dan Kontrol", papan **Ikon HUD dan radar · Fase 3**.

## Isi `assets/sprites/ui/`

| File | Ukuran | Isi |
|---|---|---|
| `ui_icon_koin.png`, `ui_icon_reputasi.png` | 14×14 | Koin emas dan bintang, ramp emas yang sama; yang membedakan bentuk |
| `ui_icon_ban.png`, `ui_icon_rem.png`, `ui_icon_rantai.png` | 14×14 | Kondisi sepeda (DESIGN_SPEC 3.3): ban dengan velg, tuas rem, dua mata rantai |
| `ui_icon_misi_kucing.png` | 14×14 | Kartu misi P1 Kucing Bu Ratmi (Fase 4) |
| `ui_icon_hud_sheet.png` + `.json` | 84×14 | Enam ikon di atas dalam satu baris, sel 14×14 |
| `ui_radar_<pelanggan\|tip\|misi\|bukan>.png` | 8×6 | Penanda radar biasa |
| `ui_radar_<jenis>_jangkau.png` | 10×8 | Masuk jangkauan lempar: +2 px, garis luar `TEXT` |
| `ui_radar_penanda.png` | 40×16 | Sheet sel 10×8: baris atas biasa (offset 1, 1), baris bawah jangkau |
| `ui_radar_strip_9slice.png` | 12×12 | Bingkai strip radar, margin 2 |
| `ui_panel_hud_9slice.png` | 12×12 | Bingkai panel HUD, margin 4, sudut tumpul 3 px bertingkat |

## Pratinjau (folder ini)

| File | Isi |
|---|---|
| `pratinjau_ikon_hud.png` | Enam ikon ×6 di atas `UI_PANEL`, ditambah ikon koran dari kode untuk perbandingan |
| `pratinjau_radar.png` | Penanda radar ×8, biasa dan jangkau |
| `radar_contoh.png` | Strip radar di atas `design/environment/fase3_perumahan.png` (×2). Jarak rumah, jangkauan radar 20 ubin, dan jangkauan lempar 7 ubin hanya angka contoh |

## Catatan

- Ikon koran tetap `IKON_KORAN` di `scripts/systems/pola_piksel.gd`, dan tombol jeda digambar dari kode (`tombol_jeda.gd`), jadi keduanya tidak punya PNG di sini.
- Penanda bukan pelanggan digambar kotak berlubang supaya bentuknya juga beda, bukan hanya warna abu-abu (tafsiran DESIGN_SPEC 3.4, usulan).
- Ikon rem paling sulit terbaca di ×1; nilai di HP sebelum dikunci.
- Render ulang: `python3 tools/ui_art/hud_ikon.py --salin` (sesudah `python3 tools/env_art/fase3.py` supaya contoh radar ikut dibuat).
