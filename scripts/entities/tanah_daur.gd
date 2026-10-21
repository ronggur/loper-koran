class_name TanahDaur
extends Node2D
## Ubin tanah (aspal, trotoar, rumput) jalan uji dan rute tanpa ujung (AC-11, ART_DIRECTION 2.2).
##
## Tanah sama di sepanjang jalan, jadi cukup satu blok ubin tetap yang cakupannya dihitung `JalanDaur.sel_tanah`
## (seluruh layar terbesar, sepeda di posisi mana pun pada lebar jalan) dan digeser kelipatan SATU ubin ke depan
## mengikuti sepeda. Hasil gambarnya identik dengan jalan yang benar-benar tanpa ujung. Ubin dikelompokkan per tekstur
## supaya gambar tergabung per tekstur. Posisi ubin bilangan bulat (piksel tajam).
##
## Dua mode tekstur. (1) Tiga tekstur graybox (`tekstur_aspal`, `tekstur_trotoar`, `tekstur_rumput`): jalan uji dan spike (scene dev), wadah
## `Aspal`, `Trotoar`, `Rumput`. (2) Enam tekstur kolom (run fase5a, D-2): dipakai bila keenam `tekstur_kolom_*` terisi (scene rute), satu
## wadah per kolom (`JalanDaur.kolom_di`) dan `RumputLuar` untuk kolom rumput di luar kolom pertama (`JalanDaur.rumput_luar`, ubin polos
## `tekstur_rumput_luar`, tanpa tepi kerb yang akan berulang jadi pita). Jumlah sprite ubin sama di kedua mode.
##
## Run fase5b-tembok-dekor bagian C (D-7, AC-14/AC-15, hanya tampilan): bila keenam tekstur khusus terisi (mode khusus, scene rute) `UbinKhusus` menukar tekstur sel kolom TROTOAR
## dan rumput (jalan masuk garasi di bawah mobil seberang, simbol sepeda tiap 12 baris, variasi rumput luar) menurut baris MUTLAK dari awal rute. Sel, posisi, dan jumlah sprite tidak berubah;
## tiap tekstur baru punya wadah sendiri supaya gambar tetap tergabung per tekstur (satu wadah satu tekstur), jadi sprite yang berganti tekstur pindah wadah. Blok digeser kelipatan
## satu ubin, jadi penerapan diulang hanya saat lantai jarak maju berubah (atau saat baris jalan masuk diatur). Tanpa tekstur khusus (jalan uji, graybox, tes lama) perilaku tidak berubah.

@export var tekstur_aspal: Texture2D
@export var tekstur_trotoar: Texture2D
@export var tekstur_rumput: Texture2D
@export var tekstur_kolom_rumput_seberang: Texture2D
@export var tekstur_kolom_trotoar_seberang: Texture2D
@export var tekstur_kolom_aspal_seberang: Texture2D
@export var tekstur_kolom_aspal_dekat: Texture2D
@export var tekstur_kolom_trotoar_dekat: Texture2D
@export var tekstur_kolom_rumput_dekat: Texture2D
## Ubin rumput polos untuk kolom rumput di luar kolom pertama (mode enam kolom). Kosong = pakai tekstur kolom rumput sisi itu.
@export var tekstur_rumput_luar: Texture2D
## Tekstur khusus (run fase5b bagian C, D-1): variasi rumput polos luar, jalan masuk garasi (trotoar dan rumput pertama, sisi seberang), simbol sepeda (kedua trotoar). Semua kosong = tanpa ubin khusus.
@export var tekstur_rumput_luar_2: Texture2D
@export var tekstur_rumput_luar_3: Texture2D
@export var tekstur_masuk_trotoar_seberang: Texture2D
@export var tekstur_masuk_rumput_seberang: Texture2D
@export var tekstur_simbol_trotoar_seberang: Texture2D
@export var tekstur_simbol_trotoar_dekat: Texture2D

