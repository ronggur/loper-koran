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
## `tekstur_rumput_luar`, tanpa tepi kerb yang akan berulang jadi pita). Tanpa varian acak per ubin. Jumlah sprite ubin sama di kedua mode.

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

const NAMA_RUMPUT_LUAR: StringName = &"RumputLuar"


func _ready() -> void:
	bangun(Config.LAYAR_LEBAR_MAKS_PX, Config.LAYAR_TINGGI_DASAR_PX)
	perbarui(0.0)


## Benar bila keenam tekstur kolom terisi (mode enam kolom).
func mode_enam_kolom() -> bool:
	return (
		tekstur_kolom_rumput_seberang != null and tekstur_kolom_trotoar_seberang != null and tekstur_kolom_aspal_seberang != null
		and tekstur_kolom_aspal_dekat != null and tekstur_kolom_trotoar_dekat != null and tekstur_kolom_rumput_dekat != null
	)


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
	if enam:
		for kolom: int in JalanDaur.Kolom.values():
			nama_wadah.append(nama_wadah_kolom(kolom as JalanDaur.Kolom))
		if tekstur_rumput_luar != null:
			nama_wadah.append(NAMA_RUMPUT_LUAR)
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


## Menggeser blok ke kelipatan satu ubin terdekat di belakang sepeda (`jarak_ubin` = jarak maju sepeda).
func perbarui(jarak_ubin: float) -> void:
	position = Iso.posisi_gambar(Vector2(0, -floorf(jarak_ubin)))
