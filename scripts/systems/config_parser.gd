class_name ConfigParser
extends RefCounted
## Pemeriksa format `scripts/config.gd` (rule `balancing`, BALANCING 1). Logika murni.
##
## Aturan yang dijaga, supaya alat simulasi dan validator bisa mem-parse file ini
## tanpa menjalankan GDScript:
## - hanya `class_name`, `extends`, baris kosong, komentar, dan `const`;
## - tiap `const` ditulis dalam SATU baris, mulai di kolom pertama;
## - nama huruf besar `UPPER_SNAKE_CASE`, tipe eksplisit (`:=` ditolak);
## - tipe: `int`, `float`, `bool`, `String`, `Array[int|float|bool|String]`;
## - nilai literal sesuai tipe. `float` wajib memakai titik desimal (`3.0`, bukan `3`);
## - tidak ada ekspresi (`A * 2`) dan tidak ada rujukan ke konstanta lain.
##
## Hasil `parse()` adalah Dictionary:
## - `"galat"`: Array[String], tiap isi berformat `baris N: pesan`. Kosong berarti valid.
## - `"konstanta"`: Dictionary nama -> `{"tipe": String, "nilai": Variant, "baris": int}`.

const TIPE_DASAR: Array[String] = ["int", "float", "bool", "String"]
const AWALAN_TIPE_ARRAY: String = "Array["


## Mem-parse seluruh isi file `config.gd` (teks), mengembalikan Dictionary hasil (lihat atas).
static func parse(teks: String) -> Dictionary:
	var galat: Array[String] = []
	var konstanta: Dictionary = {}
	var daftar_baris: PackedStringArray = teks.replace("\r", "").split("\n")
	for i: int in range(daftar_baris.size()):
		var nomor: int = i + 1
		var baris: String = daftar_baris[i]
		var hasil: Dictionary = _parse_baris(baris)
		if hasil.has("galat"):
			galat.append("baris %d: %s" % [nomor, hasil["galat"]])
			continue
		if not hasil.has("nama"):
			continue
		var nama: String = hasil["nama"]
		if konstanta.has(nama):
			galat.append("baris %d: konstanta %s ditulis dua kali" % [nomor, nama])
			continue
		konstanta[nama] = {"tipe": hasil["tipe"], "nilai": hasil["nilai"], "baris": nomor}
	return {"galat": galat, "konstanta": konstanta}


## True bila hasil `parse()` tidak memuat galat.
static func valid(hasil: Dictionary) -> bool:
	var galat: Array = hasil["galat"]
	return galat.is_empty()


## Mem-parse satu baris. Mengembalikan `{}` untuk baris yang boleh dilewati,
## `{"galat": pesan}` untuk baris yang melanggar, atau `{"nama", "tipe", "nilai"}` untuk const.
static func _parse_baris(baris: String) -> Dictionary:
	if baris.strip_edges().is_empty():
		return {}
	if baris.begins_with("#"):
		return {}
	if baris.begins_with(" ") or baris.begins_with("\t"):
		return {"galat": "baris berindentasi tidak boleh ada (const multi-baris atau kode lain)"}
	if baris.begins_with("class_name ") or baris.begins_with("extends "):
		return {}
	if not baris.begins_with("const "):
		return {"galat": "hanya const yang boleh ada di config.gd: '%s'" % baris}
	return _parse_const(baris.substr("const ".length()))


static func _parse_const(sisa: String) -> Dictionary:
	var idx_sama: int = sisa.find("=")
	if idx_sama < 0:
		return {"galat": "const tanpa nilai di baris yang sama (multi-baris tidak boleh)"}
	var bagian_nama: String = sisa.substr(0, idx_sama).strip_edges()
	var bagian_nilai: String = _buang_komentar(sisa.substr(idx_sama + 1)).strip_edges()
	var nama: String = bagian_nama
	var tipe: String = ""
	var idx_titik_dua: int = bagian_nama.find(":")
	if idx_titik_dua >= 0:
		nama = bagian_nama.substr(0, idx_titik_dua).strip_edges()
		tipe = bagian_nama.substr(idx_titik_dua + 1).strip_edges()
	if not _nama_valid(nama):
		return {"galat": "nama '%s' harus UPPER_SNAKE_CASE (huruf besar, angka, garis bawah)" % nama}
	if tipe.is_empty():
		return {"galat": "%s: tipe eksplisit wajib (const NAMA: Tipe = nilai, bukan := atau tanpa tipe)" % nama}
	if not _tipe_valid(tipe):
		return {"galat": "%s: tipe '%s' tidak didukung" % [nama, tipe]}
	var hasil: Dictionary = _parse_nilai(bagian_nilai, tipe)
	if hasil.has("galat"):
		return {"galat": "%s: %s" % [nama, hasil["galat"]]}
	return {"nama": nama, "tipe": tipe, "nilai": hasil["nilai"]}


