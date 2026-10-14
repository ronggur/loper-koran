# SPEC — 20261015-fase2-arah-bebas

Run Fase 2 sesudah Run 2A (PR #24, di-merge 2026-10-14): **arah lempar koran bebas**. Ini perbaikan dari uji HP pemilik, bukan fitur baru Fase 2. Kontrak bagi Dev **dan** QA. Prosedur penuh di `docs/LOOP-DEV-QA.md` (maksimal 2 iterasi).

## Tujuan

Koran terbang ke arah swipe **seperti yang terlihat di layar**. Swipe ke atas mengarah ke rumah seberang di depan, swipe ke kanan ke sisi dekat, swipe ke kanan atas ke depan. Arah swipe di layar diproyeksikan ke tanah lewat `Iso`, dan panjang swipe penuh menentukan kekuatan. Tidak ada lagi sudut swipe yang ditolak.

Semua sifat Run 2A tetap berlaku:
- `ThrowSolver` tetap satu-satunya sumber lintasan, dan garis bidik sama dengan hasil;
- jeda lepas, warisan kecepatan maju 100%, lengkung, dan bayangan tidak berubah;
- sisa koran, jeda antar lempar 0,35 detik, dan zona sasaran tidak berubah;
- jeda game tetap membekukan koran.

## Latar belakang (bukti, orchestrator 2026-10-15)

Laporan pemilik sesudah uji Run 2A di vivo V2108: "lemparan koran rasanya gak responsif, suka gagal, terutama ke arah kiri", lalu "bisa gak arahnya dibikin bebas aja?".

Penyebabnya terbukti lewat `ThrowSolver` di `main` `8257acc`. Fungsi `sisi_dari_swipe` menolak swipe yang |dy| ≥ |dx|, jadi semua sudut layar dari 45° sampai 135° (0 = kanan, 90 = atas) tidak melempar.

Sudut layar dari sepeda ke kotak surat (lateral ±1,625 ubin) bila kotak surat berada 0, 1, 2, 3, atau 4 ubin di depan sepeda:

| Kotak surat | 0 | 1 | 2 | 3 | 4 ubin di depan |
|---|---|---|---|---|---|
| Seberang | 153° | 115° | 78° | 59° | 50° |
| Dekat | −27° | −7° | 3° | 8° | 12° |

Sasaran seberang yang ada di depan sepeda, yaitu yang terlihat di layar, jatuh di rentang yang ditolak. Sasaran dekat selalu hampir mendatar. Kekuatan juga hanya dihitung dari |dx|, jadi swipe serong terasa lemah.

## Keputusan dari pemilik (dengan tanggal)

- **2026-10-15, arah lempar bebas** (GDD 5.2, ROADMAP 4b, commit orchestrator `06c6797`). Koran terbang ke arah swipe di layar dan menggantikan dua arah tetap. Rinciannya di bawah adalah **usulan orchestrator** yang dinilai lewat uji HP. Jangan menulisnya "dikunci".
- Keputusan sebelumnya tetap berlaku:
  - ubin 64×32 dikunci;
  - jendela kena koran memakai sakelar `Config.JENDELA_KENA_BONUS`, bawaan penalti ringan, dan keputusan akhirnya masih terbuka;
  - uji HP dilakukan pemilik sendiri.

## Rincian usulan (orchestrator, bisa ditolak di review PR)

- **D-1 Arah.** `v` = titik akhir − titik awal swipe (piksel game). Arah tanah = `Iso.layar_ke_dunia(v)` dinormalkan. `layar_ke_dunia` linear, jadi berlaku untuk vektor.
  - Konsekuensinya, `Iso.dunia_ke_layar(arah)` searah dengan `v`: garis tanah lemparan di layar sejajar jari.
  - Swipe ke kiri murni di layar kini berarti seberang dan **sedikit ke belakang** di tanah. Ini memang arti "arah di layar", dan garis bidik menunjukkannya.
  - Tidak ada arah yang dilarang, termasuk ke bawah dan ke belakang.
- **D-2 Panjang dan kekuatan.** Panjang = |v| penuh (piksel game), bukan |dx|. Ambang dan rumus Run 2A tetap:
  - min 6% dan maks 35% lebar viewport game;
  - |v| < min tidak melempar, tepat min melempar (inklusif dengan `LEMPAR_SWIPE_TOLERANSI_PX`);
  - u = jepit((|v| − min)/(maks − min), 0, 1);
  - jarak tanah lerp(1,5, 5,0, u) ubin searah arah tanah;
  - lama terbang dan tinggi puncak sama seperti Run 2A.

  Warisan maju 100% tetap ditambahkan searah `Iso.ARAH_MAJU`. Tidak ada angka `Config` baru kecuali benar-benar perlu (bila ada: satu baris, usulan, BALANCING ikut).
- **D-3 Sisi** (dipakai animasi lempar dan `Lintasan.sisi`) diambil dari komponen melintang arah tanah:
  - x < 0 berarti `SEBERANG`;
  - x > 0 berarti `DEKAT`;
  - x = 0 tepat (swipe searah sumbu jalan di layar) berarti `DEKAT`, ditulis di doc comment dan dites.

  Kidal tidak mengubah arti arah. Nama sisi di kode tetap `seberang`/`dekat`.
- **D-4 Penilaian zona dari titik mendarat saja.** Zona sasaran yang memuat titik mendarat menilai koran, apa pun arah atau sisi lemparannya. Penyaring `sisi_lempar` di `ZonaSasaran.klasifikasi` dihapus atau diabaikan. Pilihannya dicatat, tetapi hasilnya tidak boleh bergantung pada sisi lemparan. Zona seberang dan zona dekat tidak bertumpuk, dan ini dites.
- **D-5 Jari diangkat.** Lemparan tetap memakai lintasan garis bidik terakhir yang tampil untuk swipe itu (QA-001 Run 2A).
  - Batal hanya bila panjang swipe di posisi lepas |v_lepas| < min, yaitu jari ditarik kembali ke dekat titik awal.
  - Arah jari saat diangkat tidak membatalkan lemparan dan tidak mengubah titik mendarat. Aturan "berbelok tegak saat diangkat" dari Run 2A hilang dengan sendirinya.
  - Tanpa garis bidik yang tampil, lemparan dihitung dari posisi lepas dengan fungsi yang sama, seperti Run 2A.

## Di luar scope

- Mode bantu, audio lempar dan mendarat, serta QA-008 Run 2A. Ketiganya untuk Run 2B.
- Tanda saat swipe ditolak karena jeda 0,35 detik atau koran habis. Ini dicatat sebagai pengamatan uji HP, bukan dikerjakan.
- Mengubah angka jarak, waktu, puncak, jeda lepas, jeda antar lempar, atau zona swipe.
- Arah animasi lempar selain dua sisi. Sprite tetap kiri/kanan per sisi, dan tidak ada PNG baru.
- Keputusan terbuka lain di ROADMAP 5.

## Kriteria penerimaan (bisa diuji)

- **AC-1 Gerbang.** Semua perintah ini bersih, dan `git status` bersih sesudah import:
  - `godot --headless --import` tanpa ERROR/WARNING;
  - `run_tests.gd` + `python3 tools/cek_keluaran_tes.py --ketat build/tests.log` lolos, dengan 0 gagal;
  - `uji_pemeriksa.py` lolos;
  - `--quit-after 2` tanpa ERROR/WARNING;
  - `--export-pack "Android"` tanpa `tests/`, `docs/`, atau probe.
- **AC-2 Arah.** Untuk minimal 12 arah swipe, termasuk 45°, 78°, 90°, 115°, 135°, 180°, 225°, 270°, dan 315°, dengan panjang di antara min dan maks, `ThrowSolver`:
  - melempar;
  - (titik mendarat − titik lepas − geser maju warisan) = jarak × arah tanah;
  - `Iso.dunia_ke_layar(arah tanah)` searah dengan `v`: hasil kali silang ≈ 0 dan hasil kali titik > 0.
- **AC-3 Tanpa sudut ditolak.** Untuk tiap arah di AC-2:
  - |v| tepat min melempar;
  - |v| = min − 0,01 tidak melempar;
  - |v| di atas maks dijepit ke u = 1.

  Kekuatan u untuk panjang yang sama sama di semua arah.
- **AC-4 Sisi.** Hasil sisi mengikuti D-3, termasuk x = 0 tepat, x sedikit negatif, dan x sedikit positif. Kidal tidak mengubah sisi untuk swipe yang sama.
- **AC-5 Zona.** Klasifikasi titik mendarat tidak bergantung pada sisi lemparan: titik yang sama dengan sisi apa pun memberi hasil sama. Zona seberang dan dekat jalan uji tidak bertumpuk. Penanda dan status antaran mengikuti Run 2A.
- **AC-6 Regresi laporan pemilik.** Di setiap tingkat kecepatan, santai, cepat, dan ngebut (kecepatan sebenarnya dari `Config`), ada swipe dengan sudut layar antara 45° dan 135° yang mendarat di kotak surat **seberang** pelanggan yang berada di depan sepeda, dinilai `ZonaSasaran` sebagai antaran sah. Swipe 78° yang ditolak di Run 2A kini melempar. Tes ini dibuat di tes murni dan di tes scene (`tes_koran_scene.gd`, swipe lewat `TouchRouter` atau event sentuh seperti tes yang ada).
- **AC-7 Prediksi sama dengan hasil.** Tes scene Run 2A tetap lolos atau diperbarui ke arah bebas:
  - koran mendarat tepat di elips garis bidik terakhir untuk swipe ke atas, ke kanan, ke kiri, dan ke bawah;
  - flick (jari masih bergerak atau berbelok saat diangkat) tetap mendarat di elips terakhir;
  - jari ditarik kembali di bawah min membatalkan lemparan tanpa memakai koran.
- **AC-8 Bersih dari sisa aturan lama.**
  - Tidak ada lagi aturan "dominan datar" atau |dx| di jalur lemparan.
  - Komentar dan doc comment yang menyebut swipe kiri/kanan atau |dx| diperbarui.
  - Tidak ada `kiri`/`kanan` sebagai nama sisi jalan. Sumbu layar di input dan nama animasi sprite yang sudah ada boleh.
- **AC-9 Dokumen** diperbarui ke arah bebas tanpa kata "dikunci" untuk rinciannya:
  - BALANCING 4;
  - DESIGN_SPEC tafsiran garis bidik (3.7);
  - TECH_PLAN Fase 2 (`ThrowSolver`);
  - butir DEV_PHASES Fase 2 "Swipe kiri/kanan…": teks diubah. Butir itu boleh tetap dicentang, karena orchestrator mencentangnya ulang sesudah PR;
  - checklist `docs/SETUP_ANDROID.md` 8;
  - peta di `AGENTS.md` / `docs/README.md` bila ada kalimat yang usang;
  - catatan ROADMAP 5 "ketelitian swipe pendek" tetap terbuka.
- **AC-10 Probe jendela.** `tests/probe_koran_jendela.gd` diperbarui. Tangkapan di 2340×1080 dan 1920×1080 ke `docs/loop/20261015-fase2-arah-bebas/shots/` menunjukkan:
  - swipe ke atas ke kotak surat seberang di depan, kena;
  - swipe ke kanan ke sisi dekat;
  - swipe ke kiri murni, yang mendarat seberang sedikit ke belakang;
  - garis bidik sejajar arah jari.

  Bila menangkap kidal, kidal ikut. Hasil tangkapan lolos `tools/cek_blok_piksel.py`, dan probe keluar tanpa ERROR/WARNING.
- **AC-11 Mutan nyata.** Dev menjalankan mutan pada logika baru: proyeksi arah, panjang |v|, ambang, sisi x = 0, penilaian zona, dan aturan batal. Semua harus mati, atau alasannya dicatat di LOG.

## Perubahan file yang diharapkan

- `scripts/systems/throw_solver.gd`: arah dari vektor swipe, panjang |v|, dan sisi dari arah tanah. `sisi_dari_swipe` diganti atau diubah, dengan doc comment.
- `scripts/systems/zona_sasaran.gd`, `koran_lempar.gd`: penilaian dari titik mendarat.
- `scripts/entities/jalan_uji.gd`: aturan lepas jari D-5 dan doc comment.
- `scripts/systems/loper_anim.gd`: komentar.
- Bila ada yang memanggil fungsi lama, sesuaikan.
- `tests/tes_lempar.gd`, `tests/tes_koran_scene.gd`, `tests/probe_koran_jendela.gd`.
- Dokumen di AC-9.
- `docs/loop/20261015-fase2-arah-bebas/LOG.md`.

## Tes yang harus ada

AC-2 sampai AC-7 sebagai tes headless, ditambah tes mutan yang dicatat di LOG. Seed dan waktu deterministik (rule `testing`). Tes lama yang tidak lagi berlaku (sudut ditolak, |dx|) diganti tes arah bebas yang setara, tidak dihapus tanpa pengganti. Alasannya dicatat di LOG.

## Butuh uji perangkat nyata (NEEDS-MANUAL)

- Arah bebas terasa wajar: swipe ke arah rumah yang terlihat mengenai rumah itu.
- Kotak surat seberang di depan bisa dikenai dengan sengaja di ketiga kecepatan.
- Swipe ke kiri murni yang mendarat sedikit ke belakang tidak membingungkan.
- Swipe ke atas cukup panjang untuk lemparan jauh. Tinggi zona swipe 304 px game, sedangkan maks 35% lebar = 224 sampai 280 px.
- Flick dan jari ditarik kembali.
- Apakah jeda 0,35 detik dan jeda lepas 0,17 detik masih terasa "tidak responsif". Ini pengamatan untuk Run 2B.
- Hal-hal NEEDS-MANUAL Run 2A yang tersisa: garis bidik, bayangan, penanda, jendela penalti, dan HUD koran.

## Dokumen yang ikut diperbarui

Lihat AC-9. GDD 5.2 dan ROADMAP 4b sudah diperbarui orchestrator di commit `06c6797`. Jangan mengubahnya lagi kecuali ada salah fakta, dan bila begitu catat di LOG.
