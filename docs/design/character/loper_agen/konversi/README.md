# Konversi gambar AI ke pixel art (eksplorasi)

Gambar full body dari generator gambar (`sumber_ai.jpg`, 1600×1200) diubah jadi pixel art sungguhan: grid piksel tetap, palet 41 warna, garis luar 1 px `#1B1226`, latar transparan, bayangan tanah dongker `#2E3550` 38%. Ukuran subjek disamakan dengan `../loper_agen_fullbody.png` supaya bisa dibandingkan.

Status: **eksplorasi**. Gambar full body resmi tetap `../loper_agen_fullbody.png`.

## Isi
- `loper_agen_konversi.png`: **versi 3** (2026-10-07), 243×280 px, 61 warna, latar transparan. Sama dengan versi 2; hanya empat bagian sepeda yang diperbaiki:
  - frame lebih pendek (jarak poros roda 176 → 152 px), top tube, down tube, dan seat tube digambar lurus sehingga garisnya menyambung di kedua sisi kaki;
  - engkol segaris melewati as pedal, kedua pedal terlihat di sela kaki;
  - setang kiri tersambung dari grip ke stem;
  - tas boncengan tanpa tutup, dengan koran (dua gulung, dua lipat) terlihat di dalamnya, dan tas sisi seberang mengintip di kanan atas. Warna kulit, saku depan, dan dua tali bergesper tetap seperti gambar AI.

  Roda, spakbor, sadel, rak, head tube, garpu, lampu, gir dengan pelindung rantai, latar gelap, dan sepatu tetap piksel gambar AI.
- `loper_agen_konversi_asli.png`: konversi pertama tanpa penyesuaian (41 warna).
- `preview/loper_agen_konversi_x3.png`: versi 3 tampil ×3.
- `preview/loper_agen_konversi_palet.png`: palet versi 3, urut dari gelap ke terang.
- `preview/sepeda_sebelum_sesudah.png`: versi 2 dan versi 3 berdampingan, ×2.
- `arsip/loper_agen_konversi_v2.png` (+ `_x3`): versi 2 (celana dongker, mata ke depan, kepala turun 3 px, sepeda asli gambar AI), 266×281 px.
- `sumber_ai.jpg`: gambar sumber.

## Beda dengan desain terkunci (ART_DIRECTION 3.1)
Celana disamakan di versi 2, tas di kedua sisi sejak versi 3. Yang masih beda:
- Sepeda pakai spakbor; desain tanpa spakbor.
- Tas boncengan cokelat kulit; desain merah bata.

## Membuat ulang

```
python3 tools/loper_art/fullbody/konversi.py docs/design/character/loper_agen/konversi/sumber_ai.jpg --out build/loper_art/konversi
```

Versi 3 (konversi + penyesuaian ke brief + perbaikan sepeda):

```
python3 tools/loper_art/fullbody/konversi_loper.py docs/design/character/loper_agen/konversi/sumber_ai.jpg --out build/loper_art/konversi
```

Versi 2 (sepeda asli gambar AI) dibuat dengan perintah yang sama ditambah `--sepeda-lama`.

`konversi_loper.py` mengganti warna celana dengan ramp dongker yang sama dengan jogger di gambar full body resmi, memindah iris ke tengah mata dengan putih tipis di kedua sisi (menatap ke depan, tidak melirik), dan menurunkan kepala (`--head-drop`, default 3 px, dagu sedikit menumpuk kerah). Koordinat mata dan batas celana khusus untuk gambar sumber ini.

Perbaikan sepeda ada di `konversi_sepeda.py`. Bagian belakang sepeda (roda, spakbor, rak, tas) digeser ke depan dengan membuang satu lajur di belakang kaki kiri tokoh (`CUT`, `SHIFT`); sadel digeser lebih sedikit (`SADDLE_SHIFT`) supaya tetap terlihat di samping pinggul. Pipa frame lama dihapus lalu digambar ulang lurus dengan pelukis lima nada `pxhd.py` dan palet hijau gambar AI. Lengan engkol dan pedal digambar ulang pada satu garis melewati as pedal (`BB`, `CRANK_ANGLE`); lubang di gir diisi dari bagian gir itu sendiri yang diputar satu jari-jari. Tas digambar ulang tanpa tutup. Koordinat khusus untuk gambar sumber ini.

Pilihan konversi.py: `--height` (tinggi subjek dalam px, default 278) dan `--colors` (jumlah warna palet, default 40). Langkahnya: latar polos dibuang, warna dikelompokkan dengan k-means di ruang Lab, tiap piksel mengambil warna terbanyak di bloknya (bukan rata-rata, jadi tidak kabur), bintik JPEG dirapikan, lalu garis luar dan bayangan ditambahkan.
