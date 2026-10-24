class_name TampilHud
extends RefCounted
## Pemilihan tampilan HUD rute sebagai data murni (run ui2-semua-layar bagian C2; SPEC V-9, AC-6; kanvas HUD.dc.html; usulan): tombol jeda berbentuk tombol biasa, panel bawah kecepatan dan stamina
## berdampingan (margin kiri dan kanan, tanda batas ngebut di bar, warna stamina), dan isi baris 2 kolom kanan atas (kondisi sepeda + reputasi dalam satu panel). `HudDasar`, `HudRute`, `BarKecepatan`,
## dan `TombolJeda` hanya mewujudkan pilihan ini. Tanpa node, `Time`, atau RNG.


## Warna isi bar stamina: `FAIL` di bawah `HUD_STAMINA_AMBANG_RENDAH` (DESIGN_SPEC 3.5), selain itu `ACCENT`. Tepat di ambang masih `ACCENT`.
static func warna_stamina(stamina: float) -> Color:
	return Palette.FAIL if stamina < Config.HUD_STAMINA_AMBANG_RENDAH else Palette.ACCENT


## Posisi tanda batas ngebut di dalam isi bar selebar `lebar_dalam` (piksel game, tanpa garis luar): lebar x `pecahan`, dibulatkan ke bawah supaya tajam; 0 bila lebar atau pecahan tidak sah.
static func posisi_tanda(lebar_dalam: float, pecahan: float) -> int:
	if not is_finite(lebar_dalam) or not is_finite(pecahan) or lebar_dalam <= 0.0 or pecahan <= 0.0:
		return 0
	return floori(lebar_dalam * minf(pecahan, 1.0))


## Margin kiri dan kanan (`Vector2i(kiri, kanan)`) baris panel bawah: sisi stick `HUD_PANEL_KECEPATAN_GESER_PX`, sisi swipe `HUD_MARGIN_TEPI_PX`; kidal menukar keduanya (dicerminkan).
static func margin_bawah(kidal: bool) -> Vector2i:
	var geser: int = Config.HUD_PANEL_KECEPATAN_GESER_PX
	var tepi: int = Config.HUD_MARGIN_TEPI_PX
	return Vector2i(tepi, geser) if kidal else Vector2i(geser, tepi)


## True bila panel koran digambar paling awal di baris bawah (kidal: koran di sisi luar kiri, panel kecepatan di sisi stick kanan); false = paling akhir.
static func koran_di_awal(kidal: bool) -> bool:
	return kidal


## Nama dasar tekstur bingkai tombol jeda HUD (`KomponenUi`, peran biasa): normal atau ditekan.
static func nama_bingkai_jeda(ditekan: bool) -> String:
	return KomponenUi.nama_tekstur_tombol(KomponenUi.Peran.BIASA, KomponenUi.keadaan_tombol(true, ditekan))


## Nama dasar tekstur glif di tombol jeda HUD.
static func nama_glif_jeda() -> String:
	return "glif_jeda_terang"


## Pojok kiri atas glif jeda 12x12 di dalam wajah tombol jeda 24x24 (piksel game dari pojok tombol): tengah mendatar, tegak di tengah area isi bingkai 9-slice (tepi atas dan bawah 6) yang
## bergeser 2 px karena bibir bawah (normal: isi naik, ditekan: isi turun), seperti `KomponenUi.margin_isi_tombol`.
static func posisi_glif_jeda(ditekan: bool) -> Vector2i:
	var tambah: Vector2i = KomponenUi.margin_isi_tombol(KomponenUi.Peran.BIASA, KomponenUi.keadaan_tombol(true, ditekan))
	var atas: int = Config.UI_TOMBOL_SLICE_ATAS_PX + tambah.x
	var bawah: int = Config.HUD_JEDA_GAMBAR_PX - Config.UI_TOMBOL_SLICE_BAWAH_PX - tambah.y
	var x: int = floori(float(Config.HUD_JEDA_GAMBAR_PX - Config.HUD_JEDA_GLIF_PX) / 2)
	var y: int = atas + floori(float(bawah - atas - Config.HUD_JEDA_GLIF_PX) / 2)
	return Vector2i(x, y)


## Reputasi yang ditampilkan: nilai dijepit `REPUTASI_MIN`..`REPUTASI_MAKS`; negatif = tidak ada (rute tanpa keadaan pelanggan) = -1.
static func kunci_reputasi(nilai: int) -> int:
	if nilai < 0:
		return -1
	return clampi(nilai, Config.REPUTASI_MIN, Config.REPUTASI_MAKS)


## True bila penanda reputasi tampil (kunci tidak negatif).
static func reputasi_tampil(kunci: int) -> bool:
	return kunci >= 0


## True bila panel baris 2 kolom kanan atas tampil: ada kondisi sepeda atau ada reputasi (V-9 H-2: reputasi berbagi panel kondisi, tidak lagi panel sendiri di baris 3).
static func baris2_tampil(ada_kondisi: bool, kunci: int) -> bool:
	return ada_kondisi or reputasi_tampil(kunci)


## Garis sumbu bar kecepatan dan stamina tanpa trek (revisi UI pemilik R-4): satu garis `UI_GARIS_PX` setinggi satu piksel di tengah tinggi bar (`floor(tinggi / 2)`, baris 4 dari 9), sepanjang lebar bar dikurangi `UI_GARIS_PX` di kedua ujung (R-7: garis abu terang tidak boleh menonjol keluar dari ujung isi, yang juga berinset `UI_GARIS_PX`).
## Koordinat lokal bar, piksel game; Rect2i kosong bila ukuran tidak positif atau lebar tidak cukup untuk dua inset.
static func rect_sumbu_bar(lebar_bar: int, tinggi_bar: int) -> Rect2i:
	if lebar_bar <= Config.UI_GARIS_PX * 2 or tinggi_bar <= 0:
		return Rect2i()
	var tengah: int = tinggi_bar / 2
	return Rect2i(Config.UI_GARIS_PX, tengah, lebar_bar - Config.UI_GARIS_PX * 2, Config.UI_GARIS_PX)
