# Log run 20261017-tabrakan-jatuh

Branch `feat/tabrakan-jatuh` dari `main` 82dbb9e. Keputusan pemilik 2026-10-17 mengubah K-1 run 3B: tabrakan membuat pemain **jatuh** memakai animasi jatuh yang sudah ada, lalu tetap bisa melanjutkan (prinsip 2 tetap). Rincian di bawah adalah **usulan orchestrator** yang bisa ditolak pemilik; semua angka usulan, belum diuji di HP.

## Aturan akhir

| Bagian | Aturan | Angka |
|---|---|---|
| Saat tabrakan | kecepatan langsung 0, rem padam, combo putus, bunyi tabrakan sekali, ikon kilatan | |
| Jatuh | kecepatan tetap 0, stick maju dan lateral diabaikan, stamina dan rem tidak berubah, swipe dan tap mode bantu ditolak tanpa memakai koran, garis bidik tidak tampil | `TABRAKAN_JATUH_DETIK` 1,2 |
| Bel selama jatuh | boleh (pilihan paling sederhana: tidak ada aturan tambahan; anjing yang mendekat tetap bisa diusir) | |
| Animasi | `jatuh_normal` 4 frame 10 fps sekali (0,4 detik), lalu `terjerembab_normal` 2 frame 3 fps berulang; semua arah memakai `normal` | fps dari sheet |
| Bangun | dikayuh lagi dari 0 dengan akselerasi biasa (santai lagi 1,0 detik kemudian; mode bantu melanjutkan sendiri); sprite langsung ke kayuh | |
| Kebal | dihitung dari saat BANGUN; selama jatuh pun tidak ada tabrakan kedua; kedip alpha 0,5 tiap 0,1 detik | `TABRAKAN_KEBAL_DETIK` 1,0 |
| Tanpa ganda | rintangan yang tersentuh saat tabrakan, selama jatuh, atau selama kebal menempel sampai sepeda terpisah darinya | |
| Tepi waktu | tepat 1,2 detik sesudah tabrakan = sudah bangun; tepat 1,0 detik sesudah bangun = kebal habis; langkah yang melewati akhir jatuh memakai sisa waktunya untuk gerak dan kebal | toleransi 0,000001 |
| Dihapus | oleng 0,6, turun ke 1,0 u/d, geser sprite ±1 px | `TABRAKAN_KECEPATAN_UD`, `TABRAKAN_OLENG_DETIK`, `TABRAKAN_OLENG_GESER_PX`, `TABRAKAN_OLENG_PERIODE_DETIK` |

Harga tabrakan pada santai: sekitar 1,7 detik tertinggal (jatuh 1,2 + akselerasi dari 0 yang tertinggal 1,5 ubin = 0,5 detik), dulu sekitar 0,6 detik (oleng). Simulasi AC-7 (bot sengaja menabrak 11 rintangan, seed 20261016-20261018): rute selesai 98,2 detik lawan santai murni 78,7; santai lagi paling lama 2,200 detik sesudah tiap tabrakan; `rute_selesai` tepat sekali.

## Aset

`tools/loper_art/bangun_frames.py` mendapat sumber keenam `jatuh/loper_agen_jatuh.json`; PNG/JSON disalin byte demi byte ke `assets/sprites/loper/`, `loper_agen_frames.tres` 50 animasi. Titik pijak (57, 51) di sel 114×68 berjarak (0, 17) dari tengah sel, sama dengan kayuh (23, 46) di 46×58, jadi offset (0, -17) sama (diverifikasi di `tes_sprite.gd` dan di tangkapan jendela asli). PNG tidak diedit. Fase 5: empat arah lain dan animasi bangkit.

## Mutan (semua dibunuh)

Dijalankan dengan skrip sementara yang mengganti satu baris lalu menjalankan `tests/run_tests.gd` penuh (baseline 9435 lolos, 0 gagal).

