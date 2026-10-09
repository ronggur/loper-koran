class_name TanahDaur
extends Node2D
## Ubin tanah (aspal, trotoar, rumput) jalan uji tanpa ujung (AC-11, ART_DIRECTION 2.2).
##
## Tanah sama di sepanjang jalan, jadi cukup satu blok ubin tetap yang cakupannya dihitung `JalanDaur.sel_tanah`
## (seluruh layar terbesar, sepeda di posisi mana pun pada lebar jalan) dan digeser kelipatan SATU ubin ke depan
## mengikuti sepeda. Hasil gambarnya identik dengan jalan yang benar-benar tanpa ujung. Ubin dikelompokkan per jenis
## supaya gambar tergabung per tekstur. Posisi ubin bilangan bulat (piksel tajam).

@export var tekstur_aspal: Texture2D
@export var tekstur_trotoar: Texture2D
@export var tekstur_rumput: Texture2D


func _ready() -> void:
	bangun(Config.LAYAR_LEBAR_MAKS_PX, Config.LAYAR_TINGGI_DASAR_PX)
	perbarui(0.0)


## Membuat ulang blok ubin untuk viewport selebar `lebar` dan setinggi `tinggi` piksel game.
func bangun(lebar: int, tinggi: int) -> void:
	for anak: Node in get_children():
		remove_child(anak)
		anak.free()
	var wadah: Dictionary = {}
	var tekstur: Dictionary = {
		JalanDaur.Jenis.ASPAL: tekstur_aspal,
		JalanDaur.Jenis.TROTOAR: tekstur_trotoar,
		JalanDaur.Jenis.RUMPUT: tekstur_rumput,
	}
	var nama: Dictionary = {
		JalanDaur.Jenis.ASPAL: &"Aspal",
		JalanDaur.Jenis.TROTOAR: &"Trotoar",
		JalanDaur.Jenis.RUMPUT: &"Rumput",
	}
	for jenis: int in tekstur:
		var induk: Node2D = Node2D.new()
		induk.name = nama[jenis]
		add_child(induk)
		wadah[jenis] = induk
	for pusat: Vector2 in JalanDaur.sel_tanah(lebar, tinggi):
		var jenis: int = JalanDaur.jenis_di(pusat.x)
		var ubin: Sprite2D = Sprite2D.new()
		ubin.texture = tekstur[jenis]
		ubin.position = Iso.posisi_gambar(pusat)
		var induk_jenis: Node2D = wadah[jenis]
		induk_jenis.add_child(ubin)


## Menggeser blok ke kelipatan satu ubin terdekat di belakang sepeda (`jarak_ubin` = jarak maju sepeda).
func perbarui(jarak_ubin: float) -> void:
	position = Iso.posisi_gambar(Vector2(0, -floorf(jarak_ubin)))
