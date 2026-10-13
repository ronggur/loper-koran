# Lisensi audio — Kring Kring! (Loper Koran)

Wajib menurut SOUND_DESIGN 6 dan 7: setiap berkas audio di `assets/audio/` dicatat di sini dengan sumber, lisensi, dan kewajiban atribusi. Berkas pihak ketiga (mis. CC0 dari Kenney atau Freesound) dicatat satu baris per berkas beserta tautan dan lisensinya saat pertama kali masuk; berkas yang dibuat sendiri juga dicatat supaya asalnya jelas.

## Dibuat sendiri (bukan pihak ketiga)

Ketiga berkas di bawah dibuat dari rumus oleh skrip project `tools/audio_art/sintesis_sepeda.py` (hanya pustaka standar Python, benih acak tetap, deterministik), **tanpa rekaman, sampel, atau unduhan apa pun**. Placeholder Fase 1 (run fase1b-umpan-balik, 2026-10-14), usulan; diganti bunyi final di fase aset. Jangan diedit dengan tangan: ubah skripnya lalu jalankan ulang (`tools/tests_cek/uji_sintesis_sepeda.py` memeriksa berkas di repo sama dengan keluaran skrip).

| Berkas | Isi | Durasi | Dibuat oleh | Lisensi |
|---|---|---|---|---|
| `sfx/bike/sfx_bike_pedal_loop.wav` | Ketukan rantai + hentakan pedal, loop (8 ketukan per detik = kayuh santai 8 fps) | 1,0 detik | `tools/audio_art/sintesis_sepeda.py` | Milik project, tanpa atribusi pihak ketiga |
| `sfx/bike/sfx_bike_freewheel_loop.wav` | "Tik-tik-tik" freewheel pelan, loop (10 tik per detik) | 1,0 detik | `tools/audio_art/sintesis_sepeda.py` | Milik project, tanpa atribusi pihak ketiga |
| `sfx/bike/sfx_bike_brake_01.wav` | Decit rem pendek, sekali putar | 0,45 detik | `tools/audio_art/sintesis_sepeda.py` | Milik project, tanpa atribusi pihak ketiga |

## Pihak ketiga

Belum ada.
