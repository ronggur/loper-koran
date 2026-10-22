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
## - titik misi berdiri di rumah (pos dan sisi sama) dan di luar jendela rintangan (ROUTE_DESIGN 6);
## - dekor (bidang `dekor` OPSIONAL, run fase5b-tembok-dekor bagian B2, AC-9): tiap butir `{jenis, pos, sisi, varian}` semuanya wajib dan tanpa field lain, jenis dan varian
##   dari `DekorRute`, `pos` bilangan bulat `RUTE_DEKOR_TEPI_UBIN` sampai `panjang - RUTE_DEKOR_TEPI_UBIN`, tapak kaki di luar lajur sepeda, tidak menimpa zona teras atau
##   kotak surat rumah mana pun, tapak rumah, atau tapak rintangan diam, dan dua dekor sesisi paling dekat `RUTE_DEKOR_JARAK_MIN_UBIN` ubin. Berkas tanpa `dekor` tetap sah.
## - simpang T hiasan (bidang `simpang` OPSIONAL, run fase5c-animasi-simpang, P-1, D-3, AC-15): tiap butir `{pos, sisi}` keduanya wajib dan tanpa field lain, `sisi` `seberang` atau `dekat`,
##   `pos` bilangan bulat (baris `mulut_2`; `pita_maju`). Pita mulut + sudut (`RUTE_SIMPANG_PITA_BARIS`) harus di dalam segmen dan, di sisi simpang, tidak memotong kavling rumah (tapak logika dan
##   tapak gambar), zona rumah (kotak surat, halaman, teras, jendela), tapak dekor, bentuk diam rintangan (anjing diam, seluruh lintasan mobil), atau baris jalan masuk garasi beserta ujung kerbnya;
##   pita dua simpang (sisi mana pun) tidak boleh bertumpuk. Tepi yang hanya bersentuhan boleh. Simpang hanya hiasan: tanpa lalu lintas, rintangan, atau sasaran. Berkas tanpa `simpang` tetap sah.

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

const _FIELD_SEGMEN: Array[String] = ["id", "distrik", "panjang", "tag", "rumah", "objek", "titik_misi", "dekor", "simpang"]
const _FIELD_TAG: Array[String] = ["tingkat", "sisi_pelanggan", "posisi"]
const _FIELD_RUMAH: Array[String] = ["pos", "sisi", "jenis", "pelanggan_boleh"]
const _FIELD_OBJEK: Array[String] = ["jenis", "pos", "jalur", "tanda_ubin"]
const _FIELD_TITIK: Array[String] = ["nama", "pos", "sisi"]
const _FIELD_DEKOR: Array[String] = ["jenis", "pos", "sisi", "varian"]
const _FIELD_SIMPANG: Array[String] = ["pos", "sisi"]


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


## Satu dekor pinggir jalan di segmen (run fase5b-tembok-dekor bagian B2): hiasan, bukan penghalang.
class Dekor extends RefCounted:
	## Salah satu `Config.RUTE_DEKOR_JENIS`.
	var jenis: String = ""
	## Ubin dari awal segmen.
	var pos: int = 0
	## `SEBERANG` atau `DEKAT`.
	var sisi: LoperAnim.Sisi = LoperAnim.Sisi.TIDAK_ADA
	## Salah satu `DekorRute.varian_sah(jenis)`.
	var varian: String = ""


## Satu simpang T hiasan di segmen (run fase5c-animasi-simpang, P-1): jalan samping ke satu sisi, tanpa lalu lintas.
class Simpang extends RefCounted:
	## Ubin dari awal segmen ke pusat baris `mulut_2` (baris mulut yang lebih dekat ke awal segmen).
	var pos: int = 0
	## `SEBERANG` atau `DEKAT`: sisi jalan samping.
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
## Dekor pinggir jalan (kosong bila berkas tidak punya bidang `dekor`).
var dekor: Array[Dekor] = []
## Simpang T hiasan (kosong bila berkas tidak punya bidang `simpang`).
var simpang: Array[Simpang] = []


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
	_parse_dekor(data, segmen, label, ada_panjang, g)
	_parse_simpang(data, segmen, label, ada_panjang, g)
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


## Pita larangan simpang di `pos` (maju dari titik acuan yang sama dengan `pos`): Vector2(maju awal, maju akhir) = baris `pos + RUTE_SIMPANG_PITA_BARIS[0]` sampai
## `pos + RUTE_SIMPANG_PITA_BARIS[1]`, tiap baris setengah `RUTE_SETENGAH_BARIS_UBIN` ke kedua arah (pita = `pos - 1,5` sampai `pos + 3,5`).
static func pita_maju(pos: float) -> Vector2:
	return Vector2(pos + float(Config.RUTE_SIMPANG_PITA_BARIS[0]) - Config.RUTE_SETENGAH_BARIS_UBIN, pos + float(Config.RUTE_SIMPANG_PITA_BARIS[1]) + Config.RUTE_SETENGAH_BARIS_UBIN)


