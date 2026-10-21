# Prompt Claude Design — Fase 5 (aset gelombang 1)

Disimpan 2026-10-20. Prompt untuk dijalankan di Claude Design; hasilnya adalah **kanvas usulan**, bukan aset yang langsung masuk `assets/`. Aturan repo (`.cursor/rules/art-assets.mdc`) melarang mengedit PNG dengan tangan, jadi kanvas itu diporting jadi skrip renderer di `tools/env_art/` (dengan uji deterministik seperti `tools/tests_cek/uji_aset_kucing.py`), lalu run Dev↔QA kecil memasang hasilnya di rute menggantikan placeholder dari kode.

Sumber isi: `docs/ART_DIRECTION.md` bagian 2 (gaya, palet), 4 (pipeline), 6 (daftar aset), 7 (penamaan). Perbarui prompt ini bila bagian itu berubah.

Yang sengaja **tidak** diminta:
- Animasi pemain (jatuh empat arah lain, bangkit, berhenti dengan kaki turun): dirender `tools/loper_art` di repo.
- Aset yang sudah dirender atau terpasang: rumah dua sisi, anjing, mobil garasi, antena TV, kotak surat, kucing misi, ubin jalan, lampu jalan, pohon, ikon HUD, tombol bel.

Butir 4 memuat angka dari keputusan pemilik 2026-10-17 (tembok belakang rendah 14 unit, rumah mundur 1,25 ubin). Keduanya masih usulan sampai uji HP.

