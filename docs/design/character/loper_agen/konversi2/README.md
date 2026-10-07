# Sumber gambar full body (konversi2)

Gambar full body resmi `../loper_agen_fullbody.png` (240×292 px, sejak 2026-10-08) dibuat dari ilustrasi AI di folder ini (`sumber_ai.jpg`, 1792×2240). Ilustrasinya diubah jadi pixel art dengan palet terbatas, garis luar 1 px `#1B1226`, latar transparan, dan bayangan tanah dongker `#2E3550` 38% (`docs/ART_DIRECTION.md` 3.5). Setelah konversi otomatis, beberapa bagian diubah dan digambar ulang dengan tangan.

Status: **resmi**, disetujui Ronggur 2026-10-08. Menggantikan gambar 294×283 hasil `tools/loper_art/fullbody/fullbody.py`, yang sekarang disimpan di `../arsip/loper_agen_fullbody_v2.png`.

## Isi
- `sumber_ai.jpg`: gambar sumber.
- Hasilnya ada di folder induk: `../loper_agen_fullbody.png` dan pratinjau ×3 `../preview/loper_agen_fullbody_x3.png`.

## Yang diubah dari gambar sumber
- **Kepala terpisah tanpa leher.** Garis dagu kiri melengkung (tegak di bawah telinga, landai ke dagu). Bagian belakang kerah dongker terlihat dan dinaikkan 2 px; kepala diturunkan 2 px sehingga dagu sedikit menumpuk kerah belakang. Ujung kerah menyambung ke bahu, bukaan V kecil. Kepala ada di layer sendiri (`--layers`).
- **Tas boncengan terbuka.** Tutup terlipat ke belakang, gesper kosong. Koran gulung yang tadinya di atas boncengan pindah ke dalam tas; hanya bagian atasnya yang terlihat.
- **Satu gir belakang.** Derailleur dibuang, rantai lurus dari gir belakang ke gir depan.
- **Dua engkol segaris**, 19 px dan lebih tebal. Engkol sisi dekat naik di depan penutup rantai hijau; engkol sisi seberang turun di belakang gir depan, lebih gelap. Urutan lapisan dari belakang: engkol sisi seberang, gir depan, penutup rantai, engkol sisi dekat.
- **Kabel rem tinggal dua.**
- Digambar ulang: roda dan jari-jari, rantai, tulisan "KORAN", gelang kuning, tali sepatu kiri.

## Beda dengan desain sprite rute (ART_DIRECTION 3.1)
- Sepeda pakai spakbor; sprite rute tanpa spakbor.
- Tas boncengan hanya terlihat satu sisi.

## Membuat ulang

```
pip install numpy pillow opencv-python scikit-learn
python3 tools/loper_art/fullbody/konversi2.py docs/design/character/loper_agen/konversi2/sumber_ai.jpg --out build/loper_art/konversi2
python3 tools/loper_art/fullbody/konversi2.py docs/design/character/loper_agen/konversi2/sumber_ai.jpg --out build/loper_art/konversi2 --layers   # + layer kepala dan badan
```

Hasilnya `build/loper_art/konversi2/loper_agen_fullbody.png`, identik piksel per piksel dengan `../loper_agen_fullbody.png` (dicek 2026-10-08). Dengan `--layers` juga keluar `_head.png` dan `_body.png`; badan + kepala ditumpuk sama persis dengan gambar penuh. Langkah-langkahnya ada di `tools/loper_art/fullbody/konversi2/`; koordinat di tiap langkah khusus untuk gambar sumber ini.
