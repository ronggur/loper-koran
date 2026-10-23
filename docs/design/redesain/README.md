# Redesain UI layar penuh (usulan, 2026-10-23)

Hasil prompt [`../PROMPT_REDESAIN_UI.md`](../PROMPT_REDESAIN_UI.md) yang dijalankan di Claude Design: kanvas **"UI Loper Koran — Redesain"** (artefak Claude Design milik pemilik, privat). Alasannya dari uji HP pemilik 2026-10-23: UI terlalu kecil, terlalu kosong, dan tombolnya polos. **Semua isi folder ini usulan.** Belum ada yang dipasang di game, belum ada yang disalin ke `assets/`, dan tidak ada yang dikunci sebelum dinilai di HP. Porting ke Godot dikerjakan bertahap, satu layar per run (bagian 6).

## 1. Isi folder

| Path | Isi | Dibuat oleh |
|---|---|---|
| `aset/` | Semua gambar baru di kanvas sebagai PNG 1×, plus `meta.json` (ukuran, slice, catatan) dan tiga lembar pratinjau (`lembar_*`) | `python3 tools/ui_art/redesain/komponen.py --mock` |
| `aset/sepeda_*` | Sepeda panggung bengkel: `sepeda_besar.png` 232×155, `sepeda_kecil.png` 116×78 (dipakai di kanvas), pratinjau ×3, dan `sepeda.json` (ukuran, titik penanda ban, rem, rantai) | `python3 tools/ui_art/redesain/sepeda_fullbody.py --mock` (bagian 5b) |
| `latar_bengkel/` | Latar layar bengkel pixel art 640×360 dan 800×360, pratinjau ×3, dan ilustrasi sumbernya | `python3 tools/ui_art/redesain/latar_bengkel.py --mock` (bagian 5) |
| `kanvas/` | Sumber kanvas: `canvas.json` (tata letak 38 papan di enam halaman), satu `*.dc.html` per papan, dan `ui.css` (kelas komponen bersama) | Ditulis di kanvas, disalin apa adanya sebagai acuan angka |

Berkas di `aset/` dan `latar_bengkel/` dibuat skrip, jangan diedit dengan tangan (rule `docs`, `art-assets`). Uji: `python3 tools/tests_cek/uji_ui_redesain.py`.

`kanvas/` tidak bisa dibuka langsung di browser: papan memakai runtime Claude Design (`support.js`) dan merujuk gambar lewat alamat unggahan kanvas (`/_blob/<id>`). Pemetaan alamat ke berkas ada di bagian 7. Gambar papan diekspor dari kanvas (menu Share › Export) bila diperlukan.

## 2. Papan di kanvas

Semua papan digambar di kanvas game 640×360 dan diperbesar ×3 tanpa penghalusan; tiap layar penuh juga punya papan di lebar 800 dengan ukuran tertulis.

| Halaman | Papan |
|---|---|
| 1 Komponen | Komponen bersama: tombol empat peran × empat keadaan, ukuran standar, panel dan kartu, judul bagian, chip, kondisi sepeda, bilah progres, ikon, versi terang koran |
| 2 Bengkel | Tata A (sepeda di tengah), tata B (sepeda kiri atas, tab), tata C (rekomendasi) keadaan a sampai g, tempat upgrade tingkat 2–3, lebar 800 |
| 3 Koran | Hari 1 belum dipilih, Ambil, Lewati, tanpa misi, hari lanjutan, teks terpanjang (40/60), notifikasi save rusak, inset aman, lebar 800 |
| 4 Hasil | Hari biasa, hari minus, semua terkirim, lewat tenggat, pelanggan berhenti/kembali/setia, milestone baru, semua emas, kasus terpadat, tanpa data reputasi, inset aman, lebar 800 |
| 5 Jeda, tutorial, HUD | Jeda (640 dan 800), tutorial hari 1, varian banner, HUD saat mengantar dengan bahasa bentuk baru |
| 6 Spesifikasi | Ukuran, token, font per elemen; jarak; daftar aset baru dan yang cukup dari kode; urutan Container; urutan porting |

