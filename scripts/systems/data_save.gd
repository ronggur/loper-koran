class_name DataSave
extends RefCounted
## Format save v2 dan aturannya, logika murni (DATA_SCHEMA 4, rule `save-system`; AC-7 sampai AC-12 run fase4a-koran-hari, v2 AC-7 dan AC-8 run
## fase4b-misi-kucing). v2 (M-6, M-7): `flag` kini berarti "lanjutan menunggu tampil" (dikonsumsi di akhir hari bila halaman koran hari itu menampilkan
## headline lanjutannya), BUKAN riwayat; riwayat permanen ada di `misi_hasil`. Field baru: `misi_hasil`, `tutorial`, `terakhir.misi_hasil`, `terakhir.koin_misi`.
## Satu Dictionary
## state yang dipegang `SaveManager`; semua keputusan format ada di sini supaya bisa dites tanpa berkas:
## - `templat`: state bawaan (hari awal, koin 0, tanpa flag, pengaturan bawaan);
## - `dari_teks`: teks berkas -> state. Bukan JSON, bukan Dictionary, `versi` atau field kunci bertipe salah = RUSAK, `versi` lebih baru
##   dari `SAVE_VERSI` = TERLALU_BARU (keduanya: state bawaan dan `SaveManager` menyalin berkas lama dulu, tidak menimpa diam-diam, AC-9);
##   selain itu `migrasi` (AC-10);
## - `migrasi`: langkah `if versi < N` per versi, lalu normalisasi: id yang tidak ada di data (flag, jeda) DIBIARKAN, nilai tidak sah
##   (negatif, tipe salah di dalam blok) dijepit atau diganti bawaan, tidak crash. Field baru mendapat nilai bawaan dari templat;
## - `catat_hari`: yang dicatat dari satu hari. Progres tidak pernah turun (AC-11): hari, koin, dan tip_total hanya naik, jeda tidak mundur;
##   hari dengan koin 0 tidak mengurangi apa pun (prinsip 2). Flag (v2): flag yang lanjutannya tampil hari itu DIKONSUMSI dulu, flag baru dari hasil misi
##   ditambahkan SESUDAHNYA (flag baru hari ini tidak ikut terhapus). `misi_hasil[id]`: `selesai` tidak pernah ditimpa `gagal`. Angka koin (termasuk
##   tip dan koin misi), skor, dan hasil misi datang dari `HasilRute.Angka` yang sama dengan layar hasil (AC-12), tidak dihitung ulang.
## Waktu dan RNG tidak dipakai. Field DATA_SCHEMA 4 yang belum dipakai (reputasi, pelanggan, sepeda, dst) tidak ditulis; bila ada di
## berkas (save masa depan) dibiarkan. Usulan, belum dikunci.

## Hasil membaca teks save. `TIDAK_TERBACA` tidak pernah dihasilkan `dari_teks` (yang menerima teks): `SaveManager` memakainya bila berkas ada tetapi
## tidak bisa dibuka (izin, galat I/O), supaya dibedakan dari berkas yang terbaca tetapi kosong atau rusak.
enum Status { BARU, SAH, RUSAK, TERLALU_BARU, TIDAK_TERBACA }

