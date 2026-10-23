# Prompt Claude Design — Layar Bengkel (redesain)

Disimpan 2026-10-23. Prompt untuk dijalankan di Claude Design; hasilnya adalah **kanvas usulan**, bukan tampilan yang langsung masuk game. Aturan repo (`.cursor/rules/art-assets.mdc`) melarang mengedit PNG dengan tangan, jadi aset gambar baru dari kanvas itu (sprite sepeda, ikon besar, ornamen) diporting jadi skrip renderer di `tools/ui_art/` dengan uji deterministik; sisanya (panel, tombol, tata letak) dibangun dari kode di `scenes/bengkel/bengkel.tscn` dan `scripts/ui/layar_bengkel.gd`.

Sumber isi: `docs/design/DESIGN_SPEC.md` bagian 1 (token, tipografi, bentuk), 3.3 (kondisi sepeda), dan 4 baris "Bengkel" (sketsa run 6A1 bagian B); `GDD.md` 12.3 dan 12.4; `assets/data/shop/upgrades.json`; `translations/ui.csv` kunci `BENGKEL_*`. Perbarui prompt ini bila bagian itu berubah.

Alasan redesain (uji HP pemilik 2026-10-23): tampilan terlalu kecil dan terlalu kosong. Acuan keadaan sekarang: `docs/loop/20261020-fase6a1-bengkel-kondisi/shots/iter1/2340x1080_bengkel_ada_rusak.png`.

Yang sengaja **tidak** diminta:
- Fitur baru: tidak ada tempat iklan (Fase 14), tidak ada pembelian uang asli, tidak ada menu lain.
- Perubahan aturan ekonomi: harga servis, harga upgrade, dan ongkos naik dari `Economy` dan `assets/data/shop/upgrades.json` tidak berubah.
- Upgrade tingkat 2 dan 3: hanya diminta cara menampungnya nanti, bukan isinya.

Hasil kanvas masih usulan sampai dinilai di HP; belum ada yang dikunci.

