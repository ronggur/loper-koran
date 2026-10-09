# loper_art — renderer sprite pemain

Sprite pemain Loper Koran tidak digambar per piksel, tapi dirender dari model sederhana (kapsul, bola, kotak) dengan proyeksi isometrik 2:1, tiga nada per material, garis luar `#0E0A1C`, dan bayangan tanah. Aturan gaya dan alasannya: `docs/ART_DIRECTION.md` bagian 2 dan 4.1.

## Menjalankan

```
pip install numpy pillow
python3 tools/loper_art/produce.py --out build/loper_art          # Kemeja Agen, sekitar 35 detik
python3 tools/loper_art/produce.py --out build/loper_art --variant e   # varian baju lain
python3 tools/loper_art/base.py --out build/loper_art/base        # papan pratinjau 5 arah + 3 pose
python3 tools/loper_art/varian.py --out build/loper_art/varian    # pratinjau 8 varian baju, sekitar 1 menit
python3 tools/loper_art/jatuh.py --out build/loper_art/jatuh   # animasi jatuh terjerembab (usulan)
python3 tools/loper_art/melambat.py --out build/loper_art/melambat   # sprite melambat (usulan): frame santai diputar 4 fps
python3 tools/loper_art/lempar.py docs/design/character/loper_agen/loper_agen.png build/loper_art/lempar.png   # animasi lempar koran (usulan), digambar di atas frame kayuh, belum dari renderer
python3 tools/loper_art/rem_meluncur.py --out build/loper_art/rem_meluncur   # sprite meluncur dan rem (usulan), dari frame santai 2
python3 tools/loper_art/bangun_frames.py                       # SpriteFrames gabungan (38 animasi) dan salinan PNG/JSON ke assets/sprites/loper, hanya stdlib; --cek tidak menulis dan exit 1 bila berbeda
python3 tools/loper_art/fullbody/fullbody.py --out build/loper_art/fullbody   # gambar full body versi lama 294×283 (diganti konversi2.py)
python3 tools/loper_art/fullbody/konversi.py GAMBAR.jpg --out build/loper_art/konversi   # ilustrasi jadi pixel art (butuh scipy, scikit-image, scikit-learn)
python3 tools/loper_art/fullbody/konversi_loper.py docs/design/character/loper_agen/konversi/sumber_ai.jpg --out build/loper_art/konversi   # + penyesuaian ke brief dan perbaikan sepeda
python3 tools/loper_art/fullbody/fullbody.py --out build/loper_art/fullbody --layers   # + layer kepala dan badan terpisah
python3 tools/loper_art/fullbody/konversi2.py docs/design/character/loper_agen/konversi2/sumber_ai.jpg --out build/loper_art/konversi2   # gambar full body resmi dari gambar AI, + --layers untuk kepala dan badan terpisah (butuh opencv-python, scikit-learn)
python3 tools/loper_art/fullbody/arsip/fullbody_v1.py build/loper_art/arsip   # arsip: full body versi pertama
```

`build/` tidak di-commit. Setelah dicek, salin hasilnya ke `assets/sprites/loper/` (dan `docs/design/character/loper_agen/` kalau base model berubah). Untuk sheet kayuh, melambat, dan lempar jangan salin dengan tangan: jalankan `bangun_frames.py`, yang menyalin PNG/JSON dari `docs/design/character/loper_agen/` dan menulis ulang `loper_agen_frames.tres`.

## File