## True bila `bentuk` (koordinat jalan: x lateral, y maju) memotong pita `pita` (`pita_maju`) di sisi `sisi`: rentang maju bertumpuk (tepi yang bersentuhan tidak) dan bentuk
## menjangkau sisi simpang (lateral positif untuk `dekat`, negatif untuk `seberang`). Pita sisi simpang membentang dari garis tengah ke luar tanpa batas (lengan jalan samping).
static func memotong_pita(pita: Vector2, sisi: LoperAnim.Sisi, bentuk: Rect2) -> bool:
	if bentuk.position.y >= pita.y or bentuk.end.y <= pita.x:
		return false
	if sisi == LoperAnim.Sisi.DEKAT:
		return bentuk.end.x > 0.0
	if sisi == LoperAnim.Sisi.SEBERANG:
		return bentuk.position.x < 0.0
	return false


## True bila pita dua simpang bertumpuk (sisi mana pun): rentang maju bertumpuk, tepi yang bersentuhan tidak.
static func pita_bertumpuk(a: Vector2, b: Vector2) -> bool:
	return a.x < b.y and b.x < a.y


## Kavling rumah `sisi` di `pos_rumah` yang tidak boleh dipotong pita simpang: tapak logika (`PenutupPemain.tapak_rumah`) digabung tapak gambar (rumah dekat: kotak sprite
## nyata semua jenis, mundur 0,5). Tembok belakang run 5B dilepas (run fase5d-sisi-dekat, P-1), jadi rentang tembok tidak lagi ikut.
static func kavling_rumah(sisi: LoperAnim.Sisi, pos_rumah: float) -> Rect2:
	return PenutupPemain.tapak_rumah(sisi, pos_rumah).merge(PenutupPemain.tapak_rumah_gambar(sisi, pos_rumah))


## Baris jalan masuk garasi mobil sisi seberang di `pos_objek` beserta baris ujung kerbnya (`UbinKhusus`): kolom trotoar dan rumput pertama seberang, koordinat jalan.
static func bentuk_jalan_masuk(pos_objek: float) -> Rect2:
	var baris: float = float(UbinKhusus.baris_masuk(pos_objek))
	var awal: float = baris - Config.RUTE_SETENGAH_BARIS_UBIN
	var panjang: float = float(Config.RUTE_UJUNG_KERB_BARIS_RELATIF) + Config.RUTE_SETENGAH_BARIS_UBIN + Config.RUTE_SETENGAH_BARIS_UBIN
	var luar: float = Config.JALAN_LEBAR_UBIN / 2 + Config.JALAN_TROTOAR_UBIN + Config.JALAN_RUMPUT_TEPI_UBIN
	return Rect2(-luar, awal, luar - Config.JALAN_LEBAR_UBIN / 2, panjang)


## Galat tempat satu simpang `sisi` di `pos` terhadap isi segmen (rumah, zona, dekor, rintangan, jalan masuk). Dipakai `_parse_simpang` dan, dengan maju mutlak, `RouteBuilder.periksa_rute`.
static func galat_tempat_simpang(pos: float, sisi: LoperAnim.Sisi, rumah: Array[Rumah], objek: Array[Objek], dekor: Array[Dekor], nama: String) -> Array[String]:
	var g: Array[String] = []
	var pita: Vector2 = pita_maju(pos)
	for r: Rumah in rumah:
		if r.sisi == LoperAnim.Sisi.TIDAK_ADA:
			continue
		var nama_sisi_rumah: String = NAMA_SISI[0] if r.sisi == LoperAnim.Sisi.SEBERANG else NAMA_SISI[1]
		if memotong_pita(pita, sisi, kavling_rumah(r.sisi, float(r.pos))):
			g.append("%s: pita %.1f sampai %.1f memotong kavling rumah %s di pos %d" % [nama, pita.x, pita.y, nama_sisi_rumah, r.pos])
		var rr: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
		rr.sisi = r.sisi
		rr.maju_ubin = float(r.pos)
		for zona: ZonaSasaran.Zona in ZonaSasaran.zona_rumah(rr):
			if memotong_pita(pita, sisi, zona.persegi):
				g.append("%s: pita %.1f sampai %.1f memotong zona %s rumah %s di pos %d" % [nama, pita.x, pita.y, ZonaSasaran.Jenis.keys()[zona.jenis], nama_sisi_rumah, r.pos])
	for d: Dekor in dekor:
		if d.sisi != LoperAnim.Sisi.TIDAK_ADA and DekorRute.indeks_jenis(d.jenis) >= 0 and memotong_pita(pita, sisi, DekorRute.tapak(d.jenis, d.sisi, float(d.pos))):
			g.append("%s: pita %.1f sampai %.1f memotong dekor %s di pos %d" % [nama, pita.x, pita.y, d.jenis, d.pos])
	for o: Objek in objek:
		var sisi_objek: LoperAnim.Sisi = sisi_dari_nama(o.jalur)
		if not JENIS_OBJEK.has(o.jenis) or sisi_objek == LoperAnim.Sisi.TIDAK_ADA:
			continue
		if memotong_pita(pita, sisi, bentuk_rintangan_diam(o.jenis, float(o.pos), sisi_objek)):
			g.append("%s: pita %.1f sampai %.1f memotong %s di pos %d (jalur %s)" % [nama, pita.x, pita.y, o.jenis, o.pos, o.jalur])
		if o.jenis == "mobil_garasi" and sisi_objek == LoperAnim.Sisi.SEBERANG and memotong_pita(pita, sisi, bentuk_jalan_masuk(float(o.pos))):
			g.append("%s: pita %.1f sampai %.1f memotong jalan masuk garasi mobil di pos %d" % [nama, pita.x, pita.y, o.pos])
	return g


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