## Field tingkat atas dan tipenya; salah tipe = RUSAK (AC-9). `versi` diperiksa terpisah.
const _TIPE_KUNCI: Dictionary = {
	"hari": "angka",
	"koin": "angka",
	"tip_total": "angka",
	"flag": "daftar",
	"misi_jeda": "kamus",
	"headline_jeda": "kamus",
	"misi_hasil": "kamus",
	"tutorial": "kamus",
	"terakhir": "kamus",
	"pengaturan": "kamus",
}
const _PENGATURAN_BOOL: Array[String] = ["kidal", "mode_bantu"]
const _PENGATURAN_VOLUME: Array[String] = ["suara", "musik"]
const _TERAKHIR_ANGKA: Array[String] = ["hari", "terkirim", "meleset", "koin", "tip", "skor", "koin_misi"]
const _HASIL_MISI: Array[String] = ["selesai", "gagal"]


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
	## Flag baru dari hasil misi (`flag_lanjut` misi, "" tidak ditambahkan), ditambahkan SESUDAH konsumsi.
	var flag_baru: Array[String] = []
	## Flag yang lanjutannya tampil di koran hari ini (`HeadlineManager.flag_terpakai`): dihapus dari save di akhir hari (M-6).
	var flag_dikonsumsi: Array[String] = []
	## Tutorial hari ini selesai atau dilewati: `tutorial.selesai` ditulis true (hanya di akhir hari).
	var tutorial_selesai: bool = false
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
		"misi_hasil": {},
		"tutorial": {"selesai": false},
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
## tanpa menghilangkan hari, koin, flag, dan pengaturan yang sah (lalu langkah v1 -> v2). Id yang tidak dikenal data dibiarkan.
static func migrasi(data: Dictionary) -> Dictionary:
	var hasil: Dictionary = data.duplicate(true)
	var versi: int = int(hasil["versi"]) if hasil.has("versi") and _angka(hasil["versi"]) else 0
	if versi < 1:
		var dasar: Dictionary = templat()
		for kunci: String in dasar:
			if not hasil.has(kunci):
				hasil[kunci] = dasar[kunci]
		versi = 1
	if versi < 2:
		# v1 -> v2 (run fase4b-misi-kucing): field baru bawaan; `flag` v1 dibiarkan apa adanya (satu-satunya flag v1 yang mungkin ada
		# ditulis tes), `koin`, `hari`, `tip_total`, jeda, dan pengaturan dipertahankan. `terakhir` yang sah mendapat `misi_hasil` dan `koin_misi`.
		var dasar2: Dictionary = templat()
		for kunci: String in ["misi_hasil", "tutorial"]:
			if not hasil.has(kunci):
				hasil[kunci] = dasar2[kunci]
		if hasil.has("terakhir") and typeof(hasil["terakhir"]) == TYPE_DICTIONARY:
			var terakhir: Dictionary = hasil["terakhir"]
			if not terakhir.is_empty():
				if not terakhir.has("misi_hasil"):
					terakhir["misi_hasil"] = ""
				if not terakhir.has("koin_misi"):
					terakhir["koin_misi"] = 0
		versi = 2
	hasil["versi"] = versi
	return _normalisasi(hasil)


## Catat satu hari yang selesai ke salinan `state` (masukan tidak diubah). Hari, koin, dan tip_total hanya naik; jeda tidak mundur (AC-11); flag:
## konsumsi dulu, flag baru sesudahnya (M-6); `misi_hasil` dan `tutorial` (M-7); pengaturan sakelar jeda ikut disimpan (AC-13).
static func catat_hari(state: Dictionary, catatan: CatatanHari) -> Dictionary:
	var baru: Dictionary = _normalisasi(state.duplicate(true))
	var angka: HasilRute.Angka = catatan.angka if catatan.angka != null else HasilRute.Angka.new()
	baru["hari"] = clampi(maxi(int(baru["hari"]), catatan.hari + 1), Config.HARI_AWAL, Config.SAVE_ANGKA_MAKS)
	baru["koin"] = clampi(int(baru["koin"]) + maxi(angka.koin, 0), 0, Config.SAVE_ANGKA_MAKS)
	baru["tip_total"] = clampi(int(baru["tip_total"]) + maxi(angka.koin_tip, 0), 0, Config.SAVE_ANGKA_MAKS)
	var flag: Array = baru["flag"]
	for f: String in catatan.flag_dikonsumsi:
		flag.erase(f)
	for f: String in catatan.flag_baru:
		if not f.is_empty() and not flag.has(f):
			flag.append(f)
	_catat_misi_hasil(baru, angka, catatan.hari)
	if catatan.tutorial_selesai:
		var tutorial: Dictionary = baru["tutorial"]
		tutorial["selesai"] = true
	baru["misi_jeda"] = _gabung_jeda(baru["misi_jeda"], catatan.misi_jeda)
	baru["headline_jeda"] = _gabung_jeda(baru["headline_jeda"], catatan.headline_jeda)
	baru["terakhir"] = {
		"hari": catatan.hari,
		"terkirim": angka.terkirim,
		"meleset": angka.meleset,
		"koin": angka.koin,
		"tip": angka.koin_tip,
		"skor": angka.skor,
		"koin_misi": angka.koin_misi if angka.misi_hasil == "selesai" else 0,
		"misi_hasil": angka.misi_hasil if _HASIL_MISI.has(angka.misi_hasil) else "",
		"misi_diambil": catatan.misi_diambil,
	}
	var pengaturan: Dictionary = baru["pengaturan"]
	pengaturan["kidal"] = catatan.kidal
	pengaturan["mode_bantu"] = catatan.mode_bantu
	return _normalisasi(baru)