```text
Buat kanvas desain "Layar Bengkel — Loper Koran": redesain layar bengkel untuk game 2D mobile
landscape bergaya Paperboy modern, pixel art, latar Indonesia. Ini USULAN tampilan: hasilnya
akan saya porting jadi kode Godot (Container + StyleBox + sprite dari renderer Python), bukan
PNG yang diedit tangan. Gayanya harus satu keluarga dengan HUD rute dan layar hasil
(token di bawah).

MASALAH LAYAR SEKARANG (acuan: tangkapan "bengkel_ada_rusak")
- Terlalu kecil: ikon komponen 14 px dan kotak kondisi 5x5 px, padahal kartunya lebar.
  Info terpenting (kondisi) justru paling kecil.
- Terlalu kosong: tiap kartu punya celah lebar antara nama dan harga, dan sepertiga bawah
  layar kosong. Dua kolom kartu polos berwarna sama tanpa hirarki.
- Kartu upgrade tanpa ikon. Tombol hanya kotak polos. Tidak ada nuansa "bengkel".
- Tidak ada tempat memandang sepeda sendiri, padahal inilah tempat pemain merawatnya.

UKURAN DAN PIKSEL (wajib)
- Kanvas dasar 640x360 px game, ditampilkan diperbesar bilangan bulat (x3 / x5) dengan
  image-rendering: pixelated. Tanpa anti-aliasing, blur, gradien, atau skala pecahan.
  Di HP 2340x1080 skalanya 3x; rasio lain: 1920x1080, 2400x1080, 1600x720 (lebar viewport
  game melebar sampai sekitar 800, jadi layout harus lentur, jangan patok 640).
- Margin layar minimal 12 px + inset aman perangkat (notch/gesture bar) di semua tepi.
- Sentuh: semua tombol minimal 42 px game tingginya (>= 44 dp di HP) dan 84 px lebarnya.
- Gambar ukuran dalam piksel game, dan cantumkan ukuran/jarak tiap elemen di kanvas supaya
  bisa saya porting.

TOKEN (pakai ini saja, jangan buat warna baru)
UI_BG #1C130F latar layar · UI_PANEL #2A1E17 kartu · UI_PANEL_RAISED #36281E garis dalam,
bar kosong · OUTLINE #0E0A1C garis luar 1 px · TEXT #FFF3E3 · TEXT_2 #CDB9A3 ·
ACCENT #FFB22E label penting dan aksi utama · OK #56C46E · FAIL #D94F3D · WARN #FF8A3D
(perlu servis). Panel: 9-slice 12x12, garis luar 1 px OUTLINE, garis dalam 1 px
UI_PANEL_RAISED, sudut tumpul 3 px bertingkat (bukan radius halus).
Font: judul layar Lilita One 16 (boleh sampai 24), angka Lexend SemiBold 10, teks utama
Lexend SemiBold 8, teks kecil Lexend Regular 7, label HURUF KAPITAL Lexend SemiBold 8 spasi
0,1 em. Boleh naikkan ukuran teks di layar ini bila ruang ada (teks 7 px terlalu kecil).
Ikon yang sudah ada (14x14): ban, rem, rantai, koin, bintang reputasi. Boleh digambar
versi lebih besar (24-32 px) dengan gaya sama: garis luar 1 px #0E0A1C, tiga nada per
material, cahaya dari kiri atas.

ISI LAYAR (semua wajib ada, jangan tambah fitur)
1. Judul "Bengkel" dan saldo koin (ikon koin + angka berpemisah ribuan titik, "1.250").
2. SERVIS: tiga komponen (Ban, Rem, Rantai). Tiap komponen: ikon, nama, kondisi, harga
   "105 koin", dan tombol "Servis" atau label "Baik" (hijau, tombol hilang) bila kondisi
   penuh. Kondisi = tiga tingkat: BAIK (tiga kotak terisi TEXT), AUS (dua kotak terisi,
   satu BERONGGA), PERLU SERVIS (satu kotak WARN + tanda "!" WARN, teks "Perlu servis").
   Warna TIDAK BOLEH jadi satu-satunya pembeda: pasangkan dengan bentuk (kotak berongga,
   "!") dan teks.
3. Catatan "Banyak yang rusak: ongkos servis x1.25", hanya muncul bila >= 2 komponen PERLU
   SERVIS. Beri tempat tetap supaya layout tidak melompat.
4. UPGRADE: tiga kartu tingkat 1: "Ban Anti-Selip — Belok lebih lincah (+15%) — 600 koin",
   "Rem Pakem — Berhenti lebih cepat (+20%) — 500 koin", "Rantai Hemat — Stamina awet dan
   rantai lebih tahan — 700 koin". Tombol "Beli" atau label "Dimiliki" bila sudah punya.
   Rancang supaya nanti bisa bertambah tingkat 2 dan 3 per komponen (tunjukkan caranya di
   satu papan, mis. penanda tingkat I/II/III), tapi tiga upgrade sekarang HARUS muat tanpa
   scroll.
5. Tombol "Hari berikutnya": aksi utama (ACCENT terisi, teks gelap UI_BG), SELALU aktif,
   posisi tetap di kanan bawah. Bengkel boleh dilewati kapan saja.
6. Tanpa tempat iklan, tanpa pembelian uang asli, tanpa menu lain.

ARAH YANG SAYA INGIN (usulan, boleh Anda bantah dengan alasan)
- Isi ruang dengan sesuatu yang bermakna, bukan hiasan acak: mis. panel "sepeda" berisi
  ilustrasi pixel sepeda tampak samping (sisi kanan, cahaya kiri atas) dengan ban, rem,
  rantai ditandai dan tersambung ke kartu servisnya, sehingga kondisi terbaca sekilas
  dari sepedanya. Beri 2 alternatif tata letak (A: sepeda di tengah, servis kiri dan upgrade
  kanan; B: sepeda di kiri atas, daftar servis dan upgrade bertab/bertumpuk di kanan) dan
  rekomendasikan satu.
- Ikon dan kondisi harus jadi elemen paling terbaca di kartu (kotak kondisi minimal 8x8 px).
  Harga di chip kecil berikon koin, dekat tombolnya, bukan terpisah jauh di tengah kartu.
- Hirarki jelas: aksi yang mendesak (komponen PERLU SERVIS) paling menonjol; upgrade lebih
  tenang; "Hari berikutnya" paling terang.
- Nuansa bengkel hangat dan kecil-kecilan (papan peralatan, rak, lampu gantung) lewat
  latar bernada rendah di dekat UI_BG, TANPA mengurangi kontras teks (target kontras teks
  >= 7:1, garis komponen >= 3:1).
- Tombol punya tiga keadaan yang jelas: normal, ditekan, nonaktif.

KEADAAN YANG HARUS DIGAMBAR (satu papan per keadaan, di 640x360 dan satu di lebar 800)
a. Hari pertama: sepeda baru, semua BAIK, saldo kecil. Semua tombol Servis diganti "Baik".
b. Ada rusak: ban dan rem PERLU SERVIS, rantai BAIK, catatan ongkos x1.25 tampil.
c. Saldo kurang: tombol nonaktif, teksnya berganti "Koin kurang" (terbaca tanpa warna),
   bingkai dan isi redup. Menekannya tidak melakukan apa pun.
d. Sesudah beli upgrade: kartu berubah ke "Dimiliki".
e. Terpadat: tiga komponen rusak + catatan ongkos + saldo enam digit + tiga upgrade.
f. Galat data: daftar upgrade tidak bisa dimuat. Pesan "Daftar upgrade tidak bisa dimuat;
   servis tetap bisa" (WARN) tampil jujur, servis dan "Hari berikutnya" tetap jalan.
g. Dengan inset aman (mis. 24 px kiri/kanan, 16 px bawah).

KELUARAN
- Papan per keadaan, diberi label, plus satu papan "spesifikasi": daftar ukuran piksel,
  jarak, token warna dan font tiap elemen, urutan Container (HBox/VBox) yang masuk akal,
  dan ikon/sprite baru yang diminta (nama + ukuran).
- Tandai jelas mana yang aset gambar baru (sprite sepeda, ikon besar, ornamen) dan mana yang
  cukup StyleBox/teks dari kode.
- Di akhir, tulis 3-5 keputusan desain yang Anda ambil dan alasannya, supaya bisa saya nilai
  di HP.
```
