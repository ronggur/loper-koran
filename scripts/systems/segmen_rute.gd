class_name SegmenRute
extends RefCounted
## Satu segmen rute (DATA_SCHEMA 3, ROUTE_DESIGN 1 dan 4) sebagai data bertipe, beserta validasinya. Logika murni: `parse` menerima
## `Dictionary` (hasil JSON), mengembalikan segmen dan daftar galat, dan MENOLAK data tidak sah (segmen null bila ada galat). Membaca
## berkas ada di `PemuatRute`; UI dan entitas tidak membaca JSON langsung (rule `gdscript`). Usulan run fase3a-rute, belum dikunci.
##
## Aturan yang diperiksa (AC-1 sampai AC-3 run fase3a-rute):
## - field wajib ada dan bertipe benar, field tidak dikenal ditolak (salah ketik tidak lolos diam-diam);
## - `id` huruf kecil dan garis bawah; sisi hanya `seberang` atau `dekat` (jalur boleh juga `tengah`), tingkat dan posisi dari daftar;
## - `panjang` bilangan bulat 24 sampai 40 ubin; `pos` bilangan bulat dan tidak di tepi (`RUTE_TEPI_UBIN` dari tiap ujung);
## - segmen `pembuka` dan `penutup` bertingkat `tenang`;
## - rumah: jenis dikenal untuk sisinya, satu rumah per `pos` (id rumah `<id_segmen>@<pos>` unik tanpa sisi), dua rumah sesisi
##   berjarak paling sedikit satu petak (`RUTE_PETAK_UBIN`), pelanggan hanya di sisi `seberang` untuk distrik satu sisi (GDD 9.1);
## - rintangan (aturan adil ROUTE_DESIGN 4): bukan di jalur `tengah` (jalur utama bersih), paling dekat `RUTE_RINTANGAN_TEPI_UBIN` dari
##   tepi, tanda paling sedikit `RUTE_TANDA_MIN_UBIN`, dan dalam jendela `RUTE_RINTANGAN_JENDELA_UBIN` ubin maksimal satu;
## - rintangan tidak memotong tapak rumah mana pun di segmen (`rintangan_memotong_rumah`, ROUTE_DESIGN 4 aturan 7): mobil garasi di
##   celah samping rumah sepanjang seluruh lintasannya (parkir sampai berhenti), anjing penjaga di posisi diamnya; tepi yang hanya
##   bersentuhan boleh (`Tabrakan.bertumpuk`). Rumah segmen tetangga tidak terjangkau karena rintangan paling dekat 3 ubin ke tepi;
## - titik misi berdiri di rumah (pos dan sisi sama) dan di luar jendela rintangan (ROUTE_DESIGN 6).

## Tingkat keramaian segmen (tag `tingkat`).
enum Tingkat { TENANG, SEDANG, PADAT }
## Letak segmen dalam rute (tag `posisi`).
enum Posisi { PEMBUKA, TENGAH, PENUTUP }

## Nilai tag `tingkat` di data, urut sama dengan `Tingkat`.
const NAMA_TINGKAT: Array[String] = ["tenang", "sedang", "padat"]
## Nilai tag `posisi` di data, urut sama dengan `Posisi`.
const NAMA_POSISI: Array[String] = ["pembuka", "tengah", "penutup"]
## Nilai sisi di data (rumah, titik misi).
const NAMA_SISI: Array[String] = ["seberang", "dekat"]
## Nilai jalur di data (objek); `tengah` sah dibaca tetapi ditolak untuk rintangan.
const NAMA_JALUR: Array[String] = ["seberang", "tengah", "dekat"]
## Nilai tag `sisi_pelanggan` di data (ROUTE_DESIGN 1).
const NAMA_SISI_PELANGGAN: Array[String] = ["seberang", "dekat", "dua_sisi"]
## Jenis rumah sisi `seberang`: nama bentuk aset `house_perumahan_<jenis>_<pelanggan|bukan>` di `assets/sprites/houses/perumahan/`.
const JENIS_RUMAH_SEBERANG: Array[String] = ["limasan", "pelana", "sayap"]
## Jenis rumah sisi `dekat` (terlihat belakangnya): `house_perumahan_<jenis>_<pelanggan|bukan>`.
const JENIS_RUMAH_DEKAT: Array[String] = ["dekat_limasan", "dekat_pelana_lintang", "dekat_pelana_sejajar"]
## Jenis objek yang dikenal (rintangan prototype 3, ROUTE_DESIGN 4): `obs_anjing_sheet` dan `obs_mobil_garasi_sheet`.
const JENIS_OBJEK: Array[String] = ["anjing_penjaga", "mobil_garasi"]
## Distrik yang pelanggannya hanya di sisi `seberang` (GDD 9.1, ROADMAP 5: rumah sisi dekat belum diputuskan).
const DISTRIK_SATU_SISI: Array[String] = ["perumahan"]

