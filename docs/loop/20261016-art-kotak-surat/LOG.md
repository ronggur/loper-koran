# LOG art-kotak-surat (2026-10-16)

Branch `art/kotak-surat-rute`, dari `main` setelah PR #28. Status: **usulan, belum diaudit QA**. Tidak ada keputusan yang dikunci;
`docs/DEV_PHASES.md` tidak dicentang.

## Permintaan pemilik

Kotak surat sasaran di scene rute adalah kubus graybox oranye. Pemilik menyukai BENTUK kotak surat merah yang dulu ada di teras
sprite rumah (`lib.kotak_surat`: tiang `metal_dk` + badan dengan celah surat) dan tidak keberatan warnanya oranye seperti sekarang.
Jadi kubus diganti sprite kotak surat berbentuk itu, berwarna oranye.

## Keputusan

- **A-1 (sprite lewat alat).** `tools/env_art/fase3.py`: `kotak_surat_oranye(s)` memanggil `lib.kotak_surat(s, 0, 0, mat=KOTAK_SURAT_ORANYE)`;
  dirender `render_sprite` seperti sprite rumah (garis luar `#0E0A1C`, cahaya kiri atas, bayangan tanah penanda alfa 71), skala 1x,
  ukuran `lib.kotak_surat` apa adanya. Keluaran `prop_kotak_surat.png` (30x39) + `.json` (`ground_anchor` 10,26 = kaki tiang).
  PNG tidak diedit tangan. Disalin ke folder baru `assets/sprites/props/` lewat `SALIN_SPRITE`.
- **A-2 (warna).** Mat tiga nada = `KOTAK_SURAT` di `tools/env_art/graybox.py` (`#FFE08A`, `#FFC94A`, `#E98E3F`). Catatan: karena
  cahaya kiri atas, fasad menghadap kanan bawah (sisi bercelah) dipanggang lebih gelap (`#8B5833`, kecoklatan); atas dan sisi samping
  tetap `#FFE08A` dan `#FFC94A`. Tidak diubah karena permintaan menyebut nada graybox yang sama; bila terasa kurang oranye di HP,
  naikkan nada ketiga di `KOTAK_SURAT_ORANYE`.
- **A-3 (scene).** `scenes/entities/kotak_surat.tscn`: `Sprite2D`, `texture_filter = 1`, `centered = false`, offset = -`ground_anchor`
  (-10, -26), jadi `position` node = kaki tiang. `scenes/rute/rute.tscn` memakainya sebagai `adegan_kotak_surat`.
  `scenes/dev/jalan_uji.tscn`, `kotak_surat_graybox.tscn`, dan `ObjekDaur` tidak diubah (jalan uji tetap kubus graybox).
  Posisi tetap dari `SpriteRumah.titik_kotak_surat_dunia` (tidak diubah); `RumahDaurRute` hanya dapat komentar baru.
- **A-4 (urutan gambar).** Tidak ada perubahan struktur: `AreaKotak` di bawah `Objek`, jadi area oranye tipis tidak menutupi kotak
  surat; kotak surat Y-sort di depan sprite rumahnya (y layar lebih besar dari pusat tapak). Dijaga tes.
- **A-5 (selisih letak, dicatat, tidak diubah).** `titik_kotak_surat_dunia` memakai `Config.JALAN_UJI_KOTAK_SURAT_*` (-1,5; +1,0 dari
  awal kavling), sedangkan pusat area zona rute 1,0 x 1,5 adalah (-1,625; +1,125) (D-28). Selisihnya 0,125 ubin per sumbu,
  sekitar 4 px di layar (kaki tiang sedikit di atas pusat area), tetap di dalam area. Permintaan melarang mengubah posisi
  dan angka itu dipakai bersama jalan uji; kalau ingin tepat di pusat, ubah di run terpisah (config + tes jalan uji).
- **A-6 (tanpa angka ajaib).** Tidak ada `const` baru di `config.gd`; offset sprite ada di scene (seperti graybox), dan skrip tidak
  menyebut berkas sprite atau titik pijak (dites).

## Bukti

- `godot --headless --import` lalu `run_tests.gd`: 8340 lolos, 0 gagal; `cek_keluaran_tes.py` dan `--ketat` lolos (0 peringatan).
  Tes baru `tests/tes_kotak_surat.gd` (didaftarkan di `run_tests.gd`): JSON `size`/`ground_anchor` = PNG dan literal, kaki tiang dari
  piksel PNG, nada oranye dan garis luar ada, scene (Nearest, tanpa centered, offset), rute memakai sprite baru dan jalan uji tetap
  graybox, `exclude_filter` tidak mengecualikan sprite/JSON/scene, pijak tiang di dalam zona dan kotak surat di depan rumah di scene
  berjalan.
- Mutan nyata (semua GAGAL lalu dipulihkan): (1) `rute.tscn` kembali ke graybox: 2 gagal; (2) offset scene -25 bukan -26: 3 gagal;
  (3) `ground_anchor` JSON 27: 2 gagal; (4) `jalan_uji.tscn` ikut memakai sprite baru: 1 gagal.
- `godot --headless --path . --quit-after 2`: tanpa ERROR/WARNING. Empat `tools/tests_cek/uji_*.py` lolos.
- Visual (`shots/2340x1080_rute_tengah.png`, `shots/2340x1080_rute_bantu_centang.png`): di x3 bentuk kotak surat (tiang gelap
  dan badan oranye dengan celah) terbaca jelas di tengah area oranye tipis, tidak tertutup rumah, area, atau sepeda, dan penanda
  centang hijau tetap terbaca di badan kotak surat.

## Drift renderer yang dikembalikan

`fase3.py --salin` di mesin ini mengubah piksel berkas tak terkait; semuanya dikembalikan dengan `git checkout --`, tidak masuk
commit: sembilan PNG di `assets/sprites/houses/perumahan/` (enam `house_perumahan_dekat_*`, `house_perumahan_limasan_bukan`,
`house_perumahan_pelana_bukan`, `house_perumahan_sayap_bukan`), `assets/sprites/obstacles/obs_anjing_sheet.png` dan
`obs_mobil_garasi_sheet.png`, serta lima mock `docs/design/environment/fase3_*.png`. Sprite rumah tidak diubah. Hanya
`prop_kotak_surat.*` (+ `.import`) yang masuk.

## Belum

Belum diaudit QA. Belum dinilai pemilik di HP (SETUP_ANDROID 8.6 butir 3, 4, 9). Warna dan gambar final menunggu Fase 5.
