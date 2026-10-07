# Varian baju pemain (a–h)

Pratinjau delapan varian baju dari `tools/loper_art/loper.py` (`VARIANTS`, `VARIANTS_NOBAG`), dirender dengan model dan pose produksi yang sama dengan Kemeja Agen. Sama dengan papan "Dengan tas selempang", "Tanpa tas selempang", "Siklus kayuh", dan "Skala game ×3" di kanvas "Karakter Loper Koran".

Status: varian **a–g disimpan untuk item atau kosmetik nanti** (`docs/ART_DIRECTION.md` 3) dan belum diaudit frame per frame. Varian a–d memakai tas selempang yang belum pernah dicek dalam pose condong. Varian **h** adalah Kemeja Agen, base model produksi; sheet lengkapnya ada di `../loper_agen/`.

| id | Nama | Tas selempang |
|---|---|---|
| a | Merah Klasik | ya |
| b | Garis Biru | ya |
| c | Jaket Hijau | ya |
| d | Kaus Bola | ya |
| e | Polo Kuning (keranjang depan) | tidak |
| f | Batik | tidak |
| g | Hoodie Abu | tidak |
| h | Kemeja Agen | tidak |

## Isi
- `<id>_<nama>_5arah.png`: 5 arah santai (normal, serong kanan, kanan, serong kiri, kiri), sel 46×55, latar transparan.
- `varian_5arah.png`: semua varian, satu baris per varian (a sampai h).
- `preview/varian_5arah_x4.png`: semua varian ×4 di latar abu.
- `preview/<id>_<nama>_kayuh.gif`: animasi kayuh 4 frame arah normal di atas jalan, ×4.

Sel pratinjau (46×55, titik pijak 23,43) sedikit lebih pendek dari sheet produksi karena hanya pose santai. Untuk dipakai di game, buat sheet lengkap dengan `produce.py --variant <id>`.

    python3 tools/loper_art/varian.py --out build/loper_art/varian