const NAMA_RUMPUT_LUAR: StringName = &"RumputLuar"
const NAMA_RUMPUT_LUAR_2: StringName = &"RumputLuar2"
const NAMA_RUMPUT_LUAR_3: StringName = &"RumputLuar3"
const NAMA_MASUK_TROTOAR_SEBERANG: StringName = &"MasukTrotoarSeberang"
const NAMA_MASUK_RUMPUT_SEBERANG: StringName = &"MasukRumputSeberang"
const NAMA_SIMBOL_TROTOAR_SEBERANG: StringName = &"SimbolTrotoarSeberang"
const NAMA_SIMBOL_TROTOAR_DEKAT: StringName = &"SimbolTrotoarDekat"

## Sprite yang bisa berganti tekstur (mode khusus: kolom trotoar, rumput seberang, rumput luar) dengan data sejajar: pusat melintang (ubin), baris relatif blok, nama wadah bawaan, tekstur bawaan.
var _dinamis: Array[Sprite2D] = []
var _dinamis_x: PackedFloat32Array = PackedFloat32Array()
var _dinamis_baris: PackedInt32Array = PackedInt32Array()
var _dinamis_wadah: Array[StringName] = []
var _dinamis_tekstur: Array[Texture2D] = []
## Wadah per nama dan tekstur tiap wadah khusus (mode khusus).
var _wadah: Dictionary = {}
var _tekstur_khusus: Dictionary = {}
## Himpunan baris jalan masuk garasi (baris mutlak -> true) dari rute; kosong = tanpa jalan masuk.
var _baris_masuk: Dictionary = {}
## Lantai jarak maju sepeda terakhir (`perbarui`), lantai yang sudah diterapkan ke tekstur, dan apakah sudah pernah diterapkan.
var _blok: int = 0
var _blok_terapan: int = 0
var _terapan: bool = false


func _ready() -> void:
	bangun(Config.LAYAR_LEBAR_MAKS_PX, Config.LAYAR_TINGGI_DASAR_PX)
	perbarui(0.0)


## Benar bila keenam tekstur kolom terisi (mode enam kolom).
func mode_enam_kolom() -> bool:
	return (
		tekstur_kolom_rumput_seberang != null and tekstur_kolom_trotoar_seberang != null and tekstur_kolom_aspal_seberang != null
		and tekstur_kolom_aspal_dekat != null and tekstur_kolom_trotoar_dekat != null and tekstur_kolom_rumput_dekat != null
	)


## Benar bila mode enam kolom dan keenam tekstur khusus terisi (run fase5b bagian C): ubin khusus aktif.
func mode_khusus() -> bool:
	return (
		mode_enam_kolom() and tekstur_rumput_luar != null and tekstur_rumput_luar_2 != null and tekstur_rumput_luar_3 != null
		and tekstur_masuk_trotoar_seberang != null and tekstur_masuk_rumput_seberang != null
		and tekstur_simbol_trotoar_seberang != null and tekstur_simbol_trotoar_dekat != null
	)


## Mengatur baris jalan masuk garasi (baris mutlak, himpunan `UbinKhusus.himpunan_baris_masuk`): dipakai scene rute tiap rute disusun. Tekstur diterapkan ulang.
func atur_baris_masuk(baris: Dictionary) -> void:
	_baris_masuk = baris
	_terapan = false
	_terapkan_khusus()


## Nama wadah (simpul induk ubin) per kolom, mode enam kolom.
static func nama_wadah_kolom(kolom: JalanDaur.Kolom) -> StringName:
	match kolom:
		JalanDaur.Kolom.RUMPUT_SEBERANG:
			return &"RumputSeberang"
		JalanDaur.Kolom.TROTOAR_SEBERANG:
			return &"TrotoarSeberang"
		JalanDaur.Kolom.ASPAL_SEBERANG:
			return &"AspalSeberang"
		JalanDaur.Kolom.ASPAL_DEKAT:
			return &"AspalDekat"
		JalanDaur.Kolom.TROTOAR_DEKAT:
			return &"TrotoarDekat"
	return &"RumputDekat"