Angka gameplay di papan (harga servis selain 105, skor, nama milestone "Pelanggan · Perak") hanya contoh. Teks layar diambil dari `translations/` kecuali dua kunci baru yang diusulkan: isi kotak hiasan "Iklan baris" di koran dan label "Pelanggan:" di gelembung petunjuk.

## 3. Keputusan desain (usulan, menunggu penilaian pemilik)

1. **Bengkel tata C**: sepeda dan tiga baris servis di satu panel kiri, upgrade di kolom kanan. Tata A (sepeda di tengah) memaksa deskripsi upgrade terpotong satu baris di lebar 640; tata B menyembunyikan upgrade di balik tab.
2. **Kondisi terbaca dari sepeda**: chip "! Ban" atau "Rantai aus" muncul di bagian sepeda yang bermasalah (titik dari `aset/sepeda.json`, `titik_kecil`); sepeda baik tampil bersih tanpa penanda.
3. **Harga selalu chip di sebelah tombolnya**; komponen PERLU SERVIS memakai kartu bergaris WARN, yang Baik atau Dimiliki memakai kartu redup.
4. **Satu bahasa tombol untuk semua layar**: empat peran (utama, biasa, sakelar, tenang); sisi atas terang dan bibir bawah 2 px, ditekan = wajah turun 2 px; nonaktif rata, diarsir, dan teksnya berganti alasan (terbaca tanpa warna).
5. **Aksi utama 140×42 selalu di kanan bawah** (Berangkat, Ke bengkel, Hari berikutnya).
6. **Hasil harian sebagai struk antaran**: tepi bergerigi, garis sobek memisahkan yang berhasil dari yang netral, angka Terkirim dan Koin 32 px; kolom samping reputasi, pelanggan, target; tanpa data reputasi struk ke tengah.
7. **Koran terasa koran**: nama 32 px dengan garis ganda, foto berita tinta dua nada, tekstur titik kertas, kotak hiasan "Iklan baris" mengisi ruang bawah.
8. **Upgrade tingkat 2–3 tidak menambah kartu**: kartu yang sama berganti isi, dengan jejak I · II · III; tiga kartu selalu muat tanpa scroll.
9. **Latar bengkel** memakai ilustrasi yang dikonversi (bagian 5), dipilih pemilik 2026-10-23 dari dua kandidat.

## 4. Spesifikasi ringkas

Angka dalam piksel game. Rincian ada di papan Spesifikasi dan di `kanvas/ui.css`.

| Elemen | Ukuran | Warna | Font |
|---|---|---|---|
| Judul layar | 24 | TEXT / KORAN_TINTA | Lilita One 24 |
| Nama koran, angka utama hasil | 32 | KORAN_TINTA; TEXT, Koin ACCENT | Lilita One 32 |
| Headline utama / ringan | 24 / 16 | KORAN_TINTA | Lilita One |
| Teks utama layar penuh | baris 12 | TEXT | Lexend SemiBold 10 |
| Teks kecil layar penuh | baris 11 | TEXT_2 / KORAN_TINTA_2 | Lexend Regular 9 |
| Label KAPITAL | baris 10, spasi 0,1 em | ACCENT / TEXT_2 | Lexend SemiBold 8 |
| Tombol | 84 / 96 / 140 × 42 | per peran | Lexend SemiBold 10 |
| Chip | tinggi 18 (kecil 14, besar 24) | isi UI_BG, garis dalam per status | Lexend SemiBold 10 / 8 / 12 |
| Kartu servis / upgrade | lebar kolom × 50 / × 62 | kartu, menonjol (WARN), redup | — |
| Kotak kondisi | 8×8, jarak 2, "!" 3×9 | TEXT / berongga TEXT_2 / WARN | — |
| Bilah progres | tinggi 7 | OUTLINE, UI_PANEL, ACCENT + `#FFE08A` | angka Lexend 9 |
| Panel jeda | lebar 232 | panel layar di atas lapisan `HUD_PANEL` 72 % | — |

