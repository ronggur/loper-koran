class_name SpikeSisiDekat
extends AdeganJalan
## Spike rumah sisi dekat (TECH_PLAN Fase 3; run fase3c-hud-hasil AC-14 dan AC-15, usulan). Scene dev `scenes/dev/spike_sisi_dekat.tscn`,
## dikecualikan dari paket ekspor bersama skrip dan asetnya (`export_presets.cfg`, dijaga `tests/tes_export.gd`). TIDAK memutuskan apa pun:
## pemilik memilih pendekatan dari tangkapan layar (ROADMAP 5 "Cara menampilkan rumah di sisi dekat"). Rute perumahan tidak berubah.
##
## Jalan lurus (tanah `TanahDaur` yang sama dengan jalan uji dan rute) dengan rumah di dua sisi. Rumah disusun sebagai `RouteBuilder.Rute`
## buatan di kode (hanya di scene ini, tidak dari segmen): sisi seberang semuanya bukan pelanggan (konteks), sisi dekat bergantian
## pelanggan dan bukan menurut `POLA_PELANGGAN_DEKAT` (pelanggan dekat placeholder HANYA di spike; data rute perumahan tetap sisi dekat
## `bukan`). Penilaian koran, garis bidik, dan mode bantu memakai jalur yang sama dengan scene rute (`MedanKoran.dari_rute`,
## `ZonaSasaran.zona_rute_rentang`), jadi lemparan ke kotak surat sisi dekat dinilai seperti di game. Kotak surat sasaran sisi dekat =
## `scenes/entities/kotak_surat.tscn` di pusat zona kotak surat dekat, ditambah persegi zonanya di tanah (gaya `AreaKotakGambar`).
##
## Sakelar pendekatan (`atur_pendekatan`, tombol bernomor di pojok bawah tengah, tombol 1/2/3 keyboard di editor):
## 1. `RENDAH`: punggung rumah rendah dan kontras rendah (`spike_dekat_rendah_*`).
## 2. `TEMBOK`: tembok belakang rendah di kaki kavling (`spike_dekat_tembok_*`), rumah penuh di belakangnya digeser `RUMAH_TEMBOK_MUNDUR_UBIN`.
## 3. `PENUH`: punggung rumah penuh (`spike_dekat_penuh_*`, bukan pelanggan = sprite rute `house_perumahan_dekat_*_bukan`) yang dibuat
##    semi-transparan oleh aturan penutup yang SUDAH ADA: satu `PenerapPenutup` memanggil `PenutupPemain` untuk semua gambar terdaftar,
##    tanpa kode per objek. Aturan yang sama berlaku untuk gambar pendekatan 1 dan 2 (prinsip 3 berlaku untuk semua objek).
## Aset dari `tools/env_art/spike_sisi_dekat.py`; titik pijak, tapak, dan tinggi kotak penutup dibaca dari JSON aset (satu sumber).
##
## Angka di sini hanya tata letak spike (bukan tuning game, tidak masuk `Config`; scene ini tidak ikut paket game).

enum Pendekatan { RENDAH = 1, TEMBOK = 2, PENUH = 3 }

const FOLDER_SPIKE: String = "res://assets/sprites/_spike/sisi_dekat"
const ADEGAN_KOTAK_SURAT: PackedScene = preload("res://scenes/entities/kotak_surat.tscn")
## Jumlah kavling (petak 4 ubin) di tiap sisi.
const JUMLAH_KAVLING: int = 40
## Awal kavling pertama, ubin dari awal jalan.
const KAVLING_AWAL_UBIN: float = 8.0
## Status pelanggan rumah sisi dekat per kavling, diulang.
const POLA_PELANGGAN_DEKAT: Array[bool] = [true, false, true, true, false]
## Jenis rumah sisi dekat (atap) per kavling, diulang; sama dengan `tools/env_art/fase3.py` `RUMAH_DEKAT`.
const JENIS_DEKAT: Array[String] = ["limasan", "pelana_lintang", "pelana_sejajar"]
## Jenis rumah sisi seberang per kavling, diulang.
const JENIS_SEBERANG: Array[String] = ["limasan", "pelana", "sayap"]
## Pendekatan 2: pusat tembok belakang melintang jalan, ubin dari garis tengah (sisi jalan tembok tepat di kaki rumah sisi dekat 3,0).
const TEMBOK_X_UBIN: float = 3.125
## Pendekatan 2: rumah di belakang tembok digeser menjauh dari jalan sejauh ini dari tapak rumah dekat biasa, ubin.
const RUMAH_TEMBOK_MUNDUR_UBIN: float = 1.25
## Alfa piksel yang dihitung opak oleh `sasaran_tertutup` (bayangan tanah aset beralfa 28% tidak dihitung).
const ALFA_OPAK: float = 0.99

