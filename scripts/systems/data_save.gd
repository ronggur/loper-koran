class_name DataSave
extends RefCounted
## Format save v1 dan aturannya, logika murni (DATA_SCHEMA 4, rule `save-system`; AC-7 sampai AC-12 run fase4a-koran-hari). Satu Dictionary
## state yang dipegang `SaveManager`; semua keputusan format ada di sini supaya bisa dites tanpa berkas:
## - `templat`: state bawaan (hari awal, koin 0, tanpa flag, pengaturan bawaan);
## - `dari_teks`: teks berkas -> state. Bukan JSON, bukan Dictionary, `versi` atau field kunci bertipe salah = RUSAK, `versi` lebih baru
##   dari `SAVE_VERSI` = TERLALU_BARU (keduanya: state bawaan dan `SaveManager` menyalin berkas lama dulu, tidak menimpa diam-diam, AC-9);
##   selain itu `migrasi` (AC-10);
## - `migrasi`: langkah `if versi < N` per versi, lalu normalisasi: id yang tidak ada di data (flag, jeda) DIBIARKAN, nilai tidak sah
##   (negatif, tipe salah di dalam blok) dijepit atau diganti bawaan, tidak crash. Field baru mendapat nilai bawaan dari templat;
## - `catat_hari`: yang dicatat dari satu hari. Progres tidak pernah turun (AC-11): hari, koin, dan tip_total hanya naik, flag hanya
##   bertambah, jeda tidak mundur; hari dengan koin 0 tidak mengurangi apa pun (prinsip 2). Angka koin, tip, skor datang dari `HasilRute.Angka`
##   yang sama dengan layar hasil (AC-12), tidak dihitung ulang.
## Waktu dan RNG tidak dipakai. Field DATA_SCHEMA 4 yang belum dipakai (reputasi, pelanggan, sepeda, dst) tidak ditulis; bila ada di
## berkas (save masa depan) dibiarkan. Usulan, belum dikunci.

## Hasil membaca teks save.
enum Status { BARU, SAH, RUSAK, TERLALU_BARU }

## Field tingkat atas dan tipenya; salah tipe = RUSAK (AC-9). `versi` diperiksa terpisah.
const _TIPE_KUNCI: Dictionary = {
	"hari": "angka",
	"koin": "angka",
	"tip_total": "angka",
	"flag": "daftar",
	"misi_jeda": "kamus",
	"headline_jeda": "kamus",
	"terakhir": "kamus",
	"pengaturan": "kamus",
}
const _PENGATURAN_BOOL: Array[String] = ["kidal", "mode_bantu"]
const _PENGATURAN_VOLUME: Array[String] = ["suara", "musik"]
const _TERAKHIR_ANGKA: Array[String] = ["hari", "terkirim", "meleset", "koin", "tip", "skor"]


## Hasil `dari_teks`: state, status, dan alasan (teks developer) bila rusak.
class Hasil extends RefCounted:
	var state: Dictionary = {}
	var status: Status = Status.BARU
	var alasan: String = ""

	## True bila berkas lama harus disalin dulu sebelum ditimpa.
	func perlu_salinan() -> bool:
		return status == Status.RUSAK or status == Status.TERLALU_BARU


## Catatan satu hari yang selesai: masukan `catat_hari`.
class CatatanHari extends RefCounted:
	## Hari yang baru dimainkan.
	var hari: int = Config.HARI_AWAL
	## Angka layar hasil yang sama dengan yang ditampilkan.
	var angka: HasilRute.Angka = null
	## Id misi yang diambil hari itu ("" bila dilewati atau tidak ada misi).
	var misi_diambil: String = ""
	## Hari pertama headline boleh muncul lagi: id -> hari (S-4).
	var headline_jeda: Dictionary = {}
	## Hari pertama misi yang diambil boleh muncul lagi: id -> hari (S-4).
	var misi_jeda: Dictionary = {}
	## Flag baru dari hasil misi (4B; kosong di 4A).
	var flag_baru: Array[String] = []
	var kidal: bool = false
	var mode_bantu: bool = false


## State bawaan (save baru): hari pertama, tanpa koin dan flag, pengaturan bawaan.
static func templat() -> Dictionary:
	return {
		"versi": Config.SAVE_VERSI,
		"hari": Config.HARI_AWAL,
		"koin": 0,
		"tip_total": 0,
		"flag": [],
		"misi_jeda": {},
		"headline_jeda": {},
		"terakhir": {},
		"pengaturan": {
			"kidal": false,
			"mode_bantu": false,
			"suara": Config.SAVE_VOLUME_BAWAAN,
			"musik": Config.SAVE_VOLUME_BAWAAN,
		},
	}


## Teks state sebagai JSON berurut kunci (isi sama = teks sama, byte demi byte).
static func ke_teks(state: Dictionary) -> String:
	return JSON.stringify(state, "\t", true)