## Tekstur ubin di posisi melintang `x` pada mode enam kolom: tekstur kolom, atau ubin polos untuk kolom rumput di luar kolom pertama.
func tekstur_di(x: float) -> Texture2D:
	var kolom: JalanDaur.Kolom = JalanDaur.kolom_di(x)
	if tekstur_rumput_luar != null and JalanDaur.rumput_luar(x):
		return tekstur_rumput_luar
	match kolom:
		JalanDaur.Kolom.RUMPUT_SEBERANG:
			return tekstur_kolom_rumput_seberang
		JalanDaur.Kolom.TROTOAR_SEBERANG:
			return tekstur_kolom_trotoar_seberang
		JalanDaur.Kolom.ASPAL_SEBERANG:
			return tekstur_kolom_aspal_seberang
		JalanDaur.Kolom.ASPAL_DEKAT:
			return tekstur_kolom_aspal_dekat
		JalanDaur.Kolom.TROTOAR_DEKAT:
			return tekstur_kolom_trotoar_dekat
	return tekstur_kolom_rumput_dekat


## Membuat ulang blok ubin untuk viewport selebar `lebar` dan setinggi `tinggi` piksel game.
func bangun(lebar: int, tinggi: int) -> void:
	for anak: Node in get_children():
		remove_child(anak)
		anak.free()
	var enam: bool = mode_enam_kolom()
	var wadah: Dictionary = {}
	var tekstur_jenis: Dictionary = {
		JalanDaur.Jenis.ASPAL: tekstur_aspal,
		JalanDaur.Jenis.TROTOAR: tekstur_trotoar,
		JalanDaur.Jenis.RUMPUT: tekstur_rumput,
	}
	var nama_jenis: Dictionary = {
		JalanDaur.Jenis.ASPAL: &"Aspal",
		JalanDaur.Jenis.TROTOAR: &"Trotoar",
		JalanDaur.Jenis.RUMPUT: &"Rumput",
	}
	var nama_wadah: Array[StringName] = []
	var khusus: bool = mode_khusus()
	_dinamis = []
	_dinamis_x = PackedFloat32Array()
	_dinamis_baris = PackedInt32Array()
	_dinamis_wadah = []
	_dinamis_tekstur = []
	_wadah = {}
	_terapan = false
	if enam:
		for kolom: int in JalanDaur.Kolom.values():
			nama_wadah.append(nama_wadah_kolom(kolom as JalanDaur.Kolom))
		if tekstur_rumput_luar != null:
			nama_wadah.append(NAMA_RUMPUT_LUAR)
		if khusus:
			nama_wadah.append_array([
				NAMA_RUMPUT_LUAR_2, NAMA_RUMPUT_LUAR_3, NAMA_MASUK_TROTOAR_SEBERANG, NAMA_MASUK_RUMPUT_SEBERANG,
				NAMA_SIMBOL_TROTOAR_SEBERANG, NAMA_SIMBOL_TROTOAR_DEKAT,
			])
	else:
		for jenis: int in nama_jenis:
			nama_wadah.append(nama_jenis[jenis])
	for nama: StringName in nama_wadah:
		var induk: Node2D = Node2D.new()
		induk.name = nama
		add_child(induk)
		wadah[nama] = induk
	for pusat: Vector2 in JalanDaur.sel_tanah(lebar, tinggi):
		var tekstur: Texture2D
		var nama: StringName
		if enam:
			tekstur = tekstur_di(pusat.x)
			nama = NAMA_RUMPUT_LUAR if (tekstur_rumput_luar != null and JalanDaur.rumput_luar(pusat.x)) else nama_wadah_kolom(JalanDaur.kolom_di(pusat.x))
		else:
			var jenis: int = JalanDaur.jenis_di(pusat.x)
			tekstur = tekstur_jenis[jenis]
			nama = nama_jenis[jenis]
		var ubin: Sprite2D = Sprite2D.new()
		ubin.texture = tekstur
		ubin.position = Iso.posisi_gambar(pusat)
		var induk_ubin: Node2D = wadah[nama]
		induk_ubin.add_child(ubin)
		if khusus and _bisa_berganti(pusat.x):
			_dinamis.append(ubin)
			_dinamis_x.append(pusat.x)
			_dinamis_baris.append(int(-pusat.y))
			_dinamis_wadah.append(nama)
			_dinamis_tekstur.append(tekstur)
	if khusus:
		_wadah = wadah
		_tekstur_khusus = {
			NAMA_RUMPUT_LUAR_2: tekstur_rumput_luar_2, NAMA_RUMPUT_LUAR_3: tekstur_rumput_luar_3,
			NAMA_MASUK_TROTOAR_SEBERANG: tekstur_masuk_trotoar_seberang, NAMA_MASUK_RUMPUT_SEBERANG: tekstur_masuk_rumput_seberang,
			NAMA_SIMBOL_TROTOAR_SEBERANG: tekstur_simbol_trotoar_seberang, NAMA_SIMBOL_TROTOAR_DEKAT: tekstur_simbol_trotoar_dekat,
		}
		_terapkan_khusus()


