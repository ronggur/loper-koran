# Prompt Claude Design — Redesain UI (komponen bersama, bengkel, koran, hasil, jeda)

Disimpan 2026-10-23. Prompt untuk dijalankan di Claude Design; hasilnya adalah **kanvas usulan**, bukan tampilan yang langsung masuk game. Aturan repo (`.cursor/rules/art-assets.mdc`) melarang mengedit PNG dengan tangan, jadi aset gambar baru dari kanvas itu (ikon besar, sprite sepeda, ornamen, bingkai 9-slice) diporting jadi skrip renderer di `tools/ui_art/` dengan uji deterministik; sisanya (tata letak, StyleBox, teks) dibangun dari kode di `scenes/` dan `scripts/ui/`, dengan `scripts/ui/gaya_hud.gd` dan `assets/ui/theme.tres` sebagai tempat bentuk komponen bersama.

Sumber isi: `docs/design/DESIGN_SPEC.md` bagian 1 (token, tipografi, bentuk), 3 (HUD), dan 4 (baris Halaman depan koran, Hasil harian, Bengkel, Jeda); `GDD.md` 10.1, 12.3, 12.4; `assets/data/shop/upgrades.json`; `translations/ui.csv` dan `konten.csv`. Perbarui prompt ini bila bagian itu berubah.

Alasan redesain (uji HP pemilik 2026-10-23): UI terlalu kecil dan terlalu kosong, dan tombolnya polos. Acuan keadaan sekarang (tangkapan layar di repo):
- Bengkel: `docs/loop/20261020-fase6a1-bengkel-kondisi/shots/iter1/2340x1080_bengkel_ada_rusak.png`
- Halaman koran: `docs/loop/20261018-fase4a-koran-hari/shots/iter1/2340x1080_koran_hari1.png`
- Hasil harian: `docs/loop/20261023-fase6a2-reputasi-pelanggan/shots/iter1/2340x1080_reputasi_hasil_hari_biasa.png`
- Jeda: `docs/loop/20261018-fase3c-hud-hasil/shots/2340x1080_hud_jeda_sakelar.png`

Yang sengaja **tidak** diminta:
- Fitur atau layar baru: tidak ada tempat iklan (Fase 14), tidak ada pembelian uang asli, layar pengaturan dan peta distrik tetap belum ada.
- Perubahan aturan permainan atau ekonomi: harga, angka, urutan alur, dan teks dari `translations/` tidak berubah (teks boleh ditata ulang, bukan ditulis ulang).
- Perubahan tata letak HUD saat mengantar: posisi dan ukuran panelnya sudah disetel di HP (DESIGN_SPEC 3); hanya bahasa bentuk komponennya yang boleh diselaraskan.
- Upgrade tingkat 2 dan 3: hanya diminta cara menampungnya nanti, bukan isinya.

Hasil kanvas masih usulan sampai dinilai di HP; belum ada yang dikunci. Porting dikerjakan bertahap: komponen bersama dulu, lalu satu layar per run, dimulai dari bengkel.