static func _parse_dekor(data: Dictionary, segmen: SegmenRute, label: String, ada_panjang: bool, g: Array[String]) -> void:
	if not data.has("dekor"):
		return
	if typeof(data["dekor"]) != TYPE_ARRAY:
		g.append("%s: 'dekor' harus daftar" % label)
		return
	var daftar: Array = data["dekor"]
	var nomor: int = 0
	for entri: Variant in daftar:
		nomor += 1
		var nama: String = "%s dekor #%d" % [label, nomor]
		if typeof(entri) != TYPE_DICTIONARY:
			g.append("%s: harus objek" % nama)
			continue
		var d: Dictionary = entri
		_tolak_field_asing(d, _FIELD_DEKOR, nama, g)
		var dekor: Dekor = Dekor.new()
		dekor.jenis = _teks_wajib(d, "jenis", nama, g)
		var jenis_sah: bool = DekorRute.indeks_jenis(dekor.jenis) >= 0
		if not dekor.jenis.is_empty() and not jenis_sah:
			g.append("%s: jenis '%s' tidak dikenal (%s)" % [nama, dekor.jenis, ", ".join(Config.RUTE_DEKOR_JENIS)])
		dekor.varian = _teks_wajib(d, "varian", nama, g)
		if jenis_sah and not dekor.varian.is_empty() and not DekorRute.varian_sah(dekor.jenis).has(dekor.varian):
			g.append("%s: varian '%s' tidak sah untuk jenis %s (%s)" % [nama, dekor.varian, dekor.jenis, ", ".join(DekorRute.varian_sah(dekor.jenis))])
		var nama_sisi: String = _teks_wajib(d, "sisi", nama, g)
		dekor.sisi = sisi_dari_nama(nama_sisi)
		if d.has("sisi") and not nama_sisi.is_empty() and dekor.sisi == LoperAnim.Sisi.TIDAK_ADA:
			g.append("%s: sisi '%s' bukan seberang atau dekat (GDD 4.2)" % [nama, nama_sisi])
		var ok_pos: bool = _pos_dekor_sah(d, nama, segmen.panjang, ada_panjang, g)
		if ok_pos:
			dekor.pos = int(roundf(float(d["pos"])))
		if ok_pos and jenis_sah and dekor.sisi != LoperAnim.Sisi.TIDAK_ADA:
			_periksa_tempat_dekor(dekor, segmen, nama, g)
		segmen.dekor.append(dekor)


static func _parse_simpang(data: Dictionary, segmen: SegmenRute, label: String, ada_panjang: bool, g: Array[String]) -> void:
	if not data.has("simpang"):
		return
	if typeof(data["simpang"]) != TYPE_ARRAY:
		g.append("%s: 'simpang' harus daftar" % label)
		return
	var daftar: Array = data["simpang"]
	var nomor: int = 0
	for entri: Variant in daftar:
		nomor += 1
		var nama: String = "%s simpang #%d" % [label, nomor]
		if typeof(entri) != TYPE_DICTIONARY:
			g.append("%s: harus objek" % nama)
			continue
		var d: Dictionary = entri
		_tolak_field_asing(d, _FIELD_SIMPANG, nama, g)
		var item: Simpang = Simpang.new()
		var nama_sisi: String = _teks_wajib(d, "sisi", nama, g)
		item.sisi = sisi_dari_nama(nama_sisi)
		if d.has("sisi") and not nama_sisi.is_empty() and item.sisi == LoperAnim.Sisi.TIDAK_ADA:
			g.append("%s: sisi '%s' bukan seberang atau dekat (GDD 4.2)" % [nama, nama_sisi])
		var ok_pos: bool = false
		if not d.has("pos"):
			g.append("%s: field wajib 'pos' tidak ada" % nama)
		elif not _bulat(d["pos"]):
			g.append("%s: 'pos' harus bilangan bulat ubin" % nama)
		else:
			ok_pos = true
			item.pos = int(roundf(float(d["pos"])))
		if ok_pos:
			var pita: Vector2 = pita_maju(float(item.pos))
			if ada_panjang and (pita.x < 0.0 or pita.y > float(segmen.panjang)):
				g.append("%s: pita %.1f sampai %.1f di luar segmen 0 sampai %d" % [nama, pita.x, pita.y, segmen.panjang])
			for lain: Simpang in segmen.simpang:
				if pita_bertumpuk(pita, pita_maju(float(lain.pos))):
					g.append("%s: pita di pos %d bertumpuk dengan pita simpang di pos %d" % [nama, item.pos, lain.pos])
			if item.sisi != LoperAnim.Sisi.TIDAK_ADA:
				g.append_array(galat_tempat_simpang(float(item.pos), item.sisi, segmen.rumah, segmen.objek, segmen.dekor, nama))
		segmen.simpang.append(item)