## Benar bila sel berpusat melintang `x` bisa berganti tekstur: kolom trotoar kedua sisi, kolom rumput pertama seberang (jalan masuk), dan kolom rumput luar (variasi).
func _bisa_berganti(x: float) -> bool:
	match JalanDaur.kolom_di(x):
		JalanDaur.Kolom.TROTOAR_SEBERANG, JalanDaur.Kolom.TROTOAR_DEKAT, JalanDaur.Kolom.RUMPUT_SEBERANG:
			return true
	return JalanDaur.rumput_luar(x)


## Nama wadah tujuan untuk ubin khusus `jenis` di kolom sel `x`; `dasar` = wadah bawaan sel itu.
func _wadah_tujuan(jenis: UbinKhusus.Ubin, x: float, dasar: StringName) -> StringName:
	match jenis:
		UbinKhusus.Ubin.MASUK:
			return NAMA_MASUK_TROTOAR_SEBERANG if JalanDaur.kolom_di(x) == JalanDaur.Kolom.TROTOAR_SEBERANG else NAMA_MASUK_RUMPUT_SEBERANG
		UbinKhusus.Ubin.SIMBOL:
			return NAMA_SIMBOL_TROTOAR_SEBERANG if JalanDaur.kolom_di(x) == JalanDaur.Kolom.TROTOAR_SEBERANG else NAMA_SIMBOL_TROTOAR_DEKAT
		UbinKhusus.Ubin.RUMPUT_2:
			return NAMA_RUMPUT_LUAR_2
		UbinKhusus.Ubin.RUMPUT_3:
			return NAMA_RUMPUT_LUAR_3
	return dasar


## Menerapkan ubin khusus pada lantai jarak maju sekarang (`_blok`) bila belum: tiap sprite yang bisa berganti memakai tekstur dan wadah menurut `UbinKhusus.jenis` untuk baris mutlaknya.
## Sprite pindah wadah hanya bila wadah tujuannya beda dari wadah sekarang. Tanpa mode khusus tidak berbuat apa-apa.
func _terapkan_khusus() -> void:
	if _dinamis.is_empty() or (_terapan and _blok == _blok_terapan):
		return
	_terapan = true
	_blok_terapan = _blok
	for i: int in range(_dinamis.size()):
		var ubin: Sprite2D = _dinamis[i]
		var jenis: UbinKhusus.Ubin = UbinKhusus.jenis(_dinamis_x[i], _dinamis_baris[i] + _blok, _baris_masuk)
		var nama: StringName = _wadah_tujuan(jenis, _dinamis_x[i], _dinamis_wadah[i])
		var tujuan: Node = _wadah[nama]
		if ubin.get_parent() != tujuan:
			ubin.get_parent().remove_child(ubin)
			tujuan.add_child(ubin)
		var tekstur: Texture2D = _dinamis_tekstur[i] if nama == _dinamis_wadah[i] else (_tekstur_khusus[nama] as Texture2D)
		if ubin.texture != tekstur:
			ubin.texture = tekstur


## Menggeser blok ke kelipatan satu ubin terdekat di belakang sepeda (`jarak_ubin` = jarak maju sepeda).
func perbarui(jarak_ubin: float) -> void:
	position = Iso.posisi_gambar(Vector2(0, -floorf(jarak_ubin)))
	_blok = int(floorf(jarak_ubin))
	_terapkan_khusus()