## Pendekatan yang sedang tampil.
var _pendekatan: Pendekatan = Pendekatan.PENUH
var _rute: RouteBuilder.Rute = RouteBuilder.Rute.new()
## Data aset spike per nama: {"pijak": Vector2i, "tapak": Rect2 (relatif titik pijak, maju positif), "tinggi": float}.
var _aset: Dictionary = {}
var _tekstur: Dictionary = {}
## Indeks rumah (di `_rute.rumah`) -> sprite rumah.
var _sprite_rumah: Dictionary = {}
## Indeks rumah dekat -> sprite tembok (pendekatan 2 saja tampil).
var _sprite_tembok: Dictionary = {}
## Indeks rumah dekat pelanggan -> kotak surat sasaran.
var _kotak: Dictionary = {}
## Gambar piksel tekstur (untuk `sasaran_tertutup`).
var _gambar: Dictionary = {}

@onready var _objek: Node2D = %Objek
@onready var _area: Node2D = %AreaSasaran
@onready var _penerap: PenerapPenutup = %PenerapPenutup
@onready var _tombol: TombolSentuh = %TombolPendekatan


func _siapkan_dunia() -> void:
	_rute = susun_rute()
	_medan = MedanKoran.dari_rute(_rute)
	_muat_aset()
	for i: int in range(_rute.rumah.size()):
		var rumah: RouteBuilder.RumahRute = _rute.rumah[i]
		var sprite: Sprite2D = _sprite_baru("Rumah_%d" % i)
		_sprite_rumah[i] = sprite
		if rumah.sisi != LoperAnim.Sisi.DEKAT:
			continue
		_sprite_tembok[i] = _sprite_baru("Tembok_%d" % i)
		if rumah.pelanggan:
			var kotak: Node2D = ADEGAN_KOTAK_SURAT.instantiate() as Node2D
			kotak.name = "Kotak_%d" % i
			kotak.position = Iso.posisi_gambar(_titik_kotak_surat(rumah))
			_objek.add_child(kotak)
			_kotak[i] = kotak
	var perintah: Array = _perintah_area()
	_area.draw.connect(func() -> void: GambarPiksel.gambar(_area, perintah))
	_area.queue_redraw()
	_tombol.ditekan.connect(_saat_tombol)
	atur_pendekatan(_pendekatan)


func _perbarui_dunia(_jarak_ubin: float) -> void:
	_penerap.terapkan(_sepeda.posisi_dunia())


func _zona_bantu(maju_awal_ubin: float, maju_akhir_ubin: float) -> Array[ZonaSasaran.Zona]:
	return ZonaSasaran.zona_rute_rentang(_rute.rumah, maju_awal_ubin, maju_akhir_ubin)


func _langkah_koran(keadaan: SisaKoran.Keadaan) -> SisaKoran.Keadaan:
	return SisaKoran.isi_ulang_jalan_uji(keadaan, _sepeda.jarak_ubin)


func _unhandled_input(event: InputEvent) -> void:
	# Keyboard hanya untuk editor (rule `gdscript`), sama dengan stick keyboard jalan uji.
	if event is InputEventKey and event.pressed and not event.echo:
		var tombol: Key = (event as InputEventKey).keycode
		if tombol >= KEY_1 and tombol <= KEY_3:
			var nomor: int = int(tombol - KEY_1) + 1
			atur_pendekatan(nomor as Pendekatan)


