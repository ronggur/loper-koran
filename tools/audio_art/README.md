# audio_art — bunyi placeholder dari rumus

Bunyi efek sementara yang dibuat dari rumus, bukan rekaman atau unduhan (SOUND_DESIGN 3.1, 3.2, 4.2, dan 8; SPEC run `20261014-fase1b-umpan-balik` D-4, run `20261015-fase2b-bantu-audio` D-9, dan run `20261017-fase3b-rintangan-skor` AC-19). **Hanya pustaka standar Python** (`wave`, `math`, `struct`, `random` dengan benih tetap), jadi tidak perlu `pip install`. Keluaran deterministik: dua kali jalan menghasilkan byte yang sama.

## Menjalankan

Dari root repo:

```
python3 tools/audio_art/sintesis_sepeda.py                  # tulis ke assets/audio/sfx/bike/
python3 tools/audio_art/sintesis_sepeda.py --out build/x    # tulis ke folder lain (perbandingan, uji)
python3 tools/tests_cek/uji_sintesis_sepeda.py              # bukti berkas di repo = keluaran skrip, format, loop tanpa klik
python3 tools/audio_art/sintesis_lempar.py                  # tulis 13 WAV lempar dan mendarat ke assets/audio/sfx/throw/
python3 tools/audio_art/sintesis_lempar.py --out build/y    # tulis ke folder lain
python3 tools/tests_cek/uji_sintesis_lempar.py              # bukti berkas di repo = keluaran skrip, durasi, meleset lebih pelan, variasi beda, tanpa klik
python3 tools/audio_art/sintesis_rute.py                    # tulis 10 WAV rintangan, tabrakan, bel, tip, tepat ke assets/audio/sfx/{obstacle,bell,ui}/
python3 tools/audio_art/sintesis_rute.py --out build/z      # tulis ke folder lain (subfolder sama)
python3 tools/tests_cek/uji_sintesis_rute.py                # bukti berkas di repo = keluaran skrip, durasi, tabrakan lebih pelan, bel beda, tip diawali senyap
godot --headless --import                                   # impor ulang sesudah berkas berubah
```

Perubahan skrip dan WAV hasilnya masuk **commit yang sama** (rule `art-assets`, `git-workflow`). Jangan mengedit WAV dengan tangan.

## File

| File | Isi |
|---|---|
| `sintesis_lempar.py` | 13 WAV mono 16-bit 22050 Hz di `assets/audio/sfx/throw/`, semuanya sekali putar: `sfx_throw_whoosh_01.wav` ("wus" 0,20 detik: derau lewat pita 650 Hz yang pusatnya naik dari 700 ke 2200 Hz lalu turun, keras-pelan sin²), `sfx_land_mailbox_0{1,2,3}.wav` ("tunk" logam 0,17 / 0,20 / 0,23 detik: empat parsial tak harmonis dari nada dasar 520 / 600 / 690 Hz yang naik 12% dalam sekitar 30 ms, plus ketukan 3100 Hz), `sfx_land_porch_0{1,2,3}.wav` ("plak" kertas 0,16 / 0,19 / 0,22 detik: tamparan derau tinggi di 2600 / 3000 / 3500 Hz, 2 / 3 / 4 gemeresik, dentum badan 150–190 Hz), `sfx_land_grass_0{1,2,3}.wav` ("puk" 0,15 / 0,17 / 0,19 detik: derau lolos-bawah + dentum 105 / 122 / 140 Hz, serangan lunak 8 ms), `sfx_land_miss_0{1,2,3}.wav` ("plek" datar 0,14 / 0,15 / 0,16 detik: derau pita 950 / 1150 / 1350 Hz + nada 260–340 Hz). Puncak "wus" dan tiga permukaan -1 dBFS, meleset 0,5 (sekitar -6 dBFS, 5 dB lebih pelan); keras-pelan saat main di `scripts/config.gd` (`AUDIO_WUS_VOLUME_DB`, `AUDIO_MENDARAT_VOLUME_DB`) |
| `sintesis_rute.py` | 10 WAV mono 16-bit 22050 Hz sekali putar (run 3B): `obstacle/sfx_obs_dog_growl.wav` (geraman 0,80 detik: tiga harmonik 95 Hz dengan getar amplitudo 23 Hz + desis), `obstacle/sfx_obs_dog_bark_01.wav` (dua "guk" 0,42 detik: gergaji lima harmonik turun 520 ke 300 Hz + derau forman 1300 Hz), `obstacle/sfx_obs_car_beep.wav` (tiga bip 1100 Hz 0,25 detik tiap 0,5 detik, 1,5 detik = lama tanda mobil), `obstacle/sfx_obs_car_engine.wav` (gemuruh 55 Hz berdenyut 12 Hz, 1,0 detik), `obstacle/sfx_obs_crash_01.wav` (tabrakan lembut 0,45 detik: dentum 70 Hz + tiga kerincing, puncak 0,63 = sekitar 3 dB lebih pelan), `bell/sfx_bike_bell_0{1,2,3}.wav` ("kring" 0,40 / 0,36 / 0,44 detik: empat parsial tak harmonis dari 2100 / 2350 / 1900 Hz, getar pemukul 32 Hz), `ui/sfx_ui_tip_01.wav` (denting 1568 Hz, diawali 0,12 detik senyap), `ui/sfx_ui_tepat_01.wav` (dua nada naik 1319 lalu 1976 Hz, diawali 0,05 detik senyap). "Kring kring!" memakai variasi berikutnya dengan pitch +1 setengah nada saat main (`BunyiRute.pitch_bel`), bukan berkas lain |
| `sintesis_sepeda.py` | Tiga WAV mono 16-bit 22050 Hz di `assets/audio/sfx/bike/`: `sfx_bike_pedal_loop.wav` (ketukan rantai 8 per detik + hentakan pedal tiap 0,25 detik, loop 1,0 detik), `sfx_bike_freewheel_loop.wav` (tik freewheel 10 per detik, loop 1,0 detik), `sfx_bike_brake_01.wav` (decit 2400 Hz dengan getar 7 Hz dan gesekan di awal, 0,45 detik). Puncak semua berkas sama (-1 dBFS); keras-pelan diatur di `scripts/config.gd` (`AUDIO_*_VOLUME_DB`) |

