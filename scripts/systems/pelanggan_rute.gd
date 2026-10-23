class_name PelangganRute
extends RefCounted
## Keadaan pelanggan tetap yang diberikan ke `RouteBuilder.bangun` (O-7 run fase6a2-reputasi-pelanggan, usulan): status tiap rumah dari save (`state["pelanggan"]`) dan pustaka kepribadian.
## Murni: hanya data dan pembaca, tanpa node, `Time`, atau RNG. Rumah tanpa entri berstatus `baru` (belum pernah masuk rute). Entri rusak dibaca sebagai `aktif` dengan penghitung 0,
## jadi keadaan apa pun dari save yang dinormalisasi `DataSave` aman dibaca.

const BARU: String = "baru"
const AKTIF: String = "aktif"
const SETIA: String = "setia"
const BERHENTI: String = "berhenti"

## id rumah (`<id_segmen>@<pos>`) -> {status, antar, meleset, hari_berhenti} (bentuk `state["pelanggan"]`).
var pelanggan: Dictionary = {}
## Pustaka kepribadian (urut berkas); kosong = semua pelanggan `biasa`.
var kepribadian: Array[KepribadianPelanggan.Entri] = []


## Keadaan dari state save `state` (kunci `pelanggan` hilang atau bukan kamus = kosong) dan pustaka `pustaka`. Salinan: perubahan sesudahnya tidak memengaruhi state.
static func dari_state(state: Dictionary, pustaka: Array[KepribadianPelanggan.Entri]) -> PelangganRute:
	var p: PelangganRute = PelangganRute.new()
	var sumber: Variant = state.get("pelanggan")
	if typeof(sumber) == TYPE_DICTIONARY:
		p.pelanggan = (sumber as Dictionary).duplicate(true)
	p.kepribadian = pustaka
	return p


## True bila rumah `id` punya entri.
func dikenal(id: String) -> bool:
	return pelanggan.has(id) and typeof(pelanggan[id]) == TYPE_DICTIONARY


## Status rumah `id`: `baru`, `aktif`, `setia`, atau `berhenti`.
func status(id: String) -> String:
	if not dikenal(id):
		return BARU
	var s: Variant = (pelanggan[id] as Dictionary).get("status")
	if typeof(s) == TYPE_STRING and Config.PELANGGAN_STATUS.has(s):
		return str(s)
	return AKTIF


## Hari rumah `id` berhenti (0 bila bukan `berhenti` atau tidak tercatat).
func hari_berhenti(id: String) -> int:
	if not dikenal(id) or status(id) != BERHENTI:
		return 0
	var h: Variant = (pelanggan[id] as Dictionary).get("hari_berhenti", 0)
	return int(h) if ParseData.angka(h) else 0


## Kepribadian rumah `id` (`KepribadianPelanggan.dari_id`).
func kepribadian_dari(id: String) -> String:
	return KepribadianPelanggan.dari_id(id, kepribadian)


## True bila rumah `id` berhenti dan sudah lewat `PELANGGAN_KEMBALI_JEDA_HARI` hari sampai hari `hari` ("calon kembali").
func calon_kembali(id: String, hari: int) -> bool:
	return status(id) == BERHENTI and hari - hari_berhenti(id) >= Config.PELANGGAN_KEMBALI_JEDA_HARI