## Mencatat hasil misi hari ini di `misi_hasil[id]` = {hasil, hari} (riwayat permanen, M-7): `selesai` tidak pernah ditimpa `gagal` dan tidak
## digeser hari selesainya; `gagal` boleh diganti `selesai` atau hasil `gagal` yang lebih baru. Hasil kosong atau id kosong tidak mencatat apa pun.
static func _catat_misi_hasil(state: Dictionary, angka: HasilRute.Angka, hari: int) -> void:
	if angka.misi_id.is_empty() or not _HASIL_MISI.has(angka.misi_hasil):
		return
	var riwayat: Dictionary = state["misi_hasil"]
	var lama: Variant = riwayat.get(angka.misi_id)
	if typeof(lama) == TYPE_DICTIONARY and str((lama as Dictionary).get("hasil", "")) == "selesai":
		return
	riwayat[angka.misi_id] = {"hasil": angka.misi_hasil, "hari": clampi(hari, Config.HARI_AWAL, Config.SAVE_ANGKA_MAKS)}


## Flag di state sebagai daftar teks (state sudah ternormalisasi).
static func daftar_flag(state: Dictionary) -> Array[String]:
	var hasil: Array[String] = []
	var flag: Array = state.get("flag", [])
	for f: Variant in flag:
		if typeof(f) == TYPE_STRING:
			hasil.append(str(f))
	return hasil


## True bila tutorial sudah selesai atau dilewati (`tutorial.selesai`).
static func tutorial_selesai(state: Dictionary) -> bool:
	var tutorial: Variant = state.get("tutorial")
	if typeof(tutorial) != TYPE_DICTIONARY:
		return false
	var selesai: Variant = (tutorial as Dictionary).get("selesai")
	return typeof(selesai) == TYPE_BOOL and selesai


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
	data["misi_hasil"] = _normalisasi_misi_hasil(data["misi_hasil"])
	data["tutorial"] = _normalisasi_tutorial(data["tutorial"])
	data["terakhir"] = _normalisasi_terakhir(data["terakhir"])
	data["pengaturan"] = _normalisasi_pengaturan(data["pengaturan"])
	return data


## `misi_hasil`: id -> {hasil: selesai|gagal, hari >= 1}. Id tak dikenal data dibiarkan; entri bentuk salah dibuang (hasil tak sah tidak bisa ditebak).
static func _normalisasi_misi_hasil(riwayat: Dictionary) -> Dictionary:
	var hasil: Dictionary = {}
	for id: Variant in riwayat:
		var entri: Variant = riwayat[id]
		if typeof(id) != TYPE_STRING or typeof(entri) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entri
		if typeof(d.get("hasil")) != TYPE_STRING or not _HASIL_MISI.has(d["hasil"]):
			continue
		hasil[str(id)] = {"hasil": str(d["hasil"]), "hari": clampi(_ke_bulat(d.get("hari", Config.HARI_AWAL)), Config.HARI_AWAL, Config.SAVE_ANGKA_MAKS)}
	return hasil


static func _normalisasi_tutorial(tutorial: Dictionary) -> Dictionary:
	var selesai: Variant = tutorial.get("selesai")
	return {"selesai": typeof(selesai) == TYPE_BOOL and selesai}


static func _normalisasi_terakhir(terakhir: Dictionary) -> Dictionary:
	var hasil: Dictionary = {}
	if terakhir.is_empty():
		return hasil
	for kunci: String in _TERAKHIR_ANGKA:
		hasil[kunci] = clampi(_ke_bulat(terakhir.get(kunci, 0)), 0, Config.SAVE_ANGKA_MAKS)
	var diambil: Variant = terakhir.get("misi_diambil", "")
	hasil["misi_diambil"] = str(diambil) if typeof(diambil) == TYPE_STRING else ""
	var hasil_misi: Variant = terakhir.get("misi_hasil", "")
	hasil["misi_hasil"] = str(hasil_misi) if typeof(hasil_misi) == TYPE_STRING and _HASIL_MISI.has(hasil_misi) else ""
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