## Cara kerja singkat

- **Loop tanpa klik:** loop dibangun sebagai satu siklus utuh. Tiap ketukan ditempatkan di tengah selang waktunya dan meluruh jauh sebelum ujung; ekor yang melewati ujung dibungkus ke awal. Sampel awal dan akhir jadi tepat nol.
- **Ketukan:** semburan derau yang meluruh lewat resonator dua kutub (klik rantai sekitar 3200 Hz, tik freewheel sekitar 4600 Hz); hentakan pedal = sinus 170 Hz yang meluruh, kaki kanan dan kiri sedikit beda kuat.
- **Rem:** nada dasar 2400 Hz naik 4% sepanjang bunyi dengan getar 7 Hz, harmonik 2 dan 3, serangan 20 ms, lepas setengah kosinus 120 ms sampai nol, derau gesekan 60 ms di awal.
- **Sekali putar tanpa klik (lempar dan mendarat):** serangan setengah kosinus 3 ms (rumput 8 ms) dari tepat nol dan lepas setengah kosinus 30 ms sampai tepat nol; "wus" memakai sin² penuh. Sampel pertama dan terakhir tepat nol.
- **Variasi:** tiga variasi tiap permukaan berbeda nada, warna, dan panjang (diperiksa `uji_sintesis_lempar.py`: byte, panjang, dan laju lintas nol berbeda berpasangan). Pemilihan saat main bergiliran 01, 02, 03, 01 per permukaan (`scripts/systems/bunyi_lempar.gd`), tanpa acak.
- **Impor Godot:** `.import` di samping tiap WAV: `compress/mode=0` (PCM, sama persis dengan berkas), `edit/loop_mode=2` (Forward) untuk dua loop dan `1` (Disabled) untuk rem, ke-13 bunyi lempar dan mendarat, dan ke-10 bunyi rute. Godot membuat `.import` dengan `compress/mode=2` dan `edit/loop_mode=0`; sesudah berkas baru pertama diimpor, kedua nilai diubah lalu diimpor ulang (hapus hasil lama di `.godot/imported/` bila perlu).
- **Pitch kayuhan** (1,0 / 1,15 / 1,3 di santai / cepat / ngebut) diatur saat main oleh `BunyiSepeda` dan autoload `Audio`, bukan dipanggang di berkas. Akibatnya tempo ketukan ikut naik: 8 / 9,2 / 10,4 per detik, sedangkan animasi kayuh 8 / 10 / 12 fps (SOUND_DESIGN 3.2, catatan untuk uji HP).
