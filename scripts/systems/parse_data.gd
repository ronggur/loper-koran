class_name ParseData
extends RefCounted
## Pembantu parse data JSON bersama pemuat misi dan headline (pola yang sama dengan `SegmenRute`; run fase4a-koran-hari). Logika murni:
## tiap fungsi mencatat galat berbahasa Indonesia ke `g` dan mengembalikan nilai bawaan bila field tidak sah, supaya `parse` bisa
## mengumpulkan SEMUA pelanggaran sekaligus. Usulan.


## True bila `nilai` angka berhingga (int atau float JSON).
static func angka(nilai: Variant) -> bool:
	var tipe: int = typeof(nilai)
	if tipe == TYPE_INT:
		return true
	if tipe == TYPE_FLOAT:
		return is_finite(nilai)
	return false


## True bila `nilai` bilangan bulat (JSON menulis 5 sebagai 5.0).
static func bulat(nilai: Variant) -> bool:
	return angka(nilai) and is_equal_approx(float(nilai), roundf(float(nilai)))


## True bila `teks` huruf kecil, angka, dan garis bawah, dimulai huruf (id misi, headline, flag).
static func nama_sah(teks: String) -> bool:
	var re: RegEx = RegEx.create_from_string("^[a-z][a-z0-9_]*\\z")
	return re.search(teks) != null


## Menolak field di `data` yang tidak ada di `dikenal` (salah ketik tidak lolos diam-diam).
static func tolak_field_asing(data: Dictionary, dikenal: Array[String], label: String, g: Array[String]) -> void:
	for kunci: Variant in data.keys():
		if not dikenal.has(String(kunci)):
			g.append("%s: field '%s' tidak dikenal" % [label, kunci])


## Teks wajib tidak kosong.
static func teks_wajib(data: Dictionary, kunci: String, label: String, g: Array[String]) -> String:
	if not data.has(kunci):
		g.append("%s: field wajib '%s' tidak ada" % [label, kunci])
		return ""
	if typeof(data[kunci]) != TYPE_STRING:
		g.append("%s: '%s' harus teks" % [label, kunci])
		return ""
	var teks: String = data[kunci]
	if teks.is_empty():
		g.append("%s: '%s' tidak boleh kosong" % [label, kunci])
	return teks


## Bilangan bulat wajib.
static func bulat_wajib(data: Dictionary, kunci: String, label: String, g: Array[String]) -> int:
	if not data.has(kunci):
		g.append("%s: field wajib '%s' tidak ada" % [label, kunci])
		return 0
	if not bulat(data[kunci]):
		g.append("%s: '%s' harus bilangan bulat" % [label, kunci])
		return 0
	return int(roundf(float(data[kunci])))


## Objek (kamus) wajib.
static func kamus_wajib(data: Dictionary, kunci: String, label: String, g: Array[String]) -> Dictionary:
	if not data.has(kunci):
		g.append("%s: field wajib '%s' tidak ada" % [label, kunci])
		return {}
	if typeof(data[kunci]) != TYPE_DICTIONARY:
		g.append("%s: '%s' harus objek" % [label, kunci])
		return {}
	var nilai: Dictionary = data[kunci]
	return nilai


## Daftar wajib.
static func daftar_wajib(data: Dictionary, kunci: String, label: String, g: Array[String]) -> Array:
	if not data.has(kunci):
		g.append("%s: field wajib '%s' tidak ada" % [label, kunci])
		return []
	if typeof(data[kunci]) != TYPE_ARRAY:
		g.append("%s: '%s' harus daftar" % [label, kunci])
		return []
	var nilai: Array = data[kunci]
	return nilai


## Bool opsional dengan nilai `bawaan` bila field tidak ada.
static func bool_opsional(data: Dictionary, kunci: String, bawaan: bool, label: String, g: Array[String]) -> bool:
	if not data.has(kunci):
		return bawaan
	if typeof(data[kunci]) != TYPE_BOOL:
		g.append("%s: '%s' harus true atau false" % [label, kunci])
		return bawaan
	return data[kunci]


## Teks opsional ("" bila tidak ada); bila ada harus teks tidak kosong.
static func teks_opsional(data: Dictionary, kunci: String, label: String, g: Array[String]) -> String:
	if not data.has(kunci):
		return ""
	return teks_wajib(data, kunci, label, g)


## Memeriksa objek `syarat` (headline dan misi): kunci yang boleh `flag` (id), `hari_min` / `hari_maks` (hari >= 1), dan `berita_utama`
## (kunci efek dunia, hanya bila `izinkan_berita_utama`). Kembalinya salinan yang sudah dibersihkan tipenya.
static func syarat(data: Dictionary, label: String, izinkan_berita_utama: bool, g: Array[String]) -> Dictionary:
	var hasil: Dictionary = {}
	var kamus: Dictionary = kamus_wajib(data, "syarat", label, g)
	for kunci: Variant in kamus.keys():
		var nama: String = String(kunci)
		var nilai: Variant = kamus[kunci]
		match nama:
			"flag":
				if typeof(nilai) == TYPE_STRING and nama_sah(nilai):
					hasil[nama] = nilai
				else:
					g.append("%s: syarat.flag harus id huruf kecil dan garis bawah" % label)
			"hari_min", "hari_maks":
				if bulat(nilai) and int(roundf(float(nilai))) >= Config.HARI_AWAL:
					hasil[nama] = int(roundf(float(nilai)))
				else:
					g.append("%s: syarat.%s harus bilangan bulat >= %d" % [label, nama, Config.HARI_AWAL])
			"berita_utama":
				if not izinkan_berita_utama:
					g.append("%s: syarat.berita_utama hanya untuk misi" % label)
				elif typeof(nilai) == TYPE_STRING and Config.EFEK_DUNIA_DIKENAL.has(nilai):
					hasil[nama] = nilai
				else:
					g.append("%s: syarat.berita_utama harus salah satu dari %s" % [label, Config.EFEK_DUNIA_DIKENAL])
			_:
				g.append("%s: syarat.%s tidak dikenal (flag, hari_min, hari_maks, berita_utama)" % [label, nama])
	if hasil.has("hari_min") and hasil.has("hari_maks") and int(hasil["hari_min"]) > int(hasil["hari_maks"]):
		g.append("%s: syarat.hari_min lebih besar dari hari_maks" % label)
	return hasil