const _FIELD_SEGMEN: Array[String] = ["id", "distrik", "panjang", "tag", "rumah", "objek", "titik_misi"]
const _FIELD_TAG: Array[String] = ["tingkat", "sisi_pelanggan", "posisi"]
const _FIELD_RUMAH: Array[String] = ["pos", "sisi", "jenis", "pelanggan_boleh"]
const _FIELD_OBJEK: Array[String] = ["jenis", "pos", "jalur", "tanda_ubin"]
const _FIELD_TITIK: Array[String] = ["nama", "pos", "sisi"]


## Satu rumah di segmen.
class Rumah extends RefCounted:
	## Ubin dari awal segmen sampai awal kavling (geometri zona dan tapak relatif ke sini, `ZonaSasaran`).
	var pos: int = 0
	## `SEBERANG` atau `DEKAT`.
	var sisi: LoperAnim.Sisi = LoperAnim.Sisi.TIDAK_ADA
	## Bentuk rumah (`JENIS_RUMAH_SEBERANG` atau `JENIS_RUMAH_DEKAT`).
	var jenis: String = ""
	## True bila rumah ini boleh dipilih jadi pelanggan saat rute disusun.
	var pelanggan_boleh: bool = false


## Satu rintangan yang ditandai di segmen (perilakunya Run 3B).
class Objek extends RefCounted:
	## Salah satu `JENIS_OBJEK`.
	var jenis: String = ""
	## Ubin dari awal segmen.
	var pos: int = 0
	## `seberang` atau `dekat` (`tengah` ditolak untuk rintangan).
	var jalur: String = ""
	## Jarak tanda terlihat sebelum rintangan, ubin.
	var tanda_ubin: float = 0.0


## Satu tempat yang boleh dipakai misi (DATA_SCHEMA 3, Fase 4).
class TitikMisi extends RefCounted:
	## Nama titik, huruf kecil dan garis bawah (mis. `atap`, `balik_pot`).
	var nama: String = ""
	## Ubin dari awal segmen.
	var pos: int = 0
	## `SEBERANG` atau `DEKAT`.
	var sisi: LoperAnim.Sisi = LoperAnim.Sisi.TIDAK_ADA


## Hasil `parse`: segmen (null bila ada galat) dan daftar galat berbahasa Indonesia.
class Hasil extends RefCounted:
	var segmen: SegmenRute = null
	var galat: Array[String] = []

	## True bila tidak ada galat dan segmen terbentuk.
	func sah() -> bool:
		return galat.is_empty() and segmen != null


var id: String = ""
var distrik: String = ""
var panjang: int = 0
var tingkat: Tingkat = Tingkat.TENANG
var posisi: Posisi = Posisi.TENGAH
## Nilai tag `sisi_pelanggan` (salah satu `NAMA_SISI_PELANGGAN`).
var sisi_pelanggan: String = ""
var rumah: Array[Rumah] = []
var objek: Array[Objek] = []
var titik_misi: Array[TitikMisi] = []