## Rute buatan spike: kavling 4 ubin di dua sisi, seberang bukan pelanggan, dekat pelanggan menurut `POLA_PELANGGAN_DEKAT`.
static func susun_rute() -> RouteBuilder.Rute:
	var rute: RouteBuilder.Rute = RouteBuilder.Rute.new()
	for k: int in range(JUMLAH_KAVLING):
		var maju: float = KAVLING_AWAL_UBIN + float(k * Config.RUTE_PETAK_UBIN)
		for sisi: LoperAnim.Sisi in [LoperAnim.Sisi.SEBERANG, LoperAnim.Sisi.DEKAT]:
			var rumah: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
			rumah.id_segmen = "spike"
			rumah.pos = int(maju)
			rumah.id = "spike@%d%s" % [rumah.pos, "d" if sisi == LoperAnim.Sisi.DEKAT else "s"]
			rumah.maju_ubin = maju
			rumah.sisi = sisi
			if sisi == LoperAnim.Sisi.DEKAT:
				rumah.jenis = "dekat_" + JENIS_DEKAT[k % JENIS_DEKAT.size()]
				rumah.pelanggan = POLA_PELANGGAN_DEKAT[k % POLA_PELANGGAN_DEKAT.size()]
			else:
				rumah.jenis = JENIS_SEBERANG[k % JENIS_SEBERANG.size()]
			rumah.pelanggan_boleh = rumah.pelanggan
			rute.rumah.append(rumah)
			if rumah.pelanggan:
				rute.pelanggan.append(rumah)
	rute.panjang_ubin = KAVLING_AWAL_UBIN + float(JUMLAH_KAVLING * Config.RUTE_PETAK_UBIN)
	rute.koran_awal = Config.KORAN_AWAL
	return rute


## Mengganti pendekatan yang tampil: tekstur dan letak gambar sisi dekat, tembok, lalu SEMUA gambar didaftarkan ulang ke satu penerap
## penutup dengan kotak dari aset yang tampil.
func atur_pendekatan(p: Pendekatan) -> void:
	_pendekatan = p
	_penerap.lepas_semua()
	for i: int in _sprite_rumah:
		var rumah: RouteBuilder.RumahRute = _rute.rumah[i]
		var sprite: Sprite2D = _sprite_rumah[i]
		if rumah.sisi != LoperAnim.Sisi.DEKAT:
			var nama_seberang: String = SpriteRumah.nama_rumah(rumah)
			_pasang(sprite, nama_seberang, SpriteRumah.titik_pijak(nama_seberang), SpriteRumah.pusat_tapak_dunia(rumah))
			_daftar(sprite, PenutupPemain.dari_rumah(rumah))
			continue
		var pusat: Vector2 = SpriteRumah.pusat_tapak_dunia(rumah)
		var tembok: Sprite2D = _sprite_tembok[i]
		tembok.visible = p == Pendekatan.TEMBOK
		var jenis: String = rumah.jenis.trim_prefix("dekat_")
		var nama: String = _nama_rumah_dekat(p, jenis, rumah.pelanggan)
		var geometri: String = nama if nama.begins_with("spike_") else "spike_dekat_penuh_%s_pelanggan" % jenis
		if p == Pendekatan.TEMBOK:
			pusat.x += RUMAH_TEMBOK_MUNDUR_UBIN
			var nama_tembok: String = "spike_dekat_tembok_%s" % ("pelanggan" if rumah.pelanggan else "bukan")
			var pusat_tembok: Vector2 = Vector2(TEMBOK_X_UBIN, pusat.y)
			_pasang(tembok, nama_tembok, _aset[nama_tembok]["pijak"], pusat_tembok)
			_daftar(tembok, _objek_aset(nama_tembok, pusat_tembok, rumah.id + "#tembok"))
		var pijak: Vector2i = _aset[nama]["pijak"] if _aset.has(nama) else SpriteRumah.titik_pijak(nama)
		_pasang(sprite, nama, pijak, pusat)
		_daftar(sprite, _objek_aset(geometri, pusat, rumah.id))
	if is_instance_valid(_tombol):
		_tombol.text = str(int(p))
	_penerap.terapkan(_sepeda.posisi_dunia())