Jarak: margin layar 12 + inset aman; header judul di y 11, isi mulai y 46 (bengkel, hasil) atau y 56 (koran); bengkel kolom servis 48 % | 8 | upgrade; hasil struk | 10 | kolom samping 236 (300 di lebar 800); koran kolom berita | 6 + garis 1 + 6 | misi 236 (280 di 800); tombol minimal 42 tinggi, 84 lebar, jarak 6.

Lapisan jeda 72 % (bukan alpha 84 % token `HUD_PANEL`) supaya jalan tetap terbaca: usulan, perlu keputusan sebelum dipakai.

## 5. Latar bengkel

`latar_bengkel/sumber_ai.jpg` (1792×1008) adalah ilustrasi AI yang dikirim pemilik 2026-10-23. **Generator dan ketentuan lisensi komersialnya belum dicatat**; isi sebelum gambar ini dipakai di rilis (ART_DIRECTION 9, rule `art-assets`).

Konversi mengikuti cara gambar skala besar (`konversi2`, ART_DIRECTION 3.5): skala ke 1920×1080 lalu sel 3×3, palet k-means 30 warna (warna dekat palet induk ditarik ke palet induk), piksel lepas dan tekstur berisik dirapikan, cahaya lampu jadi cincin konsentris bertingkat (bukan gradien), tanaman dihapus atas permintaan pemilik, lalu versi 800 dibuat dengan memantulkan 80 px tepi kiri dan kanan. Hasil: 26 warna. Benda di latar tidak bergaris luar `#0E0A1C`, sama seperti gambar full body. Hal yang masih terlihat bila diamati: satu blok gelap kecil di ambang jendela kiri dan pengulangan di pinggir versi 800.

k-means dan inpaint memakai pustaka numerik, jadi menjalankan ulang skrip di mesin lain bisa berbeda beberapa piksel. Berkas di folder ini adalah keluaran resmi; uji memeriksa sifatnya, bukan kecocokan piksel.

## 5b. Sepeda bengkel

Sepeda di panggung bengkel diambil dari gambar full body pemain (`docs/design/character/loper_agen/loper_agen_fullbody.png`, sama dengan artboard "Gambar AI baru jadi pixel art · versi 5" di artefak Design "Karakter Loper Koran"), atas permintaan pemilik 2026-10-23. Skrip `tools/ui_art/redesain/sepeda_fullbody.py` membuang tokoh (warna tubuh, garis luar gelap di sekitarnya, sepatu, kunci, bayangan lama), lalu menggambar ulang bagian sepeda yang tadinya tertutup tubuh hanya di piksel yang kosong: roda belakang dari profil radial yang diukur dari ban yang terlihat (lingkaran, jari-jari tiap 30°), kiri bawah ban depan (ikut terhapus bersama sepatu) dari pantulan sisi kanannya, dan tabung sadel. Dua pipa step-through digambar ulang lurus dari bawah kepala setang (garis diukur dari bagian pipa sumber yang terlihat: pipa atas bertemu tabung sadel, pipa bawah lurus ke poros gir), karena sambungan potongan sumber dan lanjutan yang tidak segaris tampak bergerigi. Seat stay digambar ulang tipis (2 px) dari tabung sadel 8 px di bawah dudukan lurus ke tengah poros roda belakang, di belakang tas, poros, rantai, dan tutup rantai; potongan stay sumber (separuh tertutup lengan tokoh) dibuang dan ban di belakangnya diisi dari profil. Chainstay tidak digambar; gantinya tutup rantai hijau yang separuhnya sudah ada di roda belakang diteruskan sampai gir depan dan ujungnya melengkung di atas gir. Gir depan (lima lengan, gigi putus-putus), engkol dan pedal dua sisi, gir belakang, dan rantai atas dan bawah (garis singgung kedua gir) digambar ulang sebagai satu rakitan di kotak gir, karena sumber hanya memperlihatkan potongannya di antara kaki tokoh; di versi kecil rantai digambar 1 px supaya tidak menggumpal. Sorot pegangan setang seberang kebetulan sama dengan salah satu warna kulit, jadi kotak pegangan dikecualikan dari pembuangan tokoh. Sadel digambar utuh dengan hidung 6 px lebih panjang dari sadel sumber (yang separuhnya tertutup tokoh), dan kabel rem ditipiskan dari 2–3 px jadi 1 px supaya di versi kecil tetap garis tipis (penilaian pemilik 2026-10-23). Semua warna diambil dari palet gambar full body (diuji), garis luar `#1B1226` seperti gambar skala besar. Bayangan baru elips datar.