## Parse dan validasi satu segmen dari `data`. Segmen null bila ada galat; galat mengumpulkan SEMUA pelanggaran yang ketemu.
static func parse(data: Dictionary) -> Hasil:
	var hasil: Hasil = Hasil.new()
	var g: Array[String] = hasil.galat
	_tolak_field_asing(data, _FIELD_SEGMEN, "segmen", g)
	var segmen: SegmenRute = SegmenRute.new()
	segmen.id = _teks_wajib(data, "id", "segmen", g)
	if not segmen.id.is_empty() and not _nama_sah(segmen.id):
		g.append("segmen: id '%s' harus huruf kecil, angka, dan garis bawah, dimulai huruf" % segmen.id)
	var label: String = "segmen '%s'" % segmen.id
	segmen.distrik = _teks_wajib(data, "distrik", label, g)
	segmen.panjang = _bulat_wajib(data, "panjang", label, g)
	var ada_panjang: bool = data.has("panjang") and _bulat(data["panjang"])
	if ada_panjang and (segmen.panjang < Config.RUTE_SEGMEN_PANJANG_MIN_UBIN or segmen.panjang > Config.RUTE_SEGMEN_PANJANG_MAKS_UBIN):
		g.append("%s: panjang %d di luar %d sampai %d ubin" % [label, segmen.panjang, Config.RUTE_SEGMEN_PANJANG_MIN_UBIN, Config.RUTE_SEGMEN_PANJANG_MAKS_UBIN])
	_parse_tag(data, segmen, label, g)
	_parse_rumah(data, segmen, label, ada_panjang, g)
	_parse_objek(data, segmen, label, ada_panjang, g)
	_parse_titik_misi(data, segmen, label, ada_panjang, g)
	if g.is_empty():
		hasil.segmen = segmen
	return hasil


## Nama sisi di data ke enum (`TIDAK_ADA` bila bukan `seberang` atau `dekat`).
static func sisi_dari_nama(nama: String) -> LoperAnim.Sisi:
	if nama == NAMA_SISI[0]:
		return LoperAnim.Sisi.SEBERANG
	if nama == NAMA_SISI[1]:
		return LoperAnim.Sisi.DEKAT
	return LoperAnim.Sisi.TIDAK_ADA


## True bila jenis objek termasuk rintangan yang memaksa pindah jalur (semua `JENIS_OBJEK` di prototype 3).
static func memaksa_pindah(jenis_objek: String) -> bool:
	return JENIS_OBJEK.has(jenis_objek)


## Bentuk tanah rintangan `jenis` di titik `maju_ubin` jalur `sisi` yang tidak boleh memotong rumah (koordinat jalan, ubin): mobil garasi =
## seluruh lintasannya (`MobilGarasi.lintasan`), anjing penjaga = bentuk diamnya di halaman (`AnjingPenjaga.kotak` saat `baru`). Jenis
## atau sisi tidak dikenal = persegi kosong.
static func bentuk_rintangan_diam(jenis: String, maju_ubin: float, sisi: LoperAnim.Sisi) -> Rect2:
	if sisi == LoperAnim.Sisi.TIDAK_ADA:
		return Rect2()
	if jenis == "mobil_garasi":
		return MobilGarasi.lintasan(maju_ubin, sisi)
	if jenis == "anjing_penjaga":
		return AnjingPenjaga.kotak(AnjingPenjaga.baru(maju_ubin, sisi, 0.0))
	return Rect2()


## True bila bentuk rintangan `jenis` di `pos_objek` jalur `sisi_objek` beririsan dengan tapak rumah sisi `sisi_rumah` di `pos_rumah`
## (`PenutupPemain.tapak_rumah`; pos keduanya relatif ke awal segmen yang sama). Tepi yang hanya bersentuhan = false.
static func rintangan_memotong_rumah(jenis: String, pos_objek: float, sisi_objek: LoperAnim.Sisi, pos_rumah: float, sisi_rumah: LoperAnim.Sisi) -> bool:
	if sisi_rumah == LoperAnim.Sisi.TIDAK_ADA:
		return false
	return Tabrakan.bertumpuk(bentuk_rintangan_diam(jenis, pos_objek, sisi_objek), PenutupPemain.tapak_rumah(sisi_rumah, pos_rumah))


