# Meluncur dan rem (usulan)

Status: **usulan, dipakai di jalan uji sejak 2026-10-13** (run fase1a-gerak). Kedua sheet disalin byte demi byte ke `assets/sprites/loper/` dan masuk `loper_agen_frames.tres` gabungan (48 animasi) lewat `tools/loper_art/bangun_frames.py`; PNG di sini tidak diubah. Dua sheet ini menutup baris "Meluncur" dan "Rem" di `docs/ART_DIRECTION.md` 3.4 dan baris Aset di `docs/TECH_PLAN.md` (Fase 1).

Kapan dipakai (keputusan pemilik 2026-10-13, "ikuti fisika"; pemilihnya `LoperAnim.pose_dari_gerak`, BALANCING 2):
1. rem aktif (stick bawah penuh ditahan 0,25 detik) -> `rem_<arah>`, juga saat sudah berhenti;
2. stick ke bawah dan kecepatan sebenarnya masih di atas kecepatan tujuan (lebih dari 0,05 u/d) -> `meluncur_<arah>`;
3. stick ke bawah dan kecepatan sudah sampai tujuan -> `melambat_<arah>` (kayuh 4 fps);
4. selain itu kayuh biasa. Meluncur dan rem tidak dipengaruhi laju kayuh (`pedal_rate` = 1); lempar dari keduanya memakai lempar santai.

Alas dan tapak roda tiap frame sama persis dengan santai frame 2 (dites di `tests/tes_sprite.gd`), jadi sprite tidak melompat saat berganti dari dan ke kayuh.

Keduanya dibuat untuk **lima arah** (normal, serong_kanan, kanan, serong_kiri, kiri), bukan hanya normal. Dasarnya frame kayuh **santai 2** (engkol mendatar). Badan atas (kepala sampai pinggang) digeser **kaku** 1 px tanpa meregang, jadi bentuk topi dan kepala tidak berubah dari santai.

| Animasi | Frame | fps | Loop | Isi |
|---|---|---|---|---|
| `meluncur_<arah>` | 4 | 4 | ya | Pedal datar, kaki diam. Badan atas turun 1 px bergantian (bernapas pelan) |
| `rem_<arah>` | 4 | 8 | ya | Pedal datar, badan atas mundur 1 px ke belakang sepeda, lalu turun 1 px bergantian seperti bergetar menahan |

"Mundur" mengikuti arah sepeda di layar: normal dan serong_kanan ke kiri, kanan ke kiri, serong_kiri ke bawah, kiri ke kanan.

## Isi
- `loper_agen_meluncur.png`, `loper_agen_rem.png`: 4 kolom × 5 baris, sel 46×58, titik pijak (23, 46), offset Godot (0, −17). Urutan baris sama dengan santai.
- `loper_agen_meluncur.json`, `loper_agen_rem.json`: metadata dan region tiap frame.
- `preview/prev_<animasi>_<arah>.gif`: pratinjau ×4.

## Membuat ulang
```
python3 tools/loper_art/rem_meluncur.py --out build/loper_art/rem_meluncur
```

## Perlu diuji di HP
- Pergeseran 1 px kecil di ×3. Kalau terlalu halus di HP, naikkan jadi 2 px di `REM` pada skrip, atau pakai pose rem khusus (kaki mengerem) lewat renderer.
- Jumlah frame dan fps adalah tebakan; tidak ada bunyi atau kecepatan yang disinkronkan.
- Berhenti (satu kaki turun ke tanah) belum dibuat.