| Mutan | Berkas | Tes pembunuh (contoh) | Gagal |
|---|---|---|---|
| M1 kebal dihitung dari tabrakan, bukan dari bangun | `tabrakan.gd` | "kebal dari 1,2 sampai 2,1 detik, habis di langkah 22"; "tepat 1,2 detik: bangun, kebal 1,0 penuh" | 15 |
| M2 tidak ada perlindungan selama jatuh (hanya kebal) | `tabrakan.gd` | "rintangan yang menyentuh sejak masa jatuh menempel: tidak menabrak selama jatuh" | 4 |
| M3 `BikeMotion` mengabaikan `beku_detik` | `bike_motion.gd` | "12 langkah x 0,1 jatuh dengan stick penuh: kecepatan 0, jarak 0, lateral tetap" | 8 |
| M4 kecepatan turun ke 1,0, bukan 0 | `tabrakan.gd` | "6,0 -> 0 (jatuh)"; scene "saat sinyal: kecepatan sudah 0" | 4 |
| M5 lemparan tidak ditolak selama jatuh | `adegan_jalan.gd` | scene "swipe dan tap mode bantu selama jatuh ditolak: koran tetap 30"; "garis bidik tidak tampil" | 3 |
| M6 tepi frame 0,4 eksklusif | `loper_anim.gd` | "tepat 0,4 = terjerembab frame 0" (murni, LoperSprite, scene) | 3 |
| M7 sisa langkah sesudah bangun tidak dipakai kebal | `tabrakan.gd` | "satu langkah 1,5 detik: kebal 0,7"; "12 x 0,1 lalu 0,3 = satu langkah 1,5" | 2 |
| M8 sprite tidak menampilkan jatuh | `sepeda_uji.gd` | scene "langkah tabrakan: sprite jatuh_normal frame 0" | 5 |
| M9 tanpa menempel selama jatuh/kebal | `tabrakan.gd` | "rintangan yang menyentuh sejak masa jatuh menempel ... sesudahnya" | 1 |
| M10 scene tidak meneruskan sisa jatuh ke sepeda | `adegan_jalan.gd` | scene "selama jatuh: kecepatan 0, jarak dan lateral tidak berubah walau stick penuh ditahan" | 2 |
| M11 `LoperSprite` tidak menolak lempar selama jatuh | `loper_sprite.gd` | "lempar ditolak selama jatuh" | 4 |
| M12 lateral memakai seluruh dt (bukan sisa sesudah bangun) | `bike_motion.gd` | "dt 0,5 dengan sisa jatuh 0,2: lateral 0,9" | 2 |
| M13 terjerembab tidak berulang | `loper_anim.gd` | "12 saat x 5 arah" (1,0667 dan 1,2 = frame 0) | 2 |
| M14 rem tidak dipadamkan di `BikeMotion` selama jatuh | `bike_motion.gd` | "keadaan dengan rem menyala yang masuk jatuh: rem padam" (ditambah sesudah mutan ini lolos pada putaran pertama) | 1 |

## Tes lain yang berubah

- `tes_rute_scene.gd` kisi mode bantu: rintangan dikosongkan, karena tabrakan di sepanjang kisi kini menolak tap berikutnya (penolakan lemparan selama jatuh dites di `tes_rintangan_scene.gd`).
- AC-7: "kecepatan tidak pernah 0 sebelum akhir" diganti "kecepatan 0 hanya selama jatuh"; batas waktu rute kini santai murni + tabrakan × 2,2 + 5 (dulu + 20, yang hanya menyisakan 0,5 detik).

## Bukti visual

`godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_rintangan_jendela.gd -- build/shots_jatuh`: 0 keadaan tidak sesuai, keluaran tanpa ERROR/WARNING. Tiga gambar di `shots/`:

- `2340x1080_rintangan_tabrakan_jatuh.png`: 0,1 detik sesudah menabrak bagian belakang mobil yang berhenti, `jatuh_normal` frame 1 (terlempar lewat setang), roda dan bayangan di tanah pada titik pijak sepeda, ikon kilatan tampil, digambar di depan mobil (sepeda lebih dekat ke kamera).
- `2340x1080_rintangan_tabrakan_terjerembab.png`: `terjerembab_normal`, sepeda rebah di titik tabrakan, tubuh tengkurap ke depan menutupi bagian belakang mobil (Y-sort memakai titik pijak sepeda), tidak terpotong.
- `2340x1080_rintangan_tabrakan_bangun_kedip.png`: 0,15 detik sesudah bangun, sprite kayuh santai di titik pijak yang sama dengan alpha 0,5 (kebal), kecepatan 0,45 u/d.

## Belum diuji / perlu keputusan pemilik

- Rasa di HP (`SETUP_ANDROID.md` 8.7 butir 4): 1,2 detik adil dan tidak menyebalkan?
- Rincian usulan: bel boleh selama jatuh; stamina beku selama jatuh (tidak pulih); semua arah memakai gambar `normal`; bangun tanpa animasi bangkit.
- Tubuh yang terjerembab menjorok sekitar satu ubin ke depan; bila jatuh di depan rintangan tinggi, tubuh tampak menutupi rintangan itu. Penutup pemain (`PenutupPemain`) masih memakai kotak pemain tegak.