## Pendekatan yang sedang tampil.
func pendekatan() -> Pendekatan:
	return _pendekatan


## Rute buatan spike.
func rute() -> RouteBuilder.Rute:
	return _rute


## Penerap penutup (untuk probe).
func penerap_penutup() -> PenerapPenutup:
	return _penerap


## Sprite rumah bernomor `indeks` (di `rute().rumah`).
func sprite_rumah(indeks: int) -> Sprite2D:
	return _sprite_rumah.get(indeks) as Sprite2D


## Fakta piksel untuk catatan perbandingan (probe): pecahan piksel sasaran rumah pelanggan dekat bernomor `indeks` yang tertutup piksel
## OPAK (alpha penuh) gambar rumah atau tembok yang digambar di depannya (urutan Y-sort: posisi tegak lebih besar). x = badan sprite
## kotak surat, y = persegi zona kotak surat di tanah (zona digambar di bawah semua objek, jadi semua gambar dihitung). Bayangan tanah
## (alpha sebagian) dan alfa penutup pemain tidak dihitung. 0 = sasaran terlihat penuh.
func sasaran_tertutup(indeks: int) -> Vector2:
	var kotak: Sprite2D = _kotak.get(indeks) as Sprite2D
	if kotak == null:
		return Vector2.ZERO
	var titik_kotak: Array[Vector2i] = []
	var gambar_kotak: Image = _gambar_untuk(kotak.texture)
	var asal_kotak: Vector2i = Vector2i(kotak.position + kotak.offset)
	for y: int in range(gambar_kotak.get_height()):
		for x: int in range(gambar_kotak.get_width()):
			if gambar_kotak.get_pixel(x, y).a >= ALFA_OPAK:
				titik_kotak.append(asal_kotak + Vector2i(x, y))
	var titik_zona: Array[Vector2i] = []
	for zona: ZonaSasaran.Zona in ZonaSasaran.zona_rumah(_rute.rumah[indeks]):
		if zona.jenis != ZonaSasaran.Jenis.KOTAK_SURAT:
			continue
		for r: Vector3i in PolaPiksel.rentang_poligon(PolaPiksel.sudut_zona(zona.persegi)):
			for x: int in range(r.y, r.z):
				titik_zona.append(Vector2i(x, r.x))
	return Vector2(_pecahan_tertutup(titik_kotak, kotak.position.y), _pecahan_tertutup(titik_zona, -INF))


func _pecahan_tertutup(titik: Array[Vector2i], y_acuan: float) -> float:
	if titik.is_empty():
		return 0.0
	var depan: Array[Sprite2D] = []
	for daftar: Dictionary in [_sprite_rumah, _sprite_tembok]:
		for sprite: Sprite2D in daftar.values():
			if sprite.visible and sprite.texture != null and sprite.position.y > y_acuan:
				depan.append(sprite)
	var tertutup: int = 0
	for t: Vector2i in titik:
		for sprite: Sprite2D in depan:
			var gambar: Image = _gambar_untuk(sprite.texture)
			var lokal: Vector2i = t - Vector2i(sprite.position + sprite.offset)
			if lokal.x >= 0 and lokal.y >= 0 and lokal.x < gambar.get_width() and lokal.y < gambar.get_height() and gambar.get_pixelv(lokal).a >= ALFA_OPAK:
				tertutup += 1
				break
	return float(tertutup) / float(titik.size())


func _gambar_untuk(tekstur: Texture2D) -> Image:
	if not _gambar.has(tekstur):
		_gambar[tekstur] = tekstur.get_image()
	return _gambar[tekstur]