## State dari teks berkas. Berkas tidak ada ditangani pemanggil (`SaveManager`: status BARU, tanpa notifikasi).
static func dari_teks(teks: String) -> Hasil:
	var hasil: Hasil = Hasil.new()
	hasil.state = templat()
	if teks.strip_edges().is_empty():
		return _rusak(hasil, "berkas kosong")
	var penghurai: JSON = JSON.new()
	if penghurai.parse(teks) != OK:
		return _rusak(hasil, "bukan JSON (baris %d: %s)" % [penghurai.get_error_line(), penghurai.get_error_message()])
	if typeof(penghurai.data) != TYPE_DICTIONARY:
		return _rusak(hasil, "isi berkas bukan satu objek")
	var data: Dictionary = penghurai.data
	if data.has("versi"):
		if not _angka(data["versi"]):
			return _rusak(hasil, "versi bukan angka")
		if int(data["versi"]) > Config.SAVE_VERSI:
			hasil.status = Status.TERLALU_BARU
			hasil.alasan = "versi %d lebih baru dari yang dikenal (%d)" % [int(data["versi"]), Config.SAVE_VERSI]
			return hasil
	for kunci: String in _TIPE_KUNCI:
		if data.has(kunci) and not _tipe_cocok(data[kunci], _TIPE_KUNCI[kunci]):
			return _rusak(hasil, "field '%s' bertipe salah" % kunci)
	hasil.state = migrasi(data)
	hasil.status = Status.SAH
	return hasil


## Save versi apa pun ke versi `SAVE_VERSI`. Masukan tidak diubah. Save tanpa `versi` dianggap v0 (sebelum format ini): templat digabung
## tanpa menghilangkan hari, koin, flag, dan pengaturan yang sah. Id yang tidak dikenal data dibiarkan.
static func migrasi(data: Dictionary) -> Dictionary:
	var hasil: Dictionary = data.duplicate(true)
	var versi: int = int(hasil["versi"]) if hasil.has("versi") and _angka(hasil["versi"]) else 0
	if versi < 1:
		var dasar: Dictionary = templat()
		for kunci: String in dasar:
			if not hasil.has(kunci):
				hasil[kunci] = dasar[kunci]
		versi = 1
	hasil["versi"] = versi
	return _normalisasi(hasil)


## Catat satu hari yang selesai ke salinan `state` (masukan tidak diubah). Hari, koin, dan tip_total hanya naik; flag hanya bertambah;
## jeda tidak mundur (AC-11); pengaturan sakelar jeda ikut disimpan (AC-13).
static func catat_hari(state: Dictionary, catatan: CatatanHari) -> Dictionary:
	var baru: Dictionary = _normalisasi(state.duplicate(true))
	var angka: HasilRute.Angka = catatan.angka if catatan.angka != null else HasilRute.Angka.new()
	baru["hari"] = clampi(maxi(int(baru["hari"]), catatan.hari + 1), Config.HARI_AWAL, Config.SAVE_ANGKA_MAKS)
	baru["koin"] = clampi(int(baru["koin"]) + maxi(angka.koin, 0), 0, Config.SAVE_ANGKA_MAKS)
	baru["tip_total"] = clampi(int(baru["tip_total"]) + maxi(angka.koin_tip, 0), 0, Config.SAVE_ANGKA_MAKS)
	var flag: Array = baru["flag"]
	for f: String in catatan.flag_baru:
		if not f.is_empty() and not flag.has(f):
			flag.append(f)
	baru["misi_jeda"] = _gabung_jeda(baru["misi_jeda"], catatan.misi_jeda)
	baru["headline_jeda"] = _gabung_jeda(baru["headline_jeda"], catatan.headline_jeda)
	baru["terakhir"] = {
		"hari": catatan.hari,
		"terkirim": angka.terkirim,
		"meleset": angka.meleset,
		"koin": angka.koin,
		"tip": angka.koin_tip,
		"skor": angka.skor,
		"misi_diambil": catatan.misi_diambil,
	}
	var pengaturan: Dictionary = baru["pengaturan"]
	pengaturan["kidal"] = catatan.kidal
	pengaturan["mode_bantu"] = catatan.mode_bantu
	return _normalisasi(baru)


## Flag di state sebagai daftar teks (state sudah ternormalisasi).
static func daftar_flag(state: Dictionary) -> Array[String]:
	var hasil: Array[String] = []
	var flag: Array = state.get("flag", [])
	for f: Variant in flag:
		if typeof(f) == TYPE_STRING:
			hasil.append(str(f))
	return hasil


