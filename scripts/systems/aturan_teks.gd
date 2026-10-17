class_name AturanTeks
extends RefCounted
## Aturan teks pemain dari data (CONTENT_GUIDE 2 dan 3, rule `content-data`; AC-1, AC-2 run fase4a-koran-hari, S-2). Data menyimpan KUNCI
## terjemahan; batas panjang dan gaya diperiksa terhadap teks hasil terjemahan. Logika murni: penerjemah disuntik (`Callable` kunci -> teks),
## bawaannya `TranslationServer`, supaya aturan bisa dites dengan teks sintetis. Usulan.


## Teks terjemahan `kunci` dari `TranslationServer`; kunci yang tidak ada dikembalikan apa adanya.
static func terjemah(kunci: String) -> String:
	return String(TranslationServer.translate(StringName(kunci)))


## Teks `kunci` lewat `penerjemah` (Callable tidak sah = `terjemah`).
static func terjemah_dengan(penerjemah: Callable, kunci: String) -> String:
	if penerjemah.is_valid():
		return String(penerjemah.call(kunci))
	return terjemah(kunci)


## True bila `kunci` punya terjemahan (bukan dikembalikan apa adanya, dan tidak kosong).
static func kunci_ada(penerjemah: Callable, kunci: String) -> bool:
	var teks: String = terjemah_dengan(penerjemah, kunci)
	return not teks.is_empty() and teks != kunci


## Memeriksa kunci teks `kunci` (nilai field `nama` di `label`): harus ada terjemahannya dan panjangnya paling banyak `maks` karakter.
## Mengembalikan teks terjemahan ("" bila kunci tidak ada).
static func periksa_kunci(kunci: String, maks: int, nama: String, label: String, penerjemah: Callable, g: Array[String]) -> String:
	if kunci.is_empty():
		return ""
	if not kunci_ada(penerjemah, kunci):
		g.append("%s: kunci terjemahan '%s' (%s) tidak ada" % [label, kunci, nama])
		return ""
	var teks: String = terjemah_dengan(penerjemah, kunci)
	if teks.length() > maks:
		g.append("%s: %s '%s' (%d karakter) lebih panjang dari %d" % [label, nama, teks, teks.length(), maks])
	return teks


## Gaya headline (CONTENT_GUIDE 2) pada teks hasil terjemahan: Huruf Kapital di Awal Kata (kata penghubung boleh huruf kecil, kata
## pertama tidak), tanpa titik di akhir, tanpa tanda seru beruntun, tanpa spasi ganda.
static func periksa_gaya_headline(teks: String, label: String, g: Array[String]) -> void:
	if teks.is_empty():
		return
	if teks.ends_with("."):
		g.append("%s: headline '%s' berakhir dengan titik" % [label, teks])
	if teks.contains(Config.HEADLINE_TANDA_SERU_BERUNTUN):
		g.append("%s: headline '%s' memuat tanda seru beruntun" % [label, teks])
	if teks != teks.strip_edges() or teks.contains("  "):
		g.append("%s: headline '%s' memuat spasi berlebih" % [label, teks])
	var kata: PackedStringArray = teks.split(" ", false)
	for i: int in range(kata.size()):
		if not _awal_kata_sah(kata[i], i == 0):
			g.append("%s: kata '%s' di headline '%s' tidak diawali huruf kapital" % [label, kata[i], teks])


## Panjang dan gaya headline sekaligus (batas `HEADLINE_PANJANG_MAKS`).
static func periksa_headline(kunci: String, nama: String, label: String, penerjemah: Callable, g: Array[String]) -> void:
	var teks: String = periksa_kunci(kunci, Config.HEADLINE_PANJANG_MAKS, nama, label, penerjemah, g)
	periksa_gaya_headline(teks, label, g)


static func _awal_kata_sah(kata: String, pertama: bool) -> bool:
	if kata.is_empty():
		return false
	var awal: String = kata.substr(0, 1)
	if awal.to_upper() == awal.to_lower():
		return awal.is_valid_int()
	if awal != awal.to_upper():
		return not pertama and Config.HEADLINE_KATA_PENGHUBUNG.has(kata)
	return true