# --- Pemeriksa bagian ---

static func _parse_tag(data: Dictionary, segmen: SegmenRute, label: String, g: Array[String]) -> void:
	if not data.has("tag"):
		g.append("%s: field wajib 'tag' tidak ada" % label)
		return
	if typeof(data["tag"]) != TYPE_DICTIONARY:
		g.append("%s: 'tag' harus objek" % label)
		return
	var tag: Dictionary = data["tag"]
	_tolak_field_asing(tag, _FIELD_TAG, label + " tag", g)
	var nama_tingkat: String = _teks_wajib(tag, "tingkat", label + " tag", g)
	var idx_tingkat: int = NAMA_TINGKAT.find(nama_tingkat)
	if idx_tingkat < 0 and tag.has("tingkat") and not nama_tingkat.is_empty():
		g.append("%s: tingkat '%s' bukan %s" % [label, nama_tingkat, "/".join(NAMA_TINGKAT)])
	elif idx_tingkat >= 0:
		segmen.tingkat = idx_tingkat as Tingkat
	var nama_posisi: String = _teks_wajib(tag, "posisi", label + " tag", g)
	var idx_posisi: int = NAMA_POSISI.find(nama_posisi)
	if idx_posisi < 0 and tag.has("posisi") and not nama_posisi.is_empty():
		g.append("%s: posisi '%s' bukan %s" % [label, nama_posisi, "/".join(NAMA_POSISI)])
	elif idx_posisi >= 0:
		segmen.posisi = idx_posisi as Posisi
	segmen.sisi_pelanggan = _teks_wajib(tag, "sisi_pelanggan", label + " tag", g)
	if not segmen.sisi_pelanggan.is_empty() and not NAMA_SISI_PELANGGAN.has(segmen.sisi_pelanggan):
		g.append("%s: sisi_pelanggan '%s' bukan %s" % [label, segmen.sisi_pelanggan, "/".join(NAMA_SISI_PELANGGAN)])
	elif DISTRIK_SATU_SISI.has(segmen.distrik) and not segmen.sisi_pelanggan.is_empty() and segmen.sisi_pelanggan != NAMA_SISI[0]:
		g.append("%s: distrik %s hanya punya pelanggan di sisi seberang, sisi_pelanggan '%s'" % [label, segmen.distrik, segmen.sisi_pelanggan])
	if idx_posisi >= 0 and idx_posisi != Posisi.TENGAH and idx_tingkat >= 0 and idx_tingkat != Tingkat.TENANG:
		g.append("%s: segmen %s harus bertingkat tenang (ROUTE_DESIGN 5), dapat '%s'" % [label, nama_posisi, nama_tingkat])


