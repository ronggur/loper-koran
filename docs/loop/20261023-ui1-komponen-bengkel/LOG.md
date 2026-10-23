# Loop Log — 20261023-ui1-komponen-bengkel
Scope: Run UI-1 — redesain UI langkah 1-2 (komponen + bengkel tata C)  ·  Branch: feat/ui1-komponen-bengkel  ·  Mulai: 2026-10-23  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi saat ini: 1/2, Dev bagian A selesai; bagian B berikutnya)

## Lingkungan (orchestrator, awal run)
- `main` = `origin/main` = `b99f5a9` (rilis 0.6.0; memuat PR #61, #62, #63). Branch dibuat dari sana.
- Godot 4.7.2 di `/opt/homebrew/bin/godot`; python3 dengan numpy 2.5.3 dan pillow 12.3.0; `cv2`/`sklearn` TIDAK terpasang (hanya dibutuhkan `latar_bengkel.py` membuat ulang latar; `--salin` hanya menyalin berkas jadi tidak perlu).
- `adb devices`: tidak ada perangkat tersambung (vivo/A54 belum dicolok). Pemasangan APK menunggu perangkat tersambung dan QA PASS.
- sha256 save asli `Kring Kring!/save.json` awal run: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`.
- `.claude/` untracked di working tree: bukan bagian run, tidak di-commit.

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | (bagian A, B, C belum) | | | | |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## Baseline (AC-1; diisi Dev bagian A langkah 1)
Diambil di pohon kerja yang belum berubah selain `docs/loop/` (HEAD `0b34f64`, setara `main` `b99f5a9`), 2026-10-23, satu proses Godot sekaligus.
- `godot --headless --import`: selesai tanpa error; `git status` bersih (selain `.claude/` yang tidak di-commit).
- `run_tests.gd`: **20371 lolos, 0 gagal**; `tools/cek_keluaran_tes.py build/tests.log`: lolos (20371 lolos, 0 gagal, 0 peringatan), exit 0.
- `godot --headless --path . --quit-after 2`: tanpa ERROR/WARNING.
- Semua `tools/tests_cek/uji_*.py` exit 0 (17 skrip): aset_fase3 148, aset_gelombang1 352, aset_kucing 13, aset_lampu_pohon 183, aset_pasang_5b 595, aset_pasang_gelombang1 565, aset_simpang 214, bangun_frames 62, pemeriksa 16 kasus 0 menyimpang, sintesis_kondisi 55, sintesis_lempar 111, sintesis_milestone 18, sintesis_misi 47, sintesis_rute 90, sintesis_sepeda 32, ui_lencana 25, ui_redesain LOLOS.
- sha256 save asli (`~/Library/Application Support/Godot/app_userdata/Kring Kring!/save.json`): `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (sama dengan awal run; diperiksa lagi sesudah probe jendela).
- Tangkapan "sebelum" untuk bukti piksel-identik (AC-4): `probe_hud_rute_jendela.gd` di 1920x1080 (10 PNG: HUD awal, radar, jeda dengan sakelar, layar hasil, kidal, dst.) disimpan di scratchpad `sebelum/`; dibandingkan dengan keluaran sesudah perubahan.

## Bagian A — komponen (Dev, iterasi 1; commit 4204b25, dc2e4c5, f3655ef)
**Set aset terpasang** (daftar tunggal `tools/ui_art/redesain/pasang.py`; diputuskan dari papan `Bengkel.dc.html`, `Bengkel_Tingkat.dc.html`, `Spesifikasi.dc.html`) di `assets/sprites/ui/`, 30 berkas + `.import`:
- Tombol: 8 bingkai `ui_btn_{utama,utama_tekan,biasa,biasa_tekan,sakelar_nyala,tenang,tenang_tekan,nonaktif}` + `ui_arsir_nonaktif` (sakelar mati memakai `btn_biasa`; kanvas tidak punya `btn_sakelar_tekan`, `btn_biasa_tekan` dipakai).
- Panel dan kartu: `ui_panel_layar`, `ui_kartu_{biasa,menonjol,redup}`; chip: `ui_chip_{gelap,ok,warn,netral,aksen}` (kelimanya dipakai kanvas bengkel). `panel_hud` TIDAK dipasang ulang (sudah ada `ui_panel_hud_9slice.png`).
- `ui_bengkel_papan_alat`, `ui_bengkel_sepeda_kecil.png` + `ui_bengkel_sepeda.json` (salinan byte `sepeda.json`), `ui_bengkel_latar_800.png`.
- Ikon 24 (potongan sel dari sheet `ikon24`, piksel sama): `ui_icon24_{ban,rem,rantai}` (hanya tiga yang dipakai kartu servis dan upgrade). Glif 12 (potongan sel `glif12` per warna): `ui_glif_{seru_warn,centang_ok,centang_teks2,kunci_terang,panah_gelap}` (kombinasi nyata di kanvas).
- TIDAK dipasang (tidak dipakai bengkel): `sepeda_besar` (kanvas hanya `sepeda_kecil`), `bengkel_latar_640` (lihat keputusan 2), koran_*, struk*, foto_*, lencana32, ikon dan glif lain, `kertas_tile`, `panel_hud`, `lembar_*`.

**Keputusan kecil Dev (usulan; bisa ditolak di review)**
1. Ikon 24 dan glif 12 dipasang sebagai PNG per sel (bukan sheet utuh) supaya "tidak ada aset redesain yang tidak dipakai di `assets/`" terpenuhi; piksel sama dengan sheet, dijaga `uji_ui_redesain.py`. Run layar lain menambah sel ke `pasang.py`.
2. Latar: hanya `ui_bengkel_latar_800.png`. Kanvas selalu memakai latar 800 dengan `bgx = (lebar - 800) / 2` (di 640 terpotong 80 px tiap sisi); versi 640 = potongan tengah versi 800 (diuji), jadi tidak dipakai. SPEC AC-2 menyebut "640/800"; menambah 640 cukup satu baris di `pasang.py` bila bagian B memerlukannya.
3. Variabel lingkungan tujuan `--salin` bernama `UI_ART_SALIN_KE` (folder tujuan langsung, bukan akar repo) dan sama untuk ketiga skrip.
4. `latar_bengkel.py` memuat `cv2`/`sklearn` hanya di `main()` saat membuat ulang; `--salin` hanya menyalin berkas resmi docs/ (jalan tanpa kedua pustaka).
5. Nonaktif diarsir: `ui_btn_nonaktif.png` sel tengah 4x4 (tepat sebesar ubin) diganti `ui_arsir_nonaktif.png` saat dimuat pertama kali (`GayaHud._tekstur_nonaktif_arsir`, dibangun sekali, mode ubin). CSS kanvas menaruh arsir di balik `border-image ... fill` yang opak sehingga arsir di kanvas hampir tidak tampak; di sini arsir terlihat di tengah bingkai (tepi 4/6 px tetap rata). Tidak ada PNG yang diedit tangan.
6. Fokus tombol: garis ACCENT 1 px lurus berjarak 1 px (kanvas putus-putus; Godot tidak punya garis putus-putus).
7. `GayaHud.tombol_*` juga mengatur `disabled` (false untuk empat peran, true untuk `tombol_nonaktif`) dan `theme_type_variation` (`TombolPeran` SemiBold 10 untuk utama/biasa/sakelar, `TombolTipis` Regular 10 untuk tenang/nonaktif); memanggil fungsi peran lain pada tombol yang sama memulihkan. Teks alasan ("Koin kurang") dipilih pemanggil lewat `KomponenUi.teks_tombol`.
8. Type variation baru di `theme.tres` (U-3): `LayarTeksUtama` 10, `LayarTeksKecil` 9 Regular, `LayarLabel` 8 (KAPITAL dan spasi 0,1 em dibuat pemanggil: tema tidak punya `text-transform`/`letter-spacing`), `LayarJudul` Lilita One 24, `ChipTeks` 10, `ChipTeksKecil` 8, `ChipTeksBesar` 12, `TombolPeran`, `TombolTipis`. Tanpa token Palette baru (semua warna komponen sudah ada: `UI_BG`, `TEXT`, `TEXT_2`, `ACCENT`, `WARN`, `OUTLINE`; `#FFE08A` hanya muncul di bilah progres dan aset, belum dipakai kode).
9. Kotak kondisi besar: kelas BARU `KotakKondisiBesar` (+ `TampilKondisiBesar` murni); `KotakKondisi` 14 px untuk HUD tidak disentuh. Tanda "!" memakai pola 3x9 `PolaPiksel.TANDA_SERU_KONDISI` (bukan glif 12) dan selalu disediakan ruangnya (33x9 total). Berongga = lubang `UI_BG` bergaris `TEXT_2` (versi HUD memakai `UI_PANEL_RAISED`).
10. Chip tingkat upgrade (I, II, III) dan format teks penanda sepeda ("! Ban", "Ban aus") bagian B; di sini hanya status -> gaya + glif + kunci teks (`KomponenUi.chip`).

**Tes baru:** `tests/tes_komponen_ui.gd` (+550 pemeriksaan, terdaftar di `run_tests.gd`): Config = meta.json, ukuran 18 tekstur terpasang, 4 peran x 3 keadaan tombol (tekstur, margin, warna, bobot, teks alasan), kartu (sapuan kondisi 0..1 per 0,01 + batas + NaN), chip (7 status, tanpa tabrakan gaya/glif/teks, kunci ada di `ui.csv`), wujud `GayaHud` (StyleBoxTexture, tepi 4/6/4/6, margin isi, sakelar, ganti peran), arsir, fungsi lama tak berubah, kotak kondisi besar (geometri, sapuan warna dan luminans, node), tema. `tools/tests_cek/uji_ui_redesain.py` bagian 7 (+16 pemeriksaan); langkah sudah terdaftar di job `alat` `tes.yml` (nama langkah diperbarui; tidak ada yang butuh Godot).

**Gerbang bagian A (Dev):** `godot --headless --import` tanpa error; `--quit-after 2` tanpa ERROR/WARNING; `run_tests.gd` **20921 lolos, 0 gagal** + `cek_keluaran_tes.py` lolos (baseline 20371); semua `uji_*.py` exit 0 (termasuk `uji_ui_redesain.py` LOLOS); sha256 save asli tetap `37d6d6cb...549e`.
**Bukti layar lama tidak berubah:** `probe_hud_rute_jendela.gd` 1920x1080, tangkapan sebelum (pohon `0b34f64`, worktree terpisah, dua kali) lawan sesudah (pohon ini, dua kali): layar hasil (2), jeda sakelar, kidal, progres campuran, tenggat hampir, tenggat lewat piksel-identik di semua pasangan. Tiga tangkapan lain bervariasi menurut fase animasi dari jam dinding, bukan UI: `hud_awal` (sesudah run 1 beda seluruh layar, sesudah run 2 identik dengan sebelum), `hud_bantu_abu` (beda 24x12 px bahkan antara dua run SEBELUM) dan `hud_radar` (beda hanya di kotak 10x23 game px = fase kayuh sprite pemain; HUD identik). Kesimpulan: tampilan HUD, hasil, jeda tidak berubah.
**Pemeriksaan visual komponen:** skrip sementara di scratchpad (bukan di repo) merender tombol enam peran, tiga kartu, enam chip, kotak kondisi besar (baik/aus/perlu/nol), glif, ikon, panel layar di 1920x1080: semuanya tampil seperti kanvas (nonaktif diarsir, kartu menonjol bergaris WARN, kotak berongga dan "!" terbaca).

## Perubahan tes lama (AC-8; setiap tes lama yang diubah dan alasannya)
Bagian A: tidak ada tes lama yang diubah (hanya `tests/run_tests.gd` menambah satu panggilan `TesKomponenUi`).

## Butir terbuka pemilik
- **Lisensi latar bengkel** (`docs/design/redesain/latar_bengkel/sumber_ai.jpg`): generator dan ketentuan lisensi komersial belum dicatat. Latar dipasang untuk uji HP (U-4) tapi TIDAK boleh masuk rilis sebelum dicatat (ART_DIRECTION 9).

## NEEDS-MANUAL (uji di HP)
- [ ] SETUP_ANDROID 8.18 (lihat SPEC): bengkel terbaca sekilas; sepeda dan chip kondisi jelas; tombol enak ditekan, tiga keadaan jelas bedanya; kartu menonjol vs redup; harga dekat tombol; latar tidak mengganggu teks; tiga upgrade tanpa scroll; 60 fps.

## Keputusan & catatan
- Putusan U-1..U-5 dan semua keputusan lama: lihat SPEC. Tidak ada keputusan terbuka yang menghambat saat SPEC ditulis; kalau tata C tidak muat di 640 untuk teks terpanjang, berhenti dan tanyakan SEKALI dengan satu rekomendasi.
