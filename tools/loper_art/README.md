# loper_art — renderer sprite pemain

Sprite pemain Loper Koran tidak digambar per piksel, tapi dirender dari model sederhana (kapsul, bola, kotak) dengan proyeksi isometrik 2:1, tiga nada per material, garis luar `#0E0A1C`, dan bayangan tanah. Aturan gaya dan alasannya: `docs/ART_DIRECTION.md` bagian 2 dan 4.1.

## Menjalankan

```
pip install numpy pillow
python3 tools/loper_art/produce.py --out build/loper_art          # Kemeja Agen, sekitar 35 detik
python3 tools/loper_art/produce.py --out build/loper_art --variant e   # varian baju lain
python3 tools/loper_art/base.py --out build/loper_art/base        # papan pratinjau 5 arah + 3 pose
```

`build/` tidak di-commit. Setelah dicek, salin hasilnya ke `assets/sprites/loper/` (dan `docs/design/character/loper_agen/` kalau base model berubah).

## File

| File | Isi |
|---|---|
| `iso.py` | Renderer: titik permukaan, proyeksi 2:1, z-buffer, nada terang/dasar/gelap, garis luar, bayangan, pembersihan piksel lepas |
| `loper.py` | Model pengendara dan sepeda (`build`), delapan varian baju (`VARIANTS`, `VARIANTS_NOBAG`) |
| `base.py` | Pose yang dikunci 2026-10-07: `SPEED` (santai, cepat, ngebut), `HEADINGS` (5 arah), `ground()` untuk latar pratinjau |
| `produce.py` | 60 frame → sheet 4×15 (sel 46×58, titik pijak 23,46), JSON, SpriteFrames `.tres`, pratinjau |

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
| h | Kemeja Agen (base model) | tidak |

Hanya `h` yang sudah diaudit untuk produksi. Varian lain memakai pose yang sama tapi belum dicek frame per frame; varian a–d dengan tas selempang belum pernah dirender dalam pose condong.

## Mengubah sesuatu

- **Pose atau arah**: ubah `SPEED` / `HEADINGS` di `base.py`, jalankan `base.py` untuk melihat papan, lalu `produce.py`.
- **Animasi baru** (lempar, meluncur, rem, berhenti; ART_DIRECTION 3.4): tambahkan opsi pose di `loper.build` dan baris baru di `produce.py`. Urutan baris yang sudah ada jangan diubah, karena `.tres` dan kode memakai nama animasi.
- **Frame dipoles manual**: simpan sebagai file terpisah dan catat di changelog ART_DIRECTION, karena render ulang menimpa sheet.
- Hasil render deterministik. Setelah mengubah kode yang seharusnya tidak mengubah tampilan, bandingkan sheet baru dengan yang lama piksel per piksel.