```text
Buat kanvas desain "Aset Gelombang 1 (Fase 5) — Loper Koran": usulan pixel art untuk game 2D
mobile landscape bergaya Paperboy modern, isometrik 2:1, latar perumahan Indonesia.
Ini LANJUTAN kanvas "Lingkungan Loper Koran" dan "Karakter Loper Koran": gayanya harus satu
keluarga dengan keduanya.

ATURAN GAYA (wajib, berlaku untuk semua sprite)
- Gambar di ukuran piksel asli (1x), lalu tampilkan di kanvas diperbesar bilangan bulat
  (x3 atau x5) dengan image-rendering: pixelated. Tanpa anti-aliasing, tanpa skala pecahan,
  tanpa blur, tanpa gradien. Satu kepadatan piksel: pemain + sepeda setinggi 47 px, ubin
  belah ketupat 64x32 px.
- Proyeksi isometrik 2:1: sumbu x geser (+1,+0,5) px, sumbu y (-1,+0,5), tinggi z (0,-1).
  Jalan naik ke kanan atas. Cahaya dari KIRI ATAS. Kamera melihat sisi kanan sepeda.
- Garis luar 1 px #0E0A1C. Tiga nada per material (terang, dasar, gelap); gelap hanya di
  sisi membelakangi cahaya. Detail di bawah 2 px dibuang. Objek gameplay lebih kontras dari
  latar.
- Bayangan tanah: elips dipanggang dengan warna PENANDA #000000 alpha 71 (28%), digeser 1 px
  kanan bawah. Jangan pakai #000000 untuk hal lain.
- Palet induk (terang · dasar · gelap), pakai hanya ini kecuali benda memang baru:
  krem kertas #FBF6E8 · #F2E7C9 · #C2AF86; kulit #F2B98C · #E8A07A · #B47C5F;
  biru #9BC4D8 · #5F96C8 · #466E8C; dongker #7480A3 · #5C6A8C · #404A62;
  hijau #6FAE4F · #466E50 · #314D38; rumput #7DBB5A · #6FAE4F · #62A046;
  merah bata #B5523B · #994532 · #673F31; kayu #B47C5F · #96643C · #553428;
  logam #C4C0C8 · #969AA0 · #67636D; logam gelap #5F5B66 · #3D4649 · #221E26;
  aspal #6C6872 · #67636D, marka #F2E7C9; trotoar #DCCBA6 · #D5C4A1, kerb #A9A2AE;
  aksen hangat #FFE08A · #FFC94A · #E98E3F; pastel: pink #F0C8CD/#BB9C9F,
  krem #F6D6A0, hijau muda #C9E0A5/#9CAE80, biru muda #AADCF0/#90BBCC.
- Kuning #FFE08A/#FFC94A/#E98E3F = sasaran kotak surat; hijau = misi selesai; oranye =
  peringatan. JANGAN dipakai untuk dekorasi supaya tidak tertukar dengan petunjuk.

YANG SUDAH ADA (jangan digambar ulang, hanya jadi acuan keselarasan)
Sprite pemain Kemeja Agen, rumah seberang (limasan, pelana, sayap; pelanggan berwarna dan
bukan pelanggan abu-abu), belakang rumah sisi dekat, anjing penjaga, mobil keluar garasi,
antena TV, kotak surat (oranye sasaran, abu-abu bukan pelanggan), kucing misi belang tiga,
ubin jalan perumahan 64x32, lampu jalan, tiga jenis pohon, ikon HUD 14x14, tombol bel.

YANG DIMINTA (urut prioritas; tiap butir = satu papan di kanvas)

1. KORAN (M2)
   - Koran gulung berputar ~8x6 px, 4 frame (mendatar, serong naik, tegak, serong turun),
     12 fps.
   - Koran mendarat: tergeletak di teras, di rumput, dan masuk kotak surat (3 pose).
   - Koran terlipat di teras (pose "terantar").
   - Bayangan elips di tanah, 10 px mengecil sampai 6 px saat koran tinggi.
2. VFX DASAR (M2, tanpa garis luar bila semi-transparan)
   - Debu roda belakang: 4-6 frame, kotak 1-2 px krem #F2E7C9, melaju ke belakang
     sepanjang jalan 2:1.
   - Garis kecepatan: garis bertangga 2:1 (anak tangga 2x1 px) putih alpha 70%, 3 varian.
   - Koran kena sasaran: bintang kecil 4-6 frame, sekali putar, palet aksen hangat.
   - Tip / koin muncul: koin kecil naik + "+5", 4-6 frame.
   - Percikan genangan: 4-5 frame (M3, boleh dibuat terakhir).
3. PROPERTI & MISI (M2)
   - Tong sampah (2 varian warna, palette swap), tapak ~1/4 ubin.
   - Jejak kaki kucing di trotoar (2 varian) dan mangkuk makanan kucing.
   - Kilau petunjuk misi, 2 frame, 9x9 px, kuning hangat; harus terbaca di atas trotoar
     krem dan rumput.
   - Portal satpam + pos satpam kecil (M3, terakhir).
4. SISI DEKAT PRODUKSI (keputusan pemilik 2026-10-17: tembok/pagar belakang rendah)
   - Modul tembok belakang rendah di kaki kavling: tinggi 14 unit dunia, panjang 1 ubin,
     4 varian (polos, bata ekspos, pagar besi, tembok dengan pot) supaya bisa disambung
     tanpa kelihatan berulang. Rumah penuh berdiri 1,25 ubin di belakangnya.
   - Tampilkan satu jalan perumahan siang yang memakai modul ini di sisi dekat,
     bersama rumah seberang, supaya keterbacaan kotak surat dan jalur bisa dinilai.
5. UBIN TAMBAHAN (M3, bila waktu ada): polisi tidur, persimpangan, genangan (3 ubin 64x32,
   disusun dengan ubin jalan yang ada).

CARA MENYAJIKAN
- Satu papan per butir. Tiap sprite: tampil diperbesar x5, ada tampilan x3 di atas latar
  aspal, trotoar krem, dan rumput (uji keterbacaan), dan label ukuran piksel + titik pijak
  (ground anchor) di tanah.
- Untuk setiap sprite tulis tabel: nama file (snake_case, awalan kategori: prop_, vfx_,
  mission_, tile_, house_), ukuran sel, jumlah frame, fps, titik pijak (x,y).
- Satu papan komposisi akhir: jalan perumahan siang x3 dengan SEMUA aset baru dipasang
  (sisi seberang + sisi dekat), lalu versi sore dengan bayangan #5A2E3A.
- Beri tiap aset label "usulan", dan di bawah papan tulis satu paragraf catatan: apa yang
  kamu ragukan (misalnya terlalu kecil di x3, atau mirip warna petunjuk misi).
- Gambar sprite dengan kode (kotak, prisma, rumus piksel) atau grid piksel eksplisit supaya
  bisa saya porting ke renderer Python; JANGAN pakai gambar generatif (AI image) karena
  tidak konsisten antar frame dan lisensinya tidak jelas.

JANGAN
- Mengubah desain, proporsi, atau titik pijak sprite pemain (46x58 sel, pijak 23,46).
- Memakai aset dari game lain atau menyalin gaya persis game tertentu.
- Menambah palet baru bila palet induk sudah cukup.
```

## Hasil (2026-10-20, usulan)

