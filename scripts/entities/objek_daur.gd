class_name ObjekDaur
extends Node2D
## Rumah dan kotak surat graybox berulang di sisi seberang jalan uji, sebagai penanda gerak (AC-11).
##
## Node ini adalah induk Y-sort: rumah, kotak surat, dan sepeda semua anak langsungnya, jadi urutan gambar
## ditentukan posisi tegak titik pijak. Sejumlah slot tetap didaur oleh `JalanDaur`: objek yang sudah
## terlewat pindah ke depan. Letak dan jarak antar objek dari `Config.JALAN_UJI_*`; titik pijak sprite diatur
## di scene rumah dan kotak surat (sama dengan graybox lama). Posisi dibulatkan ke piksel.

@export var adegan_rumah: PackedScene
@export var adegan_kotak_surat: PackedScene

var _rumah: Array[Node2D] = []
var _kotak_surat: Array[Node2D] = []


func _ready() -> void:
	var jumlah: int = JalanDaur.jumlah_slot(Config.JALAN_UJI_DAUR_MUNDUR_UBIN, Config.JALAN_UJI_DAUR_MAJU_UBIN, Config.JALAN_UJI_RUMAH_PERIODE_UBIN)
	for slot: int in range(jumlah):
		_rumah.append(_buat(adegan_rumah, "Rumah%d" % slot))
		_kotak_surat.append(_buat(adegan_kotak_surat, "KotakSurat%d" % slot))
	perbarui(0.0)


## Jumlah slot rumah (sama dengan kotak surat).
func jumlah_slot() -> int:
	return _rumah.size()


## Menempatkan ulang semua slot untuk sepeda yang sudah menempuh `jarak_ubin` sepanjang jalan.
func perbarui(jarak_ubin: float) -> void:
	var periode: int = Config.JALAN_UJI_RUMAH_PERIODE_UBIN
	var pertama: int = JalanDaur.indeks_pertama(jarak_ubin, periode, Config.JALAN_UJI_DAUR_MUNDUR_UBIN)
	for slot: int in range(_rumah.size()):
		var indeks: int = JalanDaur.indeks_slot(pertama, slot, _rumah.size())
		var maju_rumah: float = JalanDaur.maju_objek_ubin(indeks, periode, Config.JALAN_UJI_RUMAH_MAJU_UBIN)
		_rumah[slot].position = Iso.posisi_gambar(Vector2(Config.JALAN_UJI_RUMAH_X_UBIN, -maju_rumah))
		var maju_kotak: float = JalanDaur.maju_objek_ubin(indeks, periode, Config.JALAN_UJI_KOTAK_SURAT_MAJU_UBIN)
		_kotak_surat[slot].position = Iso.posisi_gambar(Vector2(Config.JALAN_UJI_KOTAK_SURAT_X_UBIN, -maju_kotak))


func _buat(adegan: PackedScene, nama: String) -> Node2D:
	var objek: Node2D = adegan.instantiate() as Node2D
	objek.name = nama
	add_child(objek)
	return objek