`sepeda_besar.png` (232×155) adalah potongan 1×; `sepeda_kecil.png` (116×78) dibuat dengan blok 2×2 (blok penuh = warna terbanyak, garis tipis dan jari-jari = warna paling terang, garis luar hanya di sekeliling blok penuh) dan dipakai di kanvas, dekat ukuran sepeda prosedural lama 124×72. Titik penanda kondisi di `sepeda.json` (`titik_kecil`: ban, rem, rantai; titik rantai di rantai atas). Keluaran deterministik (tanpa pustaka acak), jadi uji memeriksa kecocokan piksel.

Yang masih terlihat bila diamati: beberapa piksel krem dan hijau sisa di dekat tabung. Kepadatan detailnya juga lebih tinggi dari ikon 24 di sebelahnya; dinilai di HP.

## 6. Urutan porting yang disarankan

1. **Komponen**: renderer `tools/ui_art/redesain/komponen.py` dipindah ke alur `--salin` ke `assets/sprites/ui/`, bentuk dipasang di `assets/ui/theme.tres` dan `scripts/ui/gaya_hud.gd`; tombol polos di semua layar diganti sekaligus.
2. **Bengkel** (tata C): ikon 24, sepeda, papan alat, latar; tata letak dua kolom dari kode. Uji keadaan a–g di HP.
3. **Hasil**: struk 9-slice, angka besar, kolom samping (data reputasi, pelanggan, milestone dari run 6A2).
4. **Koran**: tekstur kertas, foto berita, kotak iklan baris (kunci teks baru); nilai silau di HP.
5. **Jeda, tutorial, banner**: panel dan sakelar.
6. **HUD**: hanya tombol jeda berbentuk tombol biasa; posisi dan ukuran panel lain tidak berubah (DESIGN_SPEC 3).

## 7. Alamat gambar di `kanvas/`

