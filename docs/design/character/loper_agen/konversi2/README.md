# Konversi gambar AI baru ke pixel art (konversi2)

Ilustrasi full body baru dari generator gambar (`sumber_ai.jpg`, 1792×2240) diubah jadi pixel art 240×292 px: palet terbatas, garis luar 1 px `#1B1226`, latar transparan, bayangan tanah dongker `#2E3550` 38% (sama dengan gaya skala besar, `docs/ART_DIRECTION.md` 3.5). Setelah konversi otomatis, beberapa bagian diubah dan digambar ulang dengan tangan.

Status: **disetujui Ronggur 2026-10-08** sebagai hasil konversi. Belum menggantikan gambar full body resmi `../loper_agen_fullbody.png`; keputusan itu dibahas di PR.

## Isi
- `loper_agen_konversi2.png`: 240×292 px, latar transparan, bayangan tanah sudah termasuk.
- `preview/loper_agen_konversi2_x3.png`: tampil ×3.
- `sumber_ai.jpg`: gambar sumber.

## Yang diubah dari gambar sumber
- **Kepala terpisah tanpa leher.** Garis dagu kiri melengkung (tegak di bawah telinga, landai ke dagu). Bagian belakang kerah dongker terlihat dan dinaikkan 2 px; kepala diturunkan 2 px sehingga dagu sedikit menumpuk kerah belakang. Ujung kerah menyambung ke bahu, bukaan V kecil.
- **Tas boncengan terbuka.** Tutup terlipat ke belakang, gesper kosong. Koran gulung yang tadinya di atas boncengan pindah ke dalam tas; hanya bagian atasnya yang terlihat.
- **Satu gir belakang.** Derailleur dibuang, rantai lurus dari gir belakang ke gir depan.
- **Dua engkol segaris**, 19 px dan lebih tebal. Engkol sisi dekat naik di depan penutup rantai hijau; engkol sisi seberang turun di belakang gir depan, lebih gelap. Urutan lapisan dari belakang: engkol sisi seberang, gir depan, penutup rantai, engkol sisi dekat.
- **Kabel rem tinggal dua.**
- Digambar ulang: roda dan jari-jari, rantai, tulisan "KORAN", gelang kuning, tali sepatu kiri.

## Beda dengan desain terkunci (ART_DIRECTION 3.1 dan 3.5)
- Sepeda pakai spakbor; desain tanpa spakbor.
- Tas boncengan hanya terlihat satu sisi.
- Pose: koran diangkat tinggi dan tangan kiri di samping badan, bukan koran dijepit di samping wajah dan tangan kiri di setang.
- Dagu menumpuk kerah belakang, bukan dipisah celah 2 px.

## Membuat ulang

```
pip install numpy pillow opencv-python scikit-learn
python3 tools/loper_art/fullbody/konversi2.py docs/design/character/loper_agen/konversi2/sumber_ai.jpg --out build/loper_art/konversi2
```

Hasilnya identik piksel per piksel dengan file di folder ini (dicek 2026-10-08). Langkah-langkahnya ada di `tools/loper_art/fullbody/konversi2/`; koordinat di tiap langkah khusus untuk gambar sumber ini.
