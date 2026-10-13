# audio_art — bunyi placeholder dari rumus

Bunyi efek sementara yang dibuat dari rumus, bukan rekaman atau unduhan (SOUND_DESIGN 3.2 dan 8, SPEC run `20261014-fase1b-umpan-balik` D-4). **Hanya pustaka standar Python** (`wave`, `math`, `struct`, `random` dengan benih tetap), jadi tidak perlu `pip install`. Keluaran deterministik: dua kali jalan menghasilkan byte yang sama.

## Menjalankan

Dari root repo:

```
python3 tools/audio_art/sintesis_sepeda.py                  # tulis ke assets/audio/sfx/bike/
python3 tools/audio_art/sintesis_sepeda.py --out build/x    # tulis ke folder lain (perbandingan, uji)
python3 tools/tests_cek/uji_sintesis_sepeda.py              # bukti berkas di repo = keluaran skrip, format, loop tanpa klik
godot --headless --import                                   # impor ulang sesudah berkas berubah
```

Perubahan skrip dan WAV hasilnya masuk **commit yang sama** (rule `art-assets`, `git-workflow`). Jangan mengedit WAV dengan tangan.

## File

| File | Isi |
|---|---|
| `sintesis_sepeda.py` | Tiga WAV mono 16-bit 22050 Hz di `assets/audio/sfx/bike/`: `sfx_bike_pedal_loop.wav` (ketukan rantai 8 per detik + hentakan pedal tiap 0,25 detik, loop 1,0 detik), `sfx_bike_freewheel_loop.wav` (tik freewheel 10 per detik, loop 1,0 detik), `sfx_bike_brake_01.wav` (decit 2400 Hz dengan getar 7 Hz dan gesekan di awal, 0,45 detik). Puncak semua berkas sama (-1 dBFS); keras-pelan diatur di `scripts/config.gd` (`AUDIO_*_VOLUME_DB`) |

## Cara kerja singkat

- **Loop tanpa klik:** loop dibangun sebagai satu siklus utuh. Tiap ketukan ditempatkan di tengah selang waktunya dan meluruh jauh sebelum ujung; ekor yang melewati ujung dibungkus ke awal. Sampel awal dan akhir jadi tepat nol.
- **Ketukan:** semburan derau yang meluruh lewat resonator dua kutub (klik rantai sekitar 3200 Hz, tik freewheel sekitar 4600 Hz); hentakan pedal = sinus 170 Hz yang meluruh, kaki kanan dan kiri sedikit beda kuat.
- **Rem:** nada dasar 2400 Hz naik 4% sepanjang bunyi dengan getar 7 Hz, harmonik 2 dan 3, serangan 20 ms, lepas setengah kosinus 120 ms sampai nol, derau gesekan 60 ms di awal.
- **Impor Godot:** `.import` di samping tiap WAV: `compress/mode=0` (PCM, sama persis dengan berkas), `edit/loop_mode=2` (Forward) untuk dua loop dan `1` (Disabled) untuk rem.
- **Pitch kayuhan** (1,0 / 1,15 / 1,3 di santai / cepat / ngebut) diatur saat main oleh `BunyiSepeda` dan autoload `Audio`, bukan dipanggang di berkas. Akibatnya tempo ketukan ikut naik: 8 / 9,2 / 10,4 per detik, sedangkan animasi kayuh 8 / 10 / 12 fps (SOUND_DESIGN 3.2, catatan untuk uji HP).