static func _parse_rumah(data: Dictionary, segmen: SegmenRute, label: String, ada_panjang: bool, g: Array[String]) -> void:
	var daftar: Array = _daftar_wajib(data, "rumah", label, g)
	var nomor: int = 0
	for entri: Variant in daftar:
		nomor += 1
		var nama: String = "%s rumah #%d" % [label, nomor]
		if typeof(entri) != TYPE_DICTIONARY:
			g.append("%s: harus objek" % nama)
			continue
		var d: Dictionary = entri
		_tolak_field_asing(d, _FIELD_RUMAH, nama, g)
		var rumah: Rumah = Rumah.new()
		var ok_pos: bool = _pos_sah(d, nama, segmen.panjang, ada_panjang, g)
		if ok_pos:
			rumah.pos = int(roundf(float(d["pos"])))
		var nama_sisi: String = _teks_wajib(d, "sisi", nama, g)
		rumah.sisi = sisi_dari_nama(nama_sisi)
		if d.has("sisi") and not nama_sisi.is_empty() and rumah.sisi == LoperAnim.Sisi.TIDAK_ADA:
			g.append("%s: sisi '%s' bukan seberang atau dekat (GDD 4.2)" % [nama, nama_sisi])
		rumah.jenis = _teks_wajib(d, "jenis", nama, g)
		var jenis_sah: Array[String] = JENIS_RUMAH_SEBERANG if rumah.sisi == LoperAnim.Sisi.SEBERANG else JENIS_RUMAH_DEKAT
		if not rumah.jenis.is_empty() and rumah.sisi != LoperAnim.Sisi.TIDAK_ADA and not jenis_sah.has(rumah.jenis):
			g.append("%s: jenis '%s' tidak dikenal untuk sisi %s (%s)" % [nama, rumah.jenis, nama_sisi, ", ".join(jenis_sah)])
		if not d.has("pelanggan_boleh"):
			g.append("%s: field wajib 'pelanggan_boleh' tidak ada" % nama)
		elif typeof(d["pelanggan_boleh"]) != TYPE_BOOL:
			g.append("%s: 'pelanggan_boleh' harus true atau false" % nama)
		else:
			rumah.pelanggan_boleh = d["pelanggan_boleh"]
		if rumah.pelanggan_boleh and rumah.sisi == LoperAnim.Sisi.DEKAT and DISTRIK_SATU_SISI.has(segmen.distrik):
			g.append("%s: rumah sisi dekat tidak boleh jadi pelanggan di distrik %s (GDD 9.1)" % [nama, segmen.distrik])
		if ok_pos:
			for lain: Rumah in segmen.rumah:
				if lain.pos == rumah.pos:
					g.append("%s: pos %d dipakai dua rumah (id rumah <id_segmen>@<pos> harus unik)" % [nama, rumah.pos])
				elif lain.sisi == rumah.sisi and absi(lain.pos - rumah.pos) < Config.RUTE_PETAK_UBIN:
					g.append("%s: pos %d terlalu dekat rumah di pos %d (petak %d ubin)" % [nama, rumah.pos, lain.pos, Config.RUTE_PETAK_UBIN])
		segmen.rumah.append(rumah)