```text
Buat kanvas desain "UI Loper Koran — Redesain": satu sistem komponen UI bersama plus
redesain layar penuh untuk game 2D mobile landscape bergaya Paperboy modern, pixel art,
latar Indonesia. Ini USULAN tampilan: hasilnya akan saya porting jadi kode Godot
(Container + StyleBox + 9-slice + sprite dari renderer Python), bukan PNG yang diedit
tangan. Semua layar harus terasa satu keluarga dengan dunia pixel art game (rumah,
sepeda, koran), tidak seperti kotak web polos.

MASALAH UI SEKARANG (acuan: empat tangkapan layar yang saya lampirkan/rujuk)
- Terlalu kecil: ikon 14 px, kotak kondisi 5x5 px, teks 7-8 px, padahal layarnya lega.
- Terlalu kosong: bengkel dan koran menyisakan sepertiga sampai separuh layar kosong;
  layar hasil dan jeda hanya sebuah panel kecil mengambang di tengah area gelap; kartu
  punya celah lebar antara nama dan harga.
- Tombol polos: kotak 1 px berisi teks, tanpa kedalaman, tanpa ikon, tanpa perbedaan jelas
  antara aksi utama, aksi biasa, dan sakelar. Keadaan ditekan dan nonaktif nyaris sama.
- Hirarki lemah: semua baris sama besar dan sama redup; yang penting tidak menonjol.
- Tidak ada nuansa tempat: bengkel tidak terasa bengkel, koran tidak terasa koran (hanya
  teks di atas krem), hasil tidak terasa merayakan antaran.

UKURAN DAN PIKSEL (wajib, berlaku untuk semua papan)
- Kanvas dasar 640x360 px game, ditampilkan diperbesar bilangan bulat (x3 / x5) dengan
  image-rendering: pixelated. Tanpa anti-aliasing, blur, gradien, atau skala pecahan.
  Di HP 2340x1080 skalanya 3x; rasio lain: 1920x1080, 2400x1080, 1600x720 (lebar viewport
  game melebar sampai sekitar 800, jadi layout harus lentur, jangan patok 640).
- Margin layar minimal 12 px + inset aman perangkat (notch/gesture bar) di semua tepi.
- Sentuh: semua tombol minimal 42 px game tingginya (>= 44 dp di HP) dan 84 px lebarnya;
  jarak antar tombol minimal 6 px.
- Gambar ukuran dalam piksel game, dan cantumkan ukuran/jarak tiap elemen di kanvas supaya
  bisa saya porting.
- Warna TIDAK BOLEH jadi satu-satunya pembeda keadaan: pasangkan dengan bentuk, ikon, atau
  teks (aksesibilitas buta warna).

TOKEN (pakai ini saja, jangan buat warna baru)
Layar gelap: UI_BG #1C130F latar · UI_PANEL #2A1E17 kartu · UI_PANEL_RAISED #36281E garis
dalam, bar kosong · HUD_PANEL #0E0A1C alpha 84% panel di atas jalan · OUTLINE #0E0A1C garis
luar 1 px · TEXT #FFF3E3 · TEXT_2 #CDB9A3 · ACCENT #FFB22E label penting dan aksi utama ·
OK #56C46E (terkirim, tip, selesai) · FAIL #D94F3D (meleset) · WARN #FF8A3D (perlu servis,
batas ngebut).
Halaman koran (satu-satunya layar terang): KORAN_KERTAS #F2E7C9 · KORAN_KERTAS_2 #E6D8B1 ·
KORAN_TINTA #1C130F · KORAN_TINTA_2 #4A3A2C · KORAN_GARIS #7A6642.
Palet induk pixel art untuk ikon dan ornamen (terang · dasar · gelap): krem #FBF6E8 ·
#F2E7C9 · #C2AF86; kayu #B47C5F · #96643C · #553428; logam #C4C0C8 · #969AA0 · #67636D;
logam gelap #5F5B66 · #3D4649 · #221E26; aksen hangat #FFE08A · #FFC94A · #E98E3F;
merah bata #B5523B · #994532 · #673F31; hijau #6FAE4F · #466E50 · #314D38;
biru #9BC4D8 · #5F96C8 · #466E8C.
Kuning/oranye hangat = sasaran dan peringatan di game; jangan dipakai untuk dekorasi
di layar yang membawa status.
Font: judul layar Lilita One 16 (boleh sampai 24-32 untuk judul utama), angka Lexend
SemiBold 10, teks utama Lexend SemiBold 8, teks kecil Lexend Regular 7, label HURUF
KAPITAL Lexend SemiBold 8 spasi 0,1 em. Boleh naikkan ukuran di layar penuh bila ruang
ada (target teks utama >= 10 px dan teks kecil >= 8 px di layar penuh; di HUD tetap).
Panel: 9-slice 12x12 piksel, garis luar 1 px OUTLINE, garis dalam 1 px UI_PANEL_RAISED,
sudut tumpul 3 px bertingkat (bukan radius halus). Ikon yang sudah ada (14x14): ban, rem,
rantai, koin, bintang reputasi, misi kucing, lencana milestone perunggu/perak/emas. Boleh
digambar versi lebih besar (24-32 px) dengan gaya sama: garis luar 1 px #0E0A1C, tiga
nada per material, cahaya dari kiri atas.

PRIORITAS (kerjakan urut; tiap butir = beberapa papan)

1. SISTEM KOMPONEN BERSAMA (papan "Komponen")
   Rancang sekali, dipakai di semua layar:
   - Tombol: empat peran (aksi utama terisi ACCENT teks gelap; aksi biasa; sakelar
     nyala/mati; aksi bahaya-ringan/lewati yang lebih tenang), masing-masing dengan
     keadaan normal, ditekan (bergeser 1-2 px ke bawah / bingkai ACCENT), nonaktif
     (redup, teks alasan seperti "Koin kurang", terbaca tanpa warna), dan fokus. Bentuk
     bertingkat piksel dengan sisi atas terang dan sisi bawah gelap supaya terasa bisa
     ditekan; boleh ikon di dalam tombol. Ukuran standar: 84x42, 96x42, 140x42.
   - Panel dan kartu: panel layar (UI_PANEL), kartu bertingkat (kartu biasa, kartu
     menonjol karena butuh perhatian, kartu redup karena sudah selesai), judul bagian
     (label KAPITAL ACCENT dengan garis), pemisah.
   - Chip dan penanda: chip harga (ikon koin + angka + "koin"), chip status ("Baik" OK,
     "Perlu servis" WARN dengan "!", "Dimiliki"), chip saldo, penanda tingkat I/II/III.
   - Kondisi sepeda: tiga kotak per komponen versi besar (minimal 8x8 px) dengan tiga
     tingkat: BAIK (tiga kotak terisi TEXT), AUS (dua terisi, satu BERONGGA), PERLU
     SERVIS (satu terisi WARN + tanda "!" WARN).
   - Bilah progres (milestone, kondisi): garis luar OUTLINE, dasar UI_PANEL, isi ACCENT,
     angka "n/target" di kanan.
   - Versi terang untuk halaman koran: tombol, panel, dan pemisah memakai token koran.
   Tunjukkan semuanya dalam satu papan dengan ukuran piksel dan jarak. Tandai mana yang
   9-slice/sprite baru dan mana yang StyleBox dari kode.

2. BENGKEL (layar terpenting)
   Isi wajib (jangan tambah fitur):
   - Judul "Bengkel" dan saldo koin (ikon koin + angka berpemisah ribuan titik, "1.250").
   - SERVIS: Ban, Rem, Rantai. Tiap komponen: ikon, nama, kondisi, harga "105 koin", dan
     tombol "Servis" atau label "Baik" (hijau, tombol hilang) bila penuh.
   - Catatan "Banyak yang rusak: ongkos servis x1.25", hanya muncul bila >= 2 komponen
     PERLU SERVIS. Beri tempat tetap supaya layout tidak melompat.
   - UPGRADE: tiga kartu tingkat 1: "Ban Anti-Selip — Belok lebih lincah (+15%) — 600
     koin", "Rem Pakem — Berhenti lebih cepat (+20%) — 500 koin", "Rantai Hemat — Stamina
     awet dan rantai lebih tahan — 700 koin". Tombol "Beli" atau label "Dimiliki".
     Rancang supaya nanti bisa bertambah tingkat 2 dan 3 per komponen (tunjukkan caranya
     di satu papan), tapi tiga upgrade sekarang HARUS muat tanpa scroll.
   - "Hari berikutnya": aksi utama, SELALU aktif, posisi tetap di kanan bawah. Bengkel
     boleh dilewati kapan saja.
   Arah yang saya inginkan (usulan, boleh Anda bantah dengan alasan):
   - Isi ruang dengan sesuatu yang bermakna: panel "sepeda" berisi ilustrasi pixel sepeda
     tampak samping (sisi kanan, cahaya kiri atas) dengan ban, rem, rantai ditandai dan
     tersambung ke kartu servisnya, sehingga kondisi terbaca sekilas dari sepedanya.
     Beri 2 alternatif tata letak (A: sepeda di tengah, servis kiri dan upgrade kanan;
     B: sepeda di kiri atas, servis dan upgrade bertab/bertumpuk di kanan) dan
     rekomendasikan satu.
   - Ikon dan kondisi jadi elemen paling terbaca di kartu. Harga di chip dekat tombolnya,
     bukan terpisah jauh di tengah kartu.
   - Hirarki: komponen PERLU SERVIS paling menonjol; upgrade lebih tenang; "Hari
     berikutnya" paling terang.
   - Nuansa bengkel hangat dan kecil-kecilan (papan peralatan, rak, lampu gantung) lewat
     latar bernada rendah dekat UI_BG, TANPA mengurangi kontras teks (>= 7:1 teks, >= 3:1
     garis komponen).
   Keadaan (satu papan tiap keadaan): a. hari pertama, semua BAIK; b. ban dan rem PERLU
   SERVIS + catatan ongkos x1.25; c. saldo kurang, tombol nonaktif "Koin kurang"; d. sesudah
   beli upgrade, "Dimiliki"; e. terpadat: tiga rusak + catatan + saldo enam digit + tiga
   upgrade; f. galat data: pesan "Daftar upgrade tidak bisa dimuat; servis tetap bisa"
   (WARN), servis dan "Hari berikutnya" tetap jalan; g. dengan inset aman.

3. HALAMAN DEPAN KORAN ("Warta Kring"; satu-satunya layar terang; momen membaca)
   Isi wajib: nama koran "Warta Kring" dan "Hari N · Perumahan Melati"; BERITA UTAMA (satu
   headline, paling menonjol, dengan ikon efek hari itu); BERITA RINGAN (satu headline);
   panel MISI SAMPINGAN (label, headline misi, ringkasan satu baris, tombol Ambil dan
   Lewati, satu baris status: "Misi diambil" / "Misi dilewati" / "Belum dipilih; berangkat =
   dilewati"); tombol "Berangkat" di kanan bawah (zona jempol kanan, aksi utama, terisi
   tinta penuh); satu baris notifikasi save bila ada ("Save rusak..." dll). Tanpa tombol
   jeda. Tanpa misi memenuhi syarat: tombol Ambil/Lewati hilang dan baris misi berisi
   "Tidak ada misi sampingan hari ini". Headline maksimal 40 karakter, ringkasan 60.
   Ambil/Lewati: terpilih = BERONGGA dengan bingkai tinta 3 px, tidak terpilih = garis
   tipis 1 px (bentuk, bukan warna), dan Berangkat tetap tampak sebagai aksi utama.
   Arah (usulan): buat terasa seperti halaman koran sungguhan, bukan teks di atas krem:
   masthead dengan garis ganda dan tanggal, kolom dan pemisah, kotak foto pixel art kecil
   di samping berita utama (mis. ilustrasi jalan diperbaiki), tekstur kertas halus tanpa
   gradien (pola titik 1 px bernada KORAN_KERTAS_2), tinta tetap kontras >= 7:1. Isi ruang
   bawah yang kosong dengan sesuatu bermakna (kotak pengumuman kecil bertuliskan
   hiasan yang jelas bukan fitur, atau kartu "hari ini" ringkas), jangan menambah informasi baru.
   Keadaan: hari 1 dengan misi (Belum dipilih), Ambil terpilih, Lewati terpilih, tanpa
   misi, hari lanjutan, teks terpanjang (headline 40 dan ringkasan 60 karakter),
   notifikasi save rusak, inset aman.

4. HASIL HARIAN (momen menutup antaran; netral, tanpa merah besar dan tanpa kata "gagal")
   Isi wajib, kolom utama: Terkirim "22/25", Tip "+25 dari 1 pelanggan", Koin, Skor (pemisah
   ribuan), Tepat; lalu yang netral: Meleset, Koran terbuang "1 koran (-5)", Koin bersih,
   status tenggat ("Sampai sebelum tenggat" / "Lewat tenggat +m:ss; tip sesudahnya tidak
   ada"); rekap misi satu baris (selesai OK: "Misi: Kucing ketemu! +75 koin", gagal netral:
   "Misi: Kucingnya lolos hari ini"); sampai tiga baris "Rantai perlu servis" (WARN) bila
   ada yang rusak; tombol "Ke bengkel" (aksi utama; di rute lepas "Main lagi"). Kolom
   samping: Reputasi (ikon bintang, "12 (+2)", naik OK dengan tanda plus/minus tertulis),
   Pelanggan (Pelanggan baru / Jadi pelanggan tetap / Berhenti berlangganan / Berlangganan
   lagi, hanya baris yang bukan nol, netral), Target berikutnya (lencana, "Nama · Tingkat",
   bilah progres, "n/target"), sampai tiga baris "Baru: Nama · Tingkat" (OK, lencana). Semua
   milestone emas: "Semua target sudah emas". Tanpa data reputasi, kolom samping hilang.
   Arah (usulan): manfaatkan seluruh layar, bukan panel kecil di tengah: angka utama
   (Terkirim, Koin) besar sebagai fokus, ikon kecil di tiap baris, jumlah yang naik tampak
   seperti struk/tiket pengantaran, dan lencana milestone cukup besar untuk dinikmati.
   Keadaan: hari biasa, hari minus (potongan > pendapatan, saldo dijepit 0), semua
   terkirim, lewat tenggat, pelanggan berhenti/kembali/setia, milestone baru, semua emas,
   kasus terpadat (potongan + rekap misi + tiga baris kondisi + reputasi + empat baris
   pelanggan + milestone + tiga tingkat baru + tenggat lewat), tanpa data reputasi, inset.

5. JEDA (overlay di atas jalan)
   Isi wajib: judul "JEDA"; "Lanjut" (aksi utama); sakelar "Kidal: mati/nyala" dan "Bantu:
   mati/nyala" (satu ketukan membalik; status dari teks dan bingkai/ikon, bukan warna
   saja). Latar: jalan tetap terlihat di balik lapisan gelap (HUD_PANEL). Arah (usulan):
   panel sendiri yang rapi di tengah (bukan tiga tombol melayang), "Lanjut" paling menonjol,
   sakelar jelas sebagai sakelar (bentuk geser/centang), ruang untuk "Keluar ke menu" dan
   "Pengaturan" nanti tanpa menggambarnya sebagai fitur aktif.

6. TUTORIAL (overlay petunjuk hari 1) dan banner kecil
   Isi wajib: "PETUNJUK 1/4", satu kalimat ("Dorong stick ke atas untuk ngebut", "Tarik
   stick ke bawah untuk melambat", "Lempar koran ke kotak surat", "Menepi dan berhenti
   dekat kucing"), tombol "Lewati". Juga banner "Rute selesai" dan banner misi (selesai
   OK, gagal netral). Jangan menutupi jalan di depan sepeda.

7. HUD SAAT MENGANTAR (HANYA penyelarasan bentuk, opsional)
   Posisi dan ukuran panel progres, koin, skor, kondisi, radar, kecepatan, koran, tombol
   jeda dan bel TIDAK berubah. Tunjukkan satu papan HUD dengan panel, tombol jeda, tombol
   bel, dan chip memakai bahasa bentuk komponen baru (sudut, garis dalam, ikon) agar satu
   keluarga dengan layar penuh, tanpa menambah area yang menutupi jalan.

KELUARAN
- Papan "Komponen" (butir 1), lalu papan per layar dan per keadaan di 640x360 dan satu
  papan di lebar 800 untuk tiap layar penuh.
- Satu papan "Spesifikasi": ukuran piksel, jarak, token warna dan font tiap elemen, urutan
  Container (HBox/VBox/Grid) yang masuk akal, dan daftar aset gambar baru (nama + ukuran,
  mis. ikon besar, sprite sepeda, ornamen, bingkai 9-slice tombol) dibedakan dari yang
  cukup StyleBox/teks dari kode.
- Di akhir, tulis 5-8 keputusan desain yang Anda ambil dan alasannya, dan urutan porting
  yang Anda sarankan, supaya bisa saya nilai di HP.
```