## Jeda di state sebagai {id: int}. `kunci` = "misi_jeda" atau "headline_jeda".
static func daftar_jeda(state: Dictionary, kunci: String) -> Dictionary:
	var hasil: Dictionary = {}
	var jeda: Dictionary = state.get(kunci, {})
	for id: Variant in jeda:
		if typeof(id) == TYPE_STRING and _angka(jeda[id]):
			hasil[str(id)] = int(jeda[id])
	return hasil


## Gabung jeda: nilai terbesar menang (jeda tidak pernah mundur).
static func _gabung_jeda(lama: Dictionary, baru: Dictionary) -> Dictionary:
	var hasil: Dictionary = lama.duplicate(true)
	for id: Variant in baru:
		if typeof(id) != TYPE_STRING or not _angka(baru[id]):
			continue
		var nilai: int = clampi(int(baru[id]), 0, Config.SAVE_ANGKA_MAKS)
		hasil[id] = maxi(int(hasil.get(id, 0)), nilai)
	return hasil


## Perbaiki nilai tidak sah di dalam struktur yang tipe tingkat atasnya benar (dijepit atau bawaan), id dibiarkan.
static func _normalisasi(data: Dictionary) -> Dictionary:
	var dasar: Dictionary = templat()
	for kunci: String in dasar:
		if not data.has(kunci) or not _tipe_cocok(data[kunci], _tipe_dari(dasar[kunci])):
			data[kunci] = dasar[kunci]
	data["hari"] = clampi(_ke_bulat(data["hari"]), Config.HARI_AWAL, Config.SAVE_ANGKA_MAKS)
	data["koin"] = clampi(_ke_bulat(data["koin"]), 0, Config.SAVE_ANGKA_MAKS)
	data["tip_total"] = clampi(_ke_bulat(data["tip_total"]), 0, Config.SAVE_ANGKA_MAKS)
	var flag: Array = []
	var daftar: Array = data["flag"]
	for f: Variant in daftar:
		if typeof(f) == TYPE_STRING and not str(f).is_empty() and not flag.has(f):
			flag.append(f)
	data["flag"] = flag
	data["misi_jeda"] = _gabung_jeda({}, data["misi_jeda"])
	data["headline_jeda"] = _gabung_jeda({}, data["headline_jeda"])
	data["terakhir"] = _normalisasi_terakhir(data["terakhir"])
	data["pengaturan"] = _normalisasi_pengaturan(data["pengaturan"])
	return data


static func _normalisasi_terakhir(terakhir: Dictionary) -> Dictionary:
	var hasil: Dictionary = {}
	if terakhir.is_empty():
		return hasil
	for kunci: String in _TERAKHIR_ANGKA:
		hasil[kunci] = clampi(_ke_bulat(terakhir.get(kunci, 0)), 0, Config.SAVE_ANGKA_MAKS)
	var diambil: Variant = terakhir.get("misi_diambil", "")
	hasil["misi_diambil"] = str(diambil) if typeof(diambil) == TYPE_STRING else ""
	return hasil


static func _normalisasi_pengaturan(pengaturan: Dictionary) -> Dictionary:
	var hasil: Dictionary = pengaturan.duplicate(true)
	for kunci: String in _PENGATURAN_BOOL:
		if typeof(hasil.get(kunci)) != TYPE_BOOL:
			hasil[kunci] = false
	for kunci: String in _PENGATURAN_VOLUME:
		var nilai: Variant = hasil.get(kunci)
		if not _angka(nilai) or not is_finite(float(nilai)):
			hasil[kunci] = Config.SAVE_VOLUME_BAWAAN
		else:
			hasil[kunci] = clampf(float(nilai), Config.SAVE_VOLUME_MIN, Config.SAVE_VOLUME_MAKS)
	return hasil


static func _rusak(hasil: Hasil, alasan: String) -> Hasil:
	hasil.status = Status.RUSAK
	hasil.alasan = alasan
	return hasil


static func _angka(nilai: Variant) -> bool:
	return typeof(nilai) == TYPE_INT or typeof(nilai) == TYPE_FLOAT


static func _tipe_cocok(nilai: Variant, jenis: String) -> bool:
	match jenis:
		"angka":
			return _angka(nilai)
		"daftar":
			return typeof(nilai) == TYPE_ARRAY
		_:
			return typeof(nilai) == TYPE_DICTIONARY


static func _tipe_dari(nilai: Variant) -> String:
	if _angka(nilai):
		return "angka"
	if typeof(nilai) == TYPE_ARRAY:
		return "daftar"
	return "kamus"


## Angka JSON (float) ke bilangan bulat dengan pengaman NaN dan tak hingga (jadi 0).
static func _ke_bulat(nilai: Variant) -> int:
	if not _angka(nilai):
		return 0
	var f: float = float(nilai)
	if not is_finite(f):
		return 0
	return int(clampf(f, -float(Config.SAVE_ANGKA_MAKS), float(Config.SAVE_ANGKA_MAKS)))
