# Lisensi aset pihak ketiga — Kring Kring! (Loper Koran)

Setiap aset pihak ketiga yang masuk ke repo dicatat di sini: nama file, sumber (URL dan versi), lisensi, dan kewajiban atribusi (ART_DIRECTION 9). Tambahkan satu entri tiap kali mengunduh aset baru. Tidak ada aset dari Brainy Dungeon di repo ini: itu hanya acuan gaya.

## Ringkasan

| File di repo | Sumber | Lisensi | Status |
|---|---|---|---|
| `assets/fonts/lexend/lexend_variable.ttf` | google/fonts, `ofl/lexend/Lexend[wght].ttf` | SIL OFL 1.1 | **usulan (belum dikunci)**, ART_DIRECTION 11 |
| `assets/fonts/lilita_one/lilita_one_regular.ttf` | google/fonts, `ofl/lilitaone/LilitaOne-Regular.ttf` | SIL OFL 1.1 | **usulan (belum dikunci)**, ART_DIRECTION 11 |

## Font

Kedua font berstatus **usulan** (DESIGN_SPEC 1.2, ART_DIRECTION 11): dikunci atau diganti setelah keterbacaannya dicek di HP. Dipakai sebagai berkas aslinya tanpa diubah; hanya nama file yang diganti ke `snake_case` mengikuti rule `art-assets`. Nama internal font di dalam berkas tidak berubah.

### Lexend

| | |
|---|---|
| File di repo | `assets/fonts/lexend/lexend_variable.ttf` (nama asal `Lexend[wght].ttf`, font variabel sumbu bobot), `assets/fonts/lexend/OFL.txt` |
| Sumber | https://github.com/google/fonts/tree/2eb0b48d5f760f62e286216f0859a8c540dbc1bd/ofl/lexend |
| Hash commit hulu | `2eb0b48d5f760f62e286216f0859a8c540dbc1bd` (google/fonts, commit 2026-10-08), diunduh 2026-10-09 |
| SHA-256 | `lexend_variable.ttf` `3add53e641fbc81da64da4bb254285e2831b52b029527bc0714e2b9610832ee6`, `OFL.txt` `5da8505887d0fa7fe963445fd58852707fda34adfeb65af25c99d152bab285bd` |
| Lisensi | SIL Open Font License 1.1 (teks lengkap di `OFL.txt`) |
| Hak cipta | Copyright 2018 The Lexend Project Authors (https://github.com/googlefonts/lexend), Reserved Font Name "RevReading Lexend" |
| Kegunaan | Angka dan teks HUD, label (DESIGN_SPEC 1.2): Regular dan SemiBold lewat sumbu bobot |

### Lilita One

| | |
|---|---|
| File di repo | `assets/fonts/lilita_one/lilita_one_regular.ttf` (nama asal `LilitaOne-Regular.ttf`), `assets/fonts/lilita_one/OFL.txt` |
| Sumber | https://github.com/google/fonts/tree/2eb0b48d5f760f62e286216f0859a8c540dbc1bd/ofl/lilitaone |
| Hash commit hulu | `2eb0b48d5f760f62e286216f0859a8c540dbc1bd` (google/fonts, commit 2026-10-08), diunduh 2026-10-09 |
| SHA-256 | `lilita_one_regular.ttf` `f5b641c45c69d772ee4eda687bc9fda411d5cad6b0b45371491da4580cbc8d59`, `OFL.txt` `255d5debbb80eb2ea762644311f266a279e8778f00156655a516e2b7781a63e1` |
| Lisensi | SIL Open Font License 1.1 (teks lengkap di `OFL.txt`) |
| Hak cipta | Copyright (c) 2011 Juan Montoreano (juan@remolacha.biz), Reserved Font Name "Lilita" |
| Kegunaan | Judul layar dan headline koran (DESIGN_SPEC 1.2) |

### Kewajiban atribusi font (OFL 1.1)

- Boleh dipakai, dipaketkan, dan dijual bersama game, asalkan font tidak dijual sendirian dan teks lisensi OFL serta pernyataan hak cipta di atas ikut disertakan. `OFL.txt` di samping tiap font sudah memenuhi syarat itu di repo.
- Saat rilis, cantumkan nama font, penulis hak cipta, dan lisensinya di layar Kredit atau layar lisensi pihak ketiga game (dikerjakan di Fase 14; belum ada layarnya di Fase 0).
- Nama Reserved Font ("RevReading Lexend", "Lilita") tidak boleh dipakai untuk versi font yang diubah. Berkas di sini tidak diubah, jadi syarat ini tidak berlaku selama font dipakai apa adanya.

## Bukan pihak ketiga (dibuat sendiri, dicatat supaya jelas)

- Sprite pemain Kemeja Agen: dirender oleh `tools/loper_art/`, salinan di `assets/sprites/loper/`.
- Ubin dan kotak graybox: dirender oleh `tools/env_art/graybox.py`, di `assets/sprites/_placeholder/`.
- Token warna dan palet induk (`scripts/ui/palette.gd`, `assets/palette/loper_master.gpl`): dari dokumen desain repo ini (ART_DIRECTION 2.4 dan DESIGN_SPEC 1.1), berstatus usulan.

## Godot Engine

Godot Engine 4.7.2 berlisensi MIT, dengan komponen pihak ketiga yang punya lisensi sendiri. Teks lisensi dan hak ciptanya tersedia lewat `Engine.get_license_text()` dan `Engine.get_copyright_info()` dan wajib dicantumkan di layar Kredit saat rilis (Fase 14).
