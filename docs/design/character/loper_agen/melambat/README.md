# Melambat (usulan)

Tingkat kecepatan di bawah santai, untuk saat stick ditarik ke bawah dan sepeda melambat. Status: **usulan; dipakai di jalan uji sejak 2026-10-09** (run `sprite-lempar-melambat`): ada di `assets/sprites/loper/loper_agen_frames.tres` (dibangun `tools/loper_art/bangun_frames.py`) dan dipilih `LoperAnim` sebagai tingkat -1 saat stick ditarik ke bawah (komponen maju negatif sesudah zona mati 15%).

Gambarnya **sama persis dengan santai** (5 arah × 4 frame kayuh); yang berbeda hanya putarannya, **4 fps** (santai 8 fps). Percobaan pertama menggeser badan atas supaya duduk lebih tegak, tapi bentuk topi jadi berbeda dari santai, jadi dibuang. Kalau nanti perlu pembeda gambar (mis. kaki turun menjejak tanah), itu pose baru yang harus disetujui dulu.

## Isi
- `loper_agen_melambat.png`: 4 kolom × 5 baris, sel 46×58, titik pijak (23, 46), offset Godot (0, −17). Urutan baris sama dengan santai: normal, serong_kanan, kanan, serong_kiri, kiri.
- `loper_agen_melambat.json`: metadata dan region tiap frame. Nama animasi `melambat_<arah>`, loop, 4 fps.
- `preview/prev_melambat_<arah>.gif`: pratinjau ×4, 250 ms per frame.

## Membuat ulang
```
python3 tools/loper_art/melambat.py --out build/loper_art/melambat
```
Skrip hanya memotong baris santai dari `loper_agen.png`, jadi kalau sheet kayuh dirender ulang, sheet ini ikut berubah.