## Aturan tempat satu dekor (AC-9): lajur sepeda, zona teras dan kotak surat, tapak rumah, tapak rintangan, dan jarak ke dekor sesisi.
static func _periksa_tempat_dekor(dekor: Dekor, segmen: SegmenRute, nama: String, g: Array[String]) -> void:
	var tapak: Rect2 = DekorRute.tapak(dekor.jenis, dekor.sisi, float(dekor.pos))
	if DekorRute.menimpa_lajur(tapak):
		g.append("%s: %s di pos %d menimpa lajur sepeda (tapak lateral %.2f sampai %.2f, lajur sampai %.1f; jalur utama harus bersih)" % [nama, dekor.jenis, dekor.pos, tapak.position.x, tapak.end.x, Config.RUTE_DEKOR_LAJUR_UBIN])
	for rumah: Rumah in segmen.rumah:
		var nama_sisi_rumah: String = NAMA_SISI[0] if rumah.sisi == LoperAnim.Sisi.SEBERANG else NAMA_SISI[1]
		if DekorRute.menimpa_zona_rumah(tapak, rumah.sisi, float(rumah.pos)):
			g.append("%s: %s di pos %d menimpa zona teras atau kotak surat rumah %s di pos %d" % [nama, dekor.jenis, dekor.pos, nama_sisi_rumah, rumah.pos])
		if DekorRute.menimpa_tapak_rumah(tapak, rumah.sisi, float(rumah.pos)):
			g.append("%s: %s di pos %d menimpa tapak rumah %s di pos %d" % [nama, dekor.jenis, dekor.pos, nama_sisi_rumah, rumah.pos])
	for objek: Objek in segmen.objek:
		if JENIS_OBJEK.has(objek.jenis) and DekorRute.menimpa_rintangan(tapak, objek.jenis, float(objek.pos), sisi_dari_nama(objek.jalur)):
			g.append("%s: %s di pos %d menimpa tapak %s di pos %d (jalur %s)" % [nama, dekor.jenis, dekor.pos, objek.jenis, objek.pos, objek.jalur])
	for lain: Dekor in segmen.dekor:
		if lain.sisi == dekor.sisi and absi(lain.pos - dekor.pos) < Config.RUTE_DEKOR_JARAK_MIN_UBIN:
			g.append("%s: pos %d hanya %d ubin dari dekor sesisi di pos %d (paling dekat %d ubin)" % [nama, dekor.pos, absi(lain.pos - dekor.pos), lain.pos, Config.RUTE_DEKOR_JARAK_MIN_UBIN])


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


## `pos` dekor wajib, bilangan bulat, dan di dalam segmen: `RUTE_DEKOR_TEPI_UBIN` sampai `panjang - RUTE_DEKOR_TEPI_UBIN` (lebih longgar dari `_pos_sah`; dekor tidak membawa keputusan). False bila ada galat.
static func _pos_dekor_sah(d: Dictionary, nama: String, panjang: int, ada_panjang: bool, g: Array[String]) -> bool:
	if not d.has("pos"):
		g.append("%s: field wajib 'pos' tidak ada" % nama)
		return false
	if not _bulat(d["pos"]):
		g.append("%s: 'pos' harus bilangan bulat ubin" % nama)
		return false
	var pos: int = int(roundf(float(d["pos"])))
	if ada_panjang and (pos < Config.RUTE_DEKOR_TEPI_UBIN or pos > panjang - Config.RUTE_DEKOR_TEPI_UBIN):
		g.append("%s: pos %d di luar %d sampai %d" % [nama, pos, Config.RUTE_DEKOR_TEPI_UBIN, panjang - Config.RUTE_DEKOR_TEPI_UBIN])
		return false
	return true
