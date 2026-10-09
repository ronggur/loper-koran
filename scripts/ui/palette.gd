class_name Palette
extends RefCounted
## Token warna UI, SATU-SATUNYA tempat hex warna di kode dan scene (DESIGN_SPEC 1.1, rule `ui-scenes`).
##
## Nilai sama dengan tabel DESIGN_SPEC 1.1 dan dijaga oleh `tests/run_tests.gd`. Palet induk
## (ART_DIRECTION 2.4, usulan) ada di `assets/palette/loper_master.gpl` untuk Aseprite.
## Warna jangan jadi satu-satunya pembeda: pasangkan dengan bentuk atau simbol (DESIGN_SPEC 1.1).

## Latar layar penuh (koran, hasil, bengkel).
const UI_BG: Color = Color("#1C130F")
## Panel dan kartu di layar penuh.
const UI_PANEL: Color = Color("#2A1E17")
## Garis dalam panel HUD, isi bar kosong, kotak progres yang belum.
const UI_PANEL_RAISED: Color = Color("#36281E")
## Latar panel HUD di atas jalan (alpha 84%).
const HUD_PANEL: Color = Color("#0E0A1C", 0.84)
## Garis luar panel, bar, ikon (sama dengan garis luar sprite).
const OUTLINE: Color = Color("#0E0A1C")
## Teks utama, isi bar kecepatan, kotak kondisi penuh.
const TEXT: Color = Color("#FFF3E3")
## Teks kedua, garis putus-putus.
const TEXT_2: Color = Color("#CDB9A3")
## Label penting, stamina, kotak progres berikutnya, knob stick.
const ACCENT: Color = Color("#FFB22E")
## Terkirim, tip.
const OK: Color = Color("#56C46E")
## Meleset.
const FAIL: Color = Color("#D94F3D")
## Batas ngebut, kondisi sepeda perlu ke bengkel.
const WARN: Color = Color("#FF8A3D")

## Isi strip radar (alpha 60%).
const RADAR_BG: Color = Color("#0E0A1C", 0.60)
## Penanda radar: pelanggan biasa.
const RADAR_PELANGGAN: Color = Color("#FFC94A")
## Penanda radar: pelanggan pemberi tip.
const RADAR_TIP: Color = Color("#56C46E")
## Penanda radar: target misi.
const RADAR_MISI: Color = Color("#E98E3F")
## Penanda radar: rumah bukan pelanggan (hanya mode bantu, usulan).
const RADAR_BUKAN: Color = Color("#969AA0")
