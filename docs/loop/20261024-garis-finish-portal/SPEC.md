# SPEC — 20261024-garis-finish-portal

## Tujuan
Garis finish yang terasa seperti garis finish. Sekarang sepeda direm di garis akhir (`AkhirRute.stick_akhir`) lalu layar hasil muncul saat berhenti. Run ini menggantinya: portal satpam berdiri melintang di jalan pada garis akhir, sepeda melaju otomatis lewat portal dan KELUAR viewport, kontrol dikunci lurus, lempar nonaktif, banner "Rute selesai" muncul saat sepeda mulai keluar, dan layar hasil (V-10, latar = dunia yang baru dilalui) tampil sesudah sepeda keluar. Usulan pemilik 2026-10-22, dikonfirmasi 2026-10-24 (ROADMAP baris 88).

## Keputusan dari pemilik (dengan tanggal)
- 2026-10-22, dikonfirmasi 2026-10-24: sepeda otomatis melaju keluar viewport menggantikan animasi berhenti; penanda di dunia (portal); kontrol dikunci lurus, lempar nonaktif, banner saat hampir keluar. Dijadwalkan sebagai run sendiri sesudah UI-2 (PR #66 sudah di-merge).
- Berlaku, tidak ditanyakan ulang: Godot 4.7.2, skala bulat, palet induk tidak dikunci, semua aset lewat renderer (`art-assets.mdc`), pola `--salin` memasang HANYA yang dipakai.

## Putusan orchestrator (usulan, bisa ditolak di review PR)
- **G-1 Penanda = HANYA `prop_portal_satpam`** (sel 80x92, dua frame: 0 tertutup, 1 terbuka, pijak (14, 60); G-1a), melintang di jalan pada garis akhir (`RouteBuilder.Rute.panjang_ubin`). Tertutup saat jauh, membuka saat sepeda mendekat (jarak dari `Config`), terbuka saat dilewati. `prop_pos_satpam` TIDAK dipasang.
- **G-1a (amandemen orchestrator, 2026-10-24, setelah ukuran Dev bagian A)**: sel dan pijak semula 80x64 dan (14, 48) hanya berasal dari deskripsi ROADMAP, bukan dari desain; terukur memotong palang terbuka di tepi atas (ujung 57 px di atas pijak, sel 48) dan kaki penyangga tertutup di tepi bawah (27 px di bawah pijak, sel 16) (LOG A-1, A-2). Diperbaiki lewat renderer: sel 80x92, pijak (14, 60), kedua frame berbagi sel dan pijak; bentuk 3D tidak berubah. Yang wajib adalah tidak ada bagian palang atau tiang terpotong.
- **G-2 Sesudah garis akhir**: sepeda tidak direm. Melaju lurus dengan laju dijaga minimal (konstanta `Config`) sampai seluruh badan keluar viewport. Stick sungguhan dikunci lurus (tanpa belok); lempar dan mode bantu nonaktif; bel boleh diam. Kamera berhenti mengikuti di garis akhir, jadi sepeda keluar layar menurut arah rute (turunkan arahnya dari kode: jalan naik ke kanan atas, jangan menebak).
- **G-3 Banner "Rute selesai"** muncul saat sepeda mulai keluar ("hampir keluar"), bukan sesudah berhenti. Teks lewat kunci terjemahan yang sudah ada bila cukup; kunci baru hanya bila perlu dan dicatat di LOG.
- **G-4 Layar hasil tampil SETELAH sepeda keluar viewport dan semua koran terbang mendarat.** `HasilRute.siap_tampil` mengganti syarat "kecepatan 0" dengan syarat "sudah keluar"; tes murninya ikut diganti dan dicatat per baris di LOG.
- **G-5 Tidak ada yang berubah di skor, tenggat, misi, kondisi sepeda, progres 25 rumah, radar, dan save.** Semuanya tetap dibekukan di garis akhir seperti sekarang. Jarak tempuh sesudah garis akhir tidak boleh memengaruhi satu pun angka itu (kondisi/aus, telemetri `BikeMotion`, tenggat, `ProgresRute`, `RadarRute`, misi). Tanah dan dunia di belakang portal tergambar sampai sepeda keluar (tanpa lubang kosong), tanpa menambah segmen rute.
- **G-6 Tidak ada angka ekonomi atau aturan permainan yang berubah.** Teks pemain hanya dari `translations/`.

## Di luar scope
Pos satpam, polisi tidur, zebra, genangan, mobil tamu, misi P3 (pencuri sandal), perubahan panjang rute atau segmen, tenggat, ekonomi 6B, redesain UI lain, keputusan lisensi latar bengkel. Animasi "berhenti" 5C tetap ada untuk rem manual pemain (hanya tidak dipakai di garis akhir).
Bila arah keluar viewport atau tanah di belakang portal tidak bisa dipenuhi tanpa mengubah segmen rute: BERHENTI (BLOCKED di LOG), orchestrator menanyakan SEKALI dengan satu rekomendasi.

## Kriteria penerimaan (bisa diuji)
- AC-1 (aset): `prop_portal_satpam.png` + `.json` (dua frame, sel 80x92, pijak (14, 60), G-1a; margin transparan >= 1 px di semua sisi kedua frame, tidak ada bagian terpotong) ada di `assets/sprites/props/` hasil `render.py --salin`, impor Lossless/Nearest/tanpa mipmap; `uji_aset_pasang_gelombang1.py` menegakkan set tepat yang dipasang (portal ikut daftar, `prop_pos_satpam` tidak); isi `assets/` = keluaran skrip, deterministik.
- AC-2 (paket): `--export-pack` memuat portal dan tidak memuat aset gelombang 1 lain yang tidak dipasang (`tes_export.gd` diperbarui).
- AC-3 (logika murni): `AkhirRute` punya fase sebelum / melaju keluar / sudah keluar; laju minimum sesudah garis akhir; "hampir keluar" (sinyal banner, tepat sekali); keluar viewport ditentukan dari geometri nyata (posisi layar sepeda vs ukuran viewport, bukan waktu tetap). Semua angka di `config.gd` satu baris, literal.
- AC-4: `HasilRute.siap_tampil` = rute selesai DAN sepeda sudah keluar DAN tidak ada koran terbang. Tes murni dengan oracle literal.
- AC-5 (scene): setelah garis akhir stick sungguhan diabaikan (arah tetap lurus), tidak ada rem, kecepatan >= laju minimum sampai keluar, lempar dan ketukan mode bantu tidak melempar, kamera tidak bergeser lagi (posisi kamera tetap di garis akhir), sepeda terbukti keluar viewport di empat ukuran dan kidal.
- AC-6 (portal): tergambar di garis akhir, tertutup jauh, membuka mendekat, terbuka sesudah dilewati; urutan Y-sort/penerap penutup benar (sepeda lewat tanpa tertimpa/menimpa salah); tidak ada lubang tanah di belakang portal.
- AC-7 (G-5): tes yang membuktikan skor, koin, tenggat, kondisi sepeda, progres, radar, misi, dan save IDENTIK dengan perilaku lama untuk rute yang sama (bandingkan angka sebelum run vs sesudah; golden dari skrip) walau sepeda menempuh jarak tambahan sesudah garis akhir.
- AC-8 (banner dan hasil): banner muncul saat hampir keluar (sebelum sepeda hilang), layar hasil muncul sesudah keluar; "Main lagi" dan "Hari berikutnya" memulihkan keadaan awal (kamera mengikuti lagi, portal tertutup, kontrol aktif, lempar aktif); layar hasil di atas dunia portal diukur kontrasnya dengan `tools/ukur_kontras_tangkapan.py` (>= 7:1) dari tangkapan nyata.
- AC-9 (regresi): semua keluaran lama hijau kecuali tes yang berubah karena G-1..G-6 (dicatat per baris di LOG); 17 `uji_*.py` exit 0; sha256 save asli `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` tidak berubah; tes tidak menulis save sungguhan.
- AC-10 (mutan): mutan nyata (satu perubahan, tes penuh, `git checkout`; commit SEBELUM mutan). Dev >= 40, QA mengulang >= 12 pilihannya sendiri.
- AC-11 (probe): `probe_rute_jendela.gd` diperbarui di 2340x1080, 1920x1080, 2400x1080, 1600x720; kidal; mencetak keadaan tidak sesuai; tangkapan DILIHAT QA. Hanya tangkapan terpilih yang di-commit (pelajaran QA-006 UI-2: shots iter1 83 MB terlalu besar; target <= 20 MB).

## Perubahan file/struktur yang diharapkan
`tools/env_art/gelombang1/render.py` (daftar `--salin`), `assets/sprites/props/prop_portal_satpam.{png,json}(+.import)`, `scripts/systems/akhir_rute.gd`, `hasil_rute.gd`, `scripts/config.gd`, `scripts/entities/{rute_main,adegan_jalan}.gd` (+ entitas portal baru bila perlu), `scenes/rute/rute.tscn`, `scripts/ui/panel_akhir_rute.gd` (waktu banner), tes dan probe, dokumen.

## Tes yang harus ada
Tes murni `AkhirRute`/`HasilRute` (oracle literal), tes scene garis finish (sepeda keluar, kamera tetap, stick dikunci, lempar mati, G-5 identik), tes portal (frame, Y-sort), tes pemulihan Main lagi/Hari berikutnya, tes aset dan paket, probe jendela.

## Butuh uji perangkat nyata (NEEDS-MANUAL)
SETUP_ANDROID 8.20: portal terlihat jelas dari jauh, sepeda keluar mulus, banner terbaca tepat waktu, tidak ada lompatan kamera, jempol yang masih menahan stick tidak membelokkan sepeda, layar hasil terbaca di atas dunia baru, 60 fps.

## Dokumen yang ikut diperbarui
ROADMAP baris 88 (selesai, menunggu HP), ROUTE_DESIGN, ART_DIRECTION 6.x, AGENTS.md (perintah dan peta repo), docs/README, DEV_PHASES (aset dan perilaku TIDAK dicentang sebelum uji HP), SETUP_ANDROID 8.20, LOOP-DEV-QA 6m.