static func _parse_objek(data: Dictionary, segmen: SegmenRute, label: String, ada_panjang: bool, g: Array[String]) -> void:
	var daftar: Array = _daftar_wajib(data, "objek", label, g)
	var nomor: int = 0
	for entri: Variant in daftar:
		nomor += 1
		var nama: String = "%s objek #%d" % [label, nomor]
		if typeof(entri) != TYPE_DICTIONARY:
			g.append("%s: harus objek" % nama)
			continue
		var d: Dictionary = entri
		_tolak_field_asing(d, _FIELD_OBJEK, nama, g)
		var objek: Objek = Objek.new()
		objek.jenis = _teks_wajib(d, "jenis", nama, g)
		if not objek.jenis.is_empty() and not JENIS_OBJEK.has(objek.jenis):
			g.append("%s: jenis '%s' tidak dikenal (%s)" % [nama, objek.jenis, ", ".join(JENIS_OBJEK)])
		var ok_pos: bool = _pos_sah(d, nama, segmen.panjang, ada_panjang, g)
		if ok_pos:
			objek.pos = int(roundf(float(d["pos"])))
			if ada_panjang and (objek.pos < Config.RUTE_RINTANGAN_TEPI_UBIN or objek.pos > segmen.panjang - Config.RUTE_RINTANGAN_TEPI_UBIN):
				g.append("%s: rintangan di pos %d lebih dekat dari %d ubin ke tepi segmen (sambungan segmen menumpuk keputusan)" % [nama, objek.pos, Config.RUTE_RINTANGAN_TEPI_UBIN])
		objek.jalur = _teks_wajib(d, "jalur", nama, g)
		if not objek.jalur.is_empty() and not NAMA_JALUR.has(objek.jalur):
			g.append("%s: jalur '%s' bukan seberang, tengah, atau dekat (GDD 4.2)" % [nama, objek.jalur])
		elif objek.jalur == NAMA_JALUR[1]:
			g.append("%s: rintangan di jalur tengah (jalur utama harus selalu bersih, GDD 2 prinsip 3)" % nama)
		if not d.has("tanda_ubin"):
			g.append("%s: field wajib 'tanda_ubin' tidak ada (tanda sebelum bahaya, ROUTE_DESIGN 4)" % nama)
		elif not _angka(d["tanda_ubin"]):
			g.append("%s: 'tanda_ubin' harus angka" % nama)
		else:
			objek.tanda_ubin = float(d["tanda_ubin"])
			if objek.tanda_ubin < Config.RUTE_TANDA_MIN_UBIN:
				g.append("%s: tanda %.1f ubin kurang dari %.1f (1,5 detik pada ngebut, ROUTE_DESIGN 4)" % [nama, objek.tanda_ubin, Config.RUTE_TANDA_MIN_UBIN])
		var sisi_objek: LoperAnim.Sisi = sisi_dari_nama(objek.jalur)
		if ok_pos and JENIS_OBJEK.has(objek.jenis) and sisi_objek != LoperAnim.Sisi.TIDAK_ADA:
			for rumah: Rumah in segmen.rumah:
				if rintangan_memotong_rumah(objek.jenis, float(objek.pos), sisi_objek, float(rumah.pos), rumah.sisi):
					g.append("%s: %s di pos %d (jalur %s) memotong tapak rumah %s di pos %d (mobil di celah samping rumah, ROUTE_DESIGN 4)" % [nama, objek.jenis, objek.pos, objek.jalur, NAMA_SISI[0] if rumah.sisi == LoperAnim.Sisi.SEBERANG else NAMA_SISI[1], rumah.pos])
		if ok_pos:
			for lain: Objek in segmen.objek:
				if memaksa_pindah(lain.jenis) and memaksa_pindah(objek.jenis) and absi(lain.pos - objek.pos) < Config.RUTE_RINTANGAN_JENDELA_UBIN:
					g.append("%s: pos %d hanya %d ubin dari rintangan di pos %d (dalam %d ubin maksimal satu, ROUTE_DESIGN 4)" % [nama, objek.pos, absi(lain.pos - objek.pos), lain.pos, Config.RUTE_RINTANGAN_JENDELA_UBIN])
		segmen.objek.append(objek)


static func _parse_titik_misi(data: Dictionary, segmen: SegmenRute, label: String, ada_panjang: bool, g: Array[String]) -> void:
	var daftar: Array = _daftar_wajib(data, "titik_misi", label, g)
	var nomor: int = 0
	for entri: Variant in daftar:
		nomor += 1
		var nama: String = "%s titik_misi #%d" % [label, nomor]
		if typeof(entri) != TYPE_DICTIONARY:
			g.append("%s: harus objek" % nama)
			continue
		var d: Dictionary = entri
		_tolak_field_asing(d, _FIELD_TITIK, nama, g)
		var titik: TitikMisi = TitikMisi.new()
		titik.nama = _teks_wajib(d, "nama", nama, g)
		if not titik.nama.is_empty() and not _nama_sah(titik.nama):
			g.append("%s: nama '%s' harus huruf kecil, angka, dan garis bawah" % [nama, titik.nama])
		var ok_pos: bool = _pos_sah(d, nama, segmen.panjang, ada_panjang, g)
		if ok_pos:
			titik.pos = int(roundf(float(d["pos"])))
		var nama_sisi: String = _teks_wajib(d, "sisi", nama, g)
		titik.sisi = sisi_dari_nama(nama_sisi)
		if d.has("sisi") and not nama_sisi.is_empty() and titik.sisi == LoperAnim.Sisi.TIDAK_ADA:
			g.append("%s: sisi '%s' bukan seberang atau dekat (GDD 4.2)" % [nama, nama_sisi])
		if ok_pos and titik.sisi != LoperAnim.Sisi.TIDAK_ADA:
			var ada_rumah: bool = false
			for rumah: Rumah in segmen.rumah:
				if rumah.pos == titik.pos and rumah.sisi == titik.sisi:
					ada_rumah = true
			if not ada_rumah:
				g.append("%s: tidak ada rumah sisi %s di pos %d (titik misi harus di rumah)" % [nama, nama_sisi, titik.pos])
			for lain: Objek in segmen.objek:
				if absi(lain.pos - titik.pos) < Config.RUTE_RINTANGAN_JENDELA_UBIN:
					g.append("%s: pos %d dalam %d ubin dari rintangan di pos %d (petunjuk misi tidak bersama rintangan, ROUTE_DESIGN 6)" % [nama, titik.pos, Config.RUTE_RINTANGAN_JENDELA_UBIN, lain.pos])
		segmen.titik_misi.append(titik)