- Kanvas Claude Design: "Aset Gelombang 1 (Fase 5) — Loper Koran" (enam papan: komposisi siang/sore, koran, VFX, properti dan misi, sisi dekat, ubin), digambar dengan kode tanpa gambar generatif.
- Port renderer: `tools/env_art/gelombang1/` (lihat `tools/env_art/README.md`), 29 sprite 1× + JSON per sprite + `manifest.json` ke `build/env_art/gelombang1/sprites/`, mock di `docs/design/environment/gelombang1/`. Uji: `tools/tests_cek/uji_aset_gelombang1.py` (deterministik, palet induk, manifest, mock = hasil skrip), juga di CI.
- Komposisi repo memakai geometri game, bukan geometri kanvas: tembok sisi dekat berpusat 100 unit dari garis tengah (`TEMBOK_X_UBIN` 3,125, `scripts/dev/spike_sisi_dekat.gd`), rumah dekat varian `bukan` mundur 40 unit, kotak surat seberang = `prop_kotak_surat` oranye dan `prop_kotak_surat_bukan`. Di kanvas kotak surat lama masih merah dan tembok jatuh di pojok layar.
- Belum: salin ke `assets/sprites/{props,vfx,houses/perumahan,tiles/perumahan}/` dan pasang di rute menggantikan placeholder dari kode (`pola_piksel.gd`, `umpan_balik_sepeda.gd`, zona graybox), run Dev↔QA berikutnya.
- Keraguan yang perlu diputuskan pemilik ada di ART_DIRECTION 11 ("Aset gelombang 1").

## Hasil pemasangan (Run 5A, 2026-10-21, usulan)

- Run Dev↔QA `20261021-fase5a-pasang-aset-gelombang1` memasang 13 sprite dan 7 ubin dari renderer ke rute perumahan (`render.py --salin`, `ubin_perumahan.py --salin`; hanya yang dipasang, uji `uji_aset_pasang_gelombang1.py`): enam kolom ubin, koran (putar, bayangan menurut tinggi, tergeletak menurut permukaan, terlipat), debu roda, garis kecepatan, bintang kena, koin tip, dan kilau misi. Hanya tampilan.
- Keputusan K-1 diterapkan di renderer: kilau dua warna, tong sampah abu-abu logam (hijau dibuang), satu polisi tidur (gelombang 1).
- Belum dipasang: tong sampah, jejak, mangkuk, portal, pos, tembok sisi dekat, percikan, polisi tidur, zebra, genangan (5B dan M3).
- Penilaian visual di HP: SETUP_ANDROID 8.12. Keraguan yang tercatat: bayangan 28% di aspal, lajur hijau trotoar lawan penanda misi selesai, debu dan garis yang tipis di x3, kilau di atas atap putih, letak koran terlipat terhadap teras sprite rumah. Detail di `docs/loop/20261021-fase5a-pasang-aset-gelombang1/LOG.md` dan ART_DIRECTION 11.

## Hasil pemasangan (Run 5B, 2026-10-21, usulan)

- Run Dev↔QA `20261021-fase5b-tembok-dekor` memasang 23 aset lagi dari renderer ke rute perumahan lewat `--salin` ketiga skrip (`render.py`, `lampu_pohon.py`, `ubin_perumahan.py`; hanya yang dipasang, uji `uji_aset_pasang_5b.py` dan `uji_aset_lampu_pohon.py`): lima modul tembok sisi dekat, tong sampah logam, tiga pohon, dua sprite lampu mati, dan enam ubin (`rumput_2`, `rumput_3`, jalan masuk garasi trotoar dan rumput seberang, simbol sepeda di kedua trotoar). Hanya tampilan dan data dekor (bidang `dekor` di sembilan segmen).
- Putusan: tembok berpusat 3,125 dan rumah dekat digambar mundur 1,25 ubin (tapak logika tidak berubah); `aspal_1..3` tidak dipasang (polos tanpa garis tepi kerb, memutus garis); tong biru dan lampu nyala tidak dipasang.
- Belum dipasang: tong sampah biru, bingkai lampu nyala, pohon dan lampu jenis lain, `*_dekat_masuk`, `aspal_N`, jejak, mangkuk, portal, pos, percikan, polisi tidur, zebra, genangan (M3, 5C).
- Penilaian visual di HP: SETUP_ANDROID 8.13. Keraguan yang tercatat: varian `pot` menutupi 13,1% zona kotak surat dekat, tong abu-abu lawan kotak surat abu-abu, bayangan baked pohon dan lampu selalu ke kanan bawah, ujung kerb di tepi jalan masuk garasi (22 piksel, ubin ujung kerb 5C). Detail di `docs/loop/20261021-fase5b-tembok-dekor/LOG.md` dan ART_DIRECTION 11.