| Alamat | Berkas |
|---|---|
| `/_blob/b23e54cf59df17b596a06d402ed34bb2` | `kanvas/ui.css` |
| `/_blob/f7a8cc2226662f2dba85e0e9691ef678`, `b95298a61f88cc0b671db590ebb91e6b` | `aset/btn_utama.png`, `btn_utama_tekan.png` |
| `/_blob/24df3a17ea0ce96d97805a4df8481a11`, `44ce861fa736600926eb7425c9f92abf`, `1ff0f72099ec7181411b837a7d922f9f` | `btn_biasa`, `btn_biasa_tekan`, `btn_sakelar_nyala` |
| `/_blob/534a0f5c352ea36a9b42dab95d7235fd`, `42e711a3a2083053e467694995f496a3`, `703d850093f6058437126681b244a064` | `btn_tenang`, `btn_tenang_tekan`, `btn_nonaktif` |
| `/_blob/da52ed8623208525fa37fb65e43e474c`, `0915fb2044952c21a1bbd2248fe5a83b`, `013efc4eacaf5302c97047120af43df7`, `48305728fdeb615be97721f5cad5a1a1`, `762353e5d757698a40525b3429983f55` | `panel_layar`, `kartu_biasa`, `kartu_menonjol`, `kartu_redup`, `panel_hud` |
| `/_blob/e4d4a62a2e18ce28d72877abc5fc78d3`, `a627545e937439868721eb33e906d409`, `053dc22d993ad906c6c53b93554b65ed`, `3eaae32fc32885af3644651bc90f4ade`, `17b5a01cee106d0c7a816f88513518e8` | `chip_gelap`, `chip_ok`, `chip_warn`, `chip_netral`, `chip_aksen` |
| `/_blob/98684303037eba551a7f7796438e9a19`, `df48d4009ee5bbb88103f90cb3703898`, `e830964809efbba3c566642bd9bdb0a0`, `87dc67e5338052466bc1aac551111379`, `81d789adb2123fb01971957f3f73f0fc` | `koran_kotak`, `koran_btn_tinta`, `koran_btn_tinta_tekan`, `koran_btn_tipis`, `koran_btn_terpilih` |
| `/_blob/6ff6449167533e37b1201340a06e5e4e`, `2f6d4018a9ca280cd6dbf775e4ec204c`, `afbc131fc226ae494a5183644dccca52`, `c493d6bcb490bfaa6028c5c5ec03fd70` | `struk`, `struk_takik`, `arsir_nonaktif`, `kertas_tile` |
| `/_blob/372c7f38efe88500b9954cf865bfb34b`, `a8fc11bcff0402de83219ac569df5491`, `6331f06c70ca2aa3a6a6e552dfe9ad79` | `ikon24`, `lencana32`, `glif12` |
| `/_blob/2de4315b987c8da057d694005de1e80b`, `7cb89d9a8ad08057e730fa7585a0ad93`, `7474ef878735646d976d01349198b272`, `a31678716a113eab1149137657ce2e0a` | `sepeda_kecil`, `papan_alat`, `foto_jalan`, `foto_lampu` |
| `/_blob/0394a12fbc917b33a44355e7ebdde963` | `latar_bengkel/bengkel_latar_800.png` |
| `/_blob/f69c513708dab5417f72e6f09771d7b4` | Tangkapan layar jalan run 5B diperkecil ke 640×360 (`docs/loop/20261021-fase5b-tembok-dekor/shots/iter1/1920x1080_dekat_dekor_jalur_utama.png`), latar papan Jeda, Tutorial, Banner, HUD |
| `/_blob/1b8c69138f32cb9445bfef455e4dad11`, `e03f1bcfd5e463815d1be2eab707a584`, `8accfd5abc85c093f7ac098be585e921`, `972e215ef8cce3d49f3b1dbb217faafd`, `ae731af7a3e15ce2c89612c2e528318f`, `95fa34e99a2063540cf39d946e534094`, `97b23399af47af9a6ee68826f41c12bb` | `assets/sprites/ui/ui_icon_{koin,reputasi,ban,rem,rantai,misi_kucing}.png`, `ui_bel_tombol.png` (yang sudah ada) |

Unggahan lama yang tidak dirujuk lagi: `f5c80e40e3992d10089aad6bc5490d1b` (`ui.css` versi pertama, teks tombol 16 px karena `font: inherit`), `69ef450186d7982468ce4c6f54fe2fa0` (latar bengkel prosedural sebelum latar konversi), `81d52c510b5d1bc715675a17de150433` (papan alat 236 lebar), `af3437483605c4f53214bb9555dbab9e` (sepeda tampak samping prosedural 124×72 sebelum sepeda dari gambar full body), `0351d78ef85ba2fd0e7d4b9da4e2e00c` (sepeda full body pertama: sadel pendek, kabel 2 px, ban belakang lonjong dan kiri bawah ban depan terpotong), `6f2f3584f2de132d48054a6fcf5c2150` (perbaikan pertama: pegangan setang masih coak, gir dan engkol belum menyatu, tanpa rantai), `36b93a68c6a3e83e76194f4f7aeaf630` dan `90993ea437019433323d4d75de336748` (chainstay yang tampak menancap ke ban; pipa step-through bergerigi), `d3a25f225eede42c995499578ba21adf` (seat stay tebal, terlalu tinggi, tidak ke poros).