func _nama_rumah_dekat(p: Pendekatan, jenis: String, pelanggan: bool) -> String:
	if p == Pendekatan.RENDAH:
		return "spike_dekat_rendah_%s_%s" % [jenis, "pelanggan" if pelanggan else "bukan"]
	if pelanggan:
		return "spike_dekat_penuh_%s_pelanggan" % jenis
	return SpriteRumah.nama("dekat_" + jenis, false)


func _saat_tombol() -> void:
	var nomor: int = (int(_pendekatan) % 3) + 1
	atur_pendekatan(nomor as Pendekatan)


func _sprite_baru(nama: String) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = false
	sprite.name = nama
	_objek.add_child(sprite)
	return sprite


func _pasang(sprite: Sprite2D, nama: String, pijak: Vector2i, pusat_dunia: Vector2) -> void:
	sprite.texture = _tekstur_untuk(nama)
	sprite.offset = -Vector2(pijak)
	sprite.position = Iso.posisi_gambar(pusat_dunia)
	sprite.modulate.a = PenutupPemain.alfa(false)


func _daftar(gambar: CanvasItem, objek: PenutupPemain.Objek) -> void:
	_penerap.daftarkan(gambar, objek)


## Kotak penutup aset `nama` yang titik pijaknya di `pusat_dunia` (y dunia = -maju): tapak JSON relatif titik pijak, maju positif.
func _objek_aset(nama: String, pusat_dunia: Vector2, id: String) -> PenutupPemain.Objek:
	var relatif: Rect2 = _aset[nama]["tapak"]
	var tapak: Rect2 = Rect2(Vector2(pusat_dunia.x, -pusat_dunia.y) + relatif.position, relatif.size)
	return PenutupPemain.buat(tapak, _aset[nama]["tinggi"], id)


func _titik_kotak_surat(rumah: RouteBuilder.RumahRute) -> Vector2:
	for z: ZonaSasaran.Zona in ZonaSasaran.zona_rumah(rumah):
		if z.jenis == ZonaSasaran.Jenis.KOTAK_SURAT:
			var pusat: Vector2 = z.persegi.get_center()
			return Vector2(pusat.x, -pusat.y)
	return Vector2.ZERO


func _perintah_area() -> Array:
	var hasil: Array = []
	for rumah: RouteBuilder.RumahRute in _rute.rumah:
		if not rumah.pelanggan:
			continue
		for zona: ZonaSasaran.Zona in ZonaSasaran.zona_rumah(rumah):
			if zona.jenis != ZonaSasaran.Jenis.KOTAK_SURAT:
				continue
			var isi: Array[Vector3i] = PolaPiksel.rentang_poligon(PolaPiksel.sudut_zona(zona.persegi))
			hasil.append([isi, Vector2.ZERO, Color(Palette.ACCENT, Config.AREA_KOTAK_ISI_ALPHA)])
			hasil.append([PolaPiksel.rentang_tepi(isi), Vector2.ZERO, Color(Palette.OUTLINE, Config.AREA_KOTAK_TEPI_ALPHA)])
	return hasil


func _muat_aset() -> void:
	for berkas: String in DirAccess.get_files_at(FOLDER_SPIKE):
		if not berkas.ends_with(".json"):
			continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("%s/%s" % [FOLDER_SPIKE, berkas]))
		if not (data is Dictionary):
			push_error("JSON aset spike tidak terbaca: %s" % berkas)
			continue
		var d: Dictionary = data
		var pijak: Array = d["ground_anchor"]
		var tapak: Array = d["tapak_ubin"]
		_aset[berkas.get_basename()] = {
			"pijak": Vector2i(int(pijak[0]), int(pijak[1])),
			"tapak": Rect2(float(tapak[0]), float(tapak[1]), float(tapak[2]), float(tapak[3])),
			"tinggi": float(d["tinggi_ubin"]),
		}


func _tekstur_untuk(nama: String) -> Texture2D:
	if not _tekstur.has(nama):
		var jalur: String = "%s/%s.png" % [FOLDER_SPIKE, nama] if nama.begins_with("spike_") else SpriteRumah.jalur_png(nama)
		_tekstur[nama] = load(jalur) as Texture2D
	return _tekstur[nama]