| File | Isi |
|---|---|
| `iso.py` | Renderer: titik permukaan, proyeksi 2:1, z-buffer, nada terang/dasar/gelap, garis luar, bayangan, pembersihan piksel lepas |
| `loper.py` | Model pengendara dan sepeda (`build`), delapan varian baju (`VARIANTS`, `VARIANTS_NOBAG`) |
| `base.py` | Pose yang dikunci 2026-10-07: `SPEED` (santai, cepat, ngebut), `HEADINGS` (5 arah), `ground()` untuk latar pratinjau |
| `produce.py` | 60 frame → sheet 4×15 (sel 46×58, titik pijak 23,46), JSON, SpriteFrames `.tres`, pratinjau |
| `varian.py` | Pratinjau delapan varian baju: 5 arah santai dan GIF kayuh, hasilnya di `docs/design/character/varian/` |
| `jatuh.py` | Animasi jatuh terjerembab (usulan, arah normal): sepeda dan pengendara dengan pose bebas, sel 114×68, offset Godot sama dengan sheet kayuh |
| `melambat.py` | Sprite melambat (usulan): memotong baris santai dari sheet kayuh, 4 fps, hasilnya di `docs/design/character/loper_agen/melambat/` |
| `lempar.py` | Animasi lempar koran (usulan, 18 baris): lengan dan koran digambar di atas frame kayuh, **belum dari renderer model**; hasilnya di `docs/design/character/loper_agen/lempar/` |
| `rem_meluncur.py` | Sprite meluncur dan rem (usulan): frame santai 2 dengan badan atas digeser kaku, hasilnya di `docs/design/character/loper_agen/rem_meluncur/` |
| `bangun_frames.py` | Membangun `assets/sprites/loper/loper_agen_frames.tres` (15 kayuh + 5 melambat + 18 lempar = 38 animasi) dari tiga JSON sumber di `docs/design/character/loper_agen/` dan menyalin PNG/JSON byte demi byte. Hanya stdlib, deterministik, menolak sumber rusak. `produce.py` tetap menulis `.tres` kayuh saja (15 animasi, acuan di `docs/design/`); yang dipakai game adalah hasil skrip ini. Dijalankan ulang setiap sheet berubah; ujinya `tools/tests_cek/uji_bangun_frames.py` |
| `fullbody/` | Gambar full body skala besar; gaya di `docs/ART_DIRECTION.md` 3.5. **`konversi2.py`** membuat gambar resmi 240×292 (sejak 2026-10-08) dari gambar AI dengan langkah-langkah di `konversi2/`: konversi otomatis, lalu kepala, kerah, tas, gir, engkol, dan kabel diubah; kepala di layer sendiri. `fullbody.py` (dengan pelukis lima nada `pxhd.py`) adalah versi lama 294×283, hasilnya sekarang di arsip. `konversi.py`, `konversi_loper.py`, dan `konversi_sepeda.py` (perbaikan frame, engkol, setang, dan tas sepeda) adalah eksplorasi konversi pertama. `arsip/` menyimpan full body versi pertama (`fullbody_v1.py`, pelukis tiga nada `px2d.py`) |

## Varian baju

| id | Nama | Tas selempang |
|---|---|---|
| a | Merah Klasik | ya |
| b | Garis Biru | ya |
| c | Jaket Hijau | ya |
| d | Kaus Bola | ya |
| e | Polo Kuning | tidak |
| f | Batik | tidak |
| g | Hoodie Abu | tidak |
| h | Kemeja Agen (base model): celana panjang jogger, lampu depan, bel, tanpa keranjang | tidak |

Hanya `h` yang sudah diaudit untuk produksi. Varian lain memakai pose yang sama tapi belum dicek frame per frame; varian a–d dengan tas selempang belum pernah dirender dalam pose condong.

## Mengubah sesuatu

- **Pose atau arah**: ubah `SPEED` / `HEADINGS` di `base.py`, jalankan `base.py` untuk melihat papan, lalu `produce.py`.
- **Animasi baru** (lempar, meluncur, rem, berhenti; ART_DIRECTION 3.4): tambahkan opsi pose di `loper.build` dan baris baru di `produce.py`. Urutan baris yang sudah ada jangan diubah, karena `.tres` dan kode memakai nama animasi.
- **Frame dipoles manual**: simpan sebagai file terpisah dan catat di changelog ART_DIRECTION, karena render ulang menimpa sheet.
- Hasil render deterministik. Setelah mengubah kode yang seharusnya tidak mengubah tampilan, bandingkan sheet baru dengan yang lama piksel per piksel.