# --- Pembantu ---

static func _angka(nilai: Variant) -> bool:
	var tipe: int = typeof(nilai)
	if tipe == TYPE_INT:
		return true
	if tipe == TYPE_FLOAT:
		return is_finite(nilai)
	return false


static func _bulat(nilai: Variant) -> bool:
	return _angka(nilai) and is_equal_approx(float(nilai), roundf(float(nilai)))


static func _nama_sah(teks: String) -> bool:
	var re: RegEx = RegEx.create_from_string("^[a-z][a-z0-9_]*\\z")
	return re.search(teks) != null


static func _teks_wajib(data: Dictionary, kunci: String, label: String, g: Array[String]) -> String:
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


static func _bulat_wajib(data: Dictionary, kunci: String, label: String, g: Array[String]) -> int:
	if not data.has(kunci):
		g.append("%s: field wajib '%s' tidak ada" % [label, kunci])
		return 0
	if not _bulat(data[kunci]):
		g.append("%s: '%s' harus bilangan bulat" % [label, kunci])
		return 0
	return int(roundf(float(data[kunci])))


static func _daftar_wajib(data: Dictionary, kunci: String, label: String, g: Array[String]) -> Array:
	if not data.has(kunci):
		g.append("%s: field wajib '%s' tidak ada" % [label, kunci])
		return []
	if typeof(data[kunci]) != TYPE_ARRAY:
		g.append("%s: '%s' harus daftar" % [label, kunci])
		return []
	var daftar: Array = data[kunci]
	return daftar


static func _tolak_field_asing(data: Dictionary, dikenal: Array[String], label: String, g: Array[String]) -> void:
	for kunci: Variant in data.keys():
		if not dikenal.has(String(kunci)):
			g.append("%s: field '%s' tidak dikenal" % [label, kunci])


## `pos` wajib, bilangan bulat, dan di dalam segmen tanpa tepi netral (`RUTE_TEPI_UBIN`). False bila ada galat (galat sudah dicatat).
static func _pos_sah(d: Dictionary, nama: String, panjang: int, ada_panjang: bool, g: Array[String]) -> bool:
	if not d.has("pos"):
		g.append("%s: field wajib 'pos' tidak ada" % nama)
		return false
	if not _bulat(d["pos"]):
		g.append("%s: 'pos' harus bilangan bulat ubin" % nama)
		return false
	var pos: int = int(roundf(float(d["pos"])))
	if ada_panjang and (pos < Config.RUTE_TEPI_UBIN or pos > panjang - Config.RUTE_TEPI_UBIN):
		g.append("%s: pos %d di tepi segmen (harus %d sampai %d, tepi %d ubin kosong)" % [nama, pos, Config.RUTE_TEPI_UBIN, panjang - Config.RUTE_TEPI_UBIN, Config.RUTE_TEPI_UBIN])
		return false
	return true