static func _nama_valid(nama: String) -> bool:
	var re: RegEx = RegEx.create_from_string("^[A-Z][A-Z0-9_]*$")
	return re.search(nama) != null


static func _tipe_valid(tipe: String) -> bool:
	if TIPE_DASAR.has(tipe):
		return true
	if tipe.begins_with(AWALAN_TIPE_ARRAY) and tipe.ends_with("]"):
		return TIPE_DASAR.has(_tipe_elemen(tipe))
	return false


## Untuk `Array[int]` mengembalikan `int`.
static func _tipe_elemen(tipe_array: String) -> String:
	return tipe_array.substr(AWALAN_TIPE_ARRAY.length(), tipe_array.length() - AWALAN_TIPE_ARRAY.length() - 1)


## Membuang komentar `#` di ujung baris, mengabaikan `#` di dalam teks berkutip.
static func _buang_komentar(teks: String) -> String:
	var dalam_teks: bool = false
	for i: int in range(teks.length()):
		var c: String = teks[i]
		if c == "\"":
			dalam_teks = not dalam_teks
		elif c == "#" and not dalam_teks:
			return teks.substr(0, i)
	return teks


static func _parse_nilai(teks: String, tipe: String) -> Dictionary:
	if teks.is_empty():
		return {"galat": "nilai kosong"}
	if tipe.begins_with(AWALAN_TIPE_ARRAY):
		return _parse_array(teks, _tipe_elemen(tipe))
	return _parse_skalar(teks, tipe)


static func _parse_skalar(teks: String, tipe: String) -> Dictionary:
	match tipe:
		"int":
			if RegEx.create_from_string("^-?[0-9]+$").search(teks) != null:
				return {"nilai": teks.to_int()}
			return {"galat": "'%s' bukan literal int" % teks + _petunjuk(teks)}
		"float":
			if RegEx.create_from_string("^-?[0-9]+\\.[0-9]+([eE][-+]?[0-9]+)?$").search(teks) != null:
				return {"nilai": teks.to_float()}
			return {"galat": "'%s' bukan literal float (wajib titik desimal, mis. 3.0)" % teks + _petunjuk(teks)}
		"bool":
			if teks == "true":
				return {"nilai": true}
			if teks == "false":
				return {"nilai": false}
			return {"galat": "'%s' bukan literal bool" % teks + _petunjuk(teks)}
		"String":
			if RegEx.create_from_string("^\"[^\"\\\\]*\"$").search(teks) != null:
				return {"nilai": teks.substr(1, teks.length() - 2)}
			return {"galat": "'%s' bukan literal String ber-kutip ganda" % teks + _petunjuk(teks)}
	return {"galat": "tipe '%s' tidak didukung" % tipe}


## Pesan tambahan bila nilai tampak seperti ekspresi atau rujukan konstanta lain.
static func _petunjuk(teks: String) -> String:
	if RegEx.create_from_string("[A-Za-z_]").search(teks) != null and not teks.begins_with("\""):
		return " (ekspresi atau rujukan ke konstanta lain tidak boleh)"
	if RegEx.create_from_string("[-+*/%()]").search(teks.trim_prefix("-")) != null and not teks.begins_with("\""):
		return " (ekspresi tidak boleh)"
	return ""


static func _parse_array(teks: String, tipe_elemen: String) -> Dictionary:
	if not teks.begins_with("[") or not teks.ends_with("]"):
		return {"galat": "array harus diawali [ dan ditutup ] di baris yang sama"}
	var isi: String = teks.substr(1, teks.length() - 2).strip_edges()
	var hasil_array: Array = []
	if isi.is_empty():
		return {"nilai": hasil_array}
	for bagian: String in _pisah_koma(isi):
		var elemen: Dictionary = _parse_skalar(bagian.strip_edges(), tipe_elemen)
		if elemen.has("galat"):
			return {"galat": "elemen array: %s" % elemen["galat"]}
		hasil_array.append(elemen["nilai"])
	return {"nilai": hasil_array}


## Memecah teks pada koma yang berada di luar teks berkutip.
static func _pisah_koma(teks: String) -> PackedStringArray:
	var hasil: PackedStringArray = PackedStringArray()
	var dalam_teks: bool = false
	var mulai: int = 0
	for i: int in range(teks.length()):
		var c: String = teks[i]
		if c == "\"":
			dalam_teks = not dalam_teks
		elif c == "," and not dalam_teks:
			hasil.append(teks.substr(mulai, i - mulai))
			mulai = i + 1
	hasil.append(teks.substr(mulai))
	return hasil
