# Konversi gambar AI ke pixel art (eksplorasi)

Gambar full body dari generator gambar (`sumber_ai.jpg`, 1600×1200) diubah jadi pixel art sungguhan: grid piksel tetap, palet 41 warna, garis luar 1 px `#1B1226`, latar transparan, bayangan tanah dongker `#2E3550` 38%. Ukuran subjek disamakan dengan `../loper_agen_fullbody.png` supaya bisa dibandingkan.

Status: **eksplorasi**. Gambar full body resmi tetap `../loper_agen_fullbody.png`.

## Isi
- `loper_agen_konversi.png`: **versi 2**, disesuaikan ke brief (2026-10-07): celana jogger dongker, mata menatap ke depan (iris di tengah, tidak melirik), kepala diturunkan 3 px sehingga dagu sedikit menumpuk kerah. 266×281 px, 49 warna, latar transparan.
- `loper_agen_konversi_asli.png`: konversi pertama tanpa penyesuaian (41 warna).
- `preview/loper_agen_konversi_x3.png`: versi 2 tampil ×3.
- `preview/loper_agen_konversi_palet.png`: palet versi 2, urut dari gelap ke terang.
- `sumber_ai.jpg`: gambar sumber.

## Beda dengan desain terkunci (ART_DIRECTION 3.1)
Celana sudah disamakan di versi 2. Yang masih beda:
- Sepeda pakai spakbor; desain tanpa spakbor.
- Tas boncengan hanya satu sisi.

## Membuat ulang

```
python3 tools/loper_art/fullbody/konversi.py docs/design/character/loper_agen/konversi/sumber_ai.jpg --out build/loper_art/konversi
```

Versi 2 (konversi + penyesuaian ke brief):

```
python3 tools/loper_art/fullbody/konversi_loper.py docs/design/character/loper_agen/konversi/sumber_ai.jpg --out build/loper_art/konversi
```

`konversi_loper.py` mengganti warna celana dengan ramp dongker yang sama dengan jogger di gambar full body resmi, memindah iris ke tengah mata dengan putih tipis di kedua sisi (menatap ke depan, tidak melirik), dan menurunkan kepala (`--head-drop`, default 3 px, dagu sedikit menumpuk kerah). Koordinat mata dan batas celana khusus untuk gambar sumber ini.

Pilihan konversi.py: `--height` (tinggi subjek dalam px, default 278) dan `--colors` (jumlah warna palet, default 40). Langkahnya: latar polos dibuang, warna dikelompokkan dengan k-means di ruang Lab, tiap piksel mengambil warna terbanyak di bloknya (bukan rata-rata, jadi tidak kabur), bintik JPEG dirapikan, lalu garis luar dan bayangan ditambahkan.
