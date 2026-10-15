# Lisensi audio — Kring Kring! (Loper Koran)

Wajib menurut SOUND_DESIGN 6 dan 7: setiap berkas audio di `assets/audio/` dicatat di sini dengan sumber, lisensi, dan kewajiban atribusi. Berkas pihak ketiga (mis. CC0 dari Kenney atau Freesound) dicatat satu baris per berkas beserta tautan dan lisensinya saat pertama kali masuk; berkas yang dibuat sendiri juga dicatat supaya asalnya jelas.

## Dibuat sendiri (bukan pihak ketiga)

Ketiga berkas di bawah dibuat dari rumus oleh skrip project `tools/audio_art/sintesis_sepeda.py` (hanya pustaka standar Python, benih acak tetap, deterministik), **tanpa rekaman, sampel, atau unduhan apa pun**. Placeholder Fase 1 (run fase1b-umpan-balik, 2026-10-14), usulan; diganti bunyi final di fase aset. Jangan diedit dengan tangan: ubah skripnya lalu jalankan ulang (`tools/tests_cek/uji_sintesis_sepeda.py` memeriksa berkas di repo sama dengan keluaran skrip).

| Berkas | Isi | Durasi | Dibuat oleh | Lisensi |
|---|---|---|---|---|
| `sfx/bike/sfx_bike_pedal_loop.wav` | Ketukan rantai + hentakan pedal, loop (8 ketukan per detik = kayuh santai 8 fps) | 1,0 detik | `tools/audio_art/sintesis_sepeda.py` | Milik project, tanpa atribusi pihak ketiga |
| `sfx/bike/sfx_bike_freewheel_loop.wav` | "Tik-tik-tik" freewheel pelan, loop (10 tik per detik) | 1,0 detik | `tools/audio_art/sintesis_sepeda.py` | Milik project, tanpa atribusi pihak ketiga |
| `sfx/bike/sfx_bike_brake_01.wav` | Decit rem pendek, sekali putar | 0,45 detik | `tools/audio_art/sintesis_sepeda.py` | Milik project, tanpa atribusi pihak ketiga |

Ke-13 berkas di bawah dibuat dari rumus oleh skrip project `tools/audio_art/sintesis_lempar.py` (hanya pustaka standar Python, benih acak tetap, deterministik), **tanpa rekaman, sampel, atau unduhan apa pun**. Placeholder Fase 2 (run fase2b-bantu-audio, 2026-10-15), usulan; diganti bunyi final di fase aset. Jangan diedit dengan tangan: ubah skripnya lalu jalankan ulang (`tools/tests_cek/uji_sintesis_lempar.py` memeriksa berkas di repo sama dengan keluaran skrip).

| Berkas | Isi | Durasi | Dibuat oleh | Lisensi |
|---|---|---|---|---|
| `sfx/throw/sfx_throw_whoosh_01.wav` | "Wus" koran dilempar: desis pita sempit yang naik lalu turun | 0,20 detik | `tools/audio_art/sintesis_lempar.py` | Milik project, tanpa atribusi pihak ketiga |
| `sfx/throw/sfx_land_mailbox_01.wav`, `sfx_land_mailbox_02.wav`, `sfx_land_mailbox_03.wav` | "Tunk" logam pendek bernada naik (mendarat di kotak surat), tiga variasi | 0,17 / 0,20 / 0,23 detik | `tools/audio_art/sintesis_lempar.py` | Milik project, tanpa atribusi pihak ketiga |
| `sfx/throw/sfx_land_porch_01.wav`, `sfx_land_porch_02.wav`, `sfx_land_porch_03.wav` | "Plak" kertas renyah di lantai (mendarat di teras), tiga variasi | 0,16 / 0,19 / 0,22 detik | `tools/audio_art/sintesis_lempar.py` | Milik project, tanpa atribusi pihak ketiga |
| `sfx/throw/sfx_land_grass_01.wav`, `sfx_land_grass_02.wav`, `sfx_land_grass_03.wav` | "Puk" lembut redup (mendarat di rumput/halaman), tiga variasi | 0,15 / 0,17 / 0,19 detik | `tools/audio_art/sintesis_lempar.py` | Milik project, tanpa atribusi pihak ketiga |
| `sfx/throw/sfx_land_miss_01.wav`, `sfx_land_miss_02.wav`, `sfx_land_miss_03.wav` | "Plek" datar, lebih pelan (meleset: jalan, rumah salah, jendela penalti), tiga variasi | 0,14 / 0,15 / 0,16 detik | `tools/audio_art/sintesis_lempar.py` | Milik project, tanpa atribusi pihak ketiga |

## Pihak ketiga

Belum ada.
