class_name TampilBengkel
extends RefCounted
## Pemilihan keadaan layar bengkel tata C sebagai data murni (run ui1-komponen-bengkel bagian B, AC-6 dan AC-7; kanvas Bengkel.dc.html, Bengkel_Tingkat.dc.html; usulan): keadaan kartu servis
## (menonjol, redup, biasa), chip penanda kondisi di sepeda, status aksi tombol (aktif, nonaktif bertulis alasan, tidak ada), jejak tingkat upgrade I, II, III, dan geometri panggung sepeda,
## kolom, dan penanda. `LayarBengkel` hanya mewujudkan hasilnya jadi node. Tanpa node, `Time`, atau RNG. Memakai `KomponenUi`, `TampilKondisi`, `BikeCondition`, dan `Economy.penuh`
## (tidak menduplikasi aturan mereka). Semua angka dari `Config`. Setiap keadaan terbaca TANPA warna: bentuk kartu, chip ("!" atau centang), teks status, dan teks alasan tombol.

## Keadaan aksi satu kartu: TIDAK_ADA (tidak ada yang dijual atau diservis: chip "Baik" atau "Dimiliki"), AKTIF (tombol aksi), KURANG (tombol nonaktif bertulis alasan "Koin kurang").
enum Aksi { TIDAK_ADA, AKTIF, KURANG }
## Posisi satu tingkat pada jejak I, II, III: DIMILIKI (sudah dibeli), AKTIF (yang sedang dijual), MENUNGGU (belum giliran).
enum StatusJejak { DIMILIKI, AKTIF, MENUNGGU }
## Sisi titik penanda tempat chip diletakkan: AWAL = di depan titik pada sumbu mendatar, AKHIR = sesudah titik, BAWAH = di bawah titik.
enum Sisi { AWAL, AKHIR, BAWAH }

## Kunci terjemahan teks tombol aksi dan alasan nonaktif, penanda kondisi di sepeda, dan angka tingkat.
const KUNCI_AKSI_SERVIS: String = "BENGKEL_SERVIS"
const KUNCI_AKSI_BELI: String = "BENGKEL_BELI"
const KUNCI_KURANG: String = "BENGKEL_KOIN_KURANG"
const KUNCI_PENANDA_PERLU: String = "BENGKEL_PENANDA_PERLU"
const KUNCI_PENANDA_AUS: String = "BENGKEL_PENANDA_AUS"
const KUNCI_TINGKAT: Array[String] = ["BENGKEL_TINGKAT_1", "BENGKEL_TINGKAT_2", "BENGKEL_TINGKAT_3"]
const KUNCI_TINGKAT_LAIN: String = "BENGKEL_TINGKAT_LAIN"
## Sisi chip penanda tiap komponen di sepeda (kanvas: ban di depan titik, rem sesudah titik, rantai di bawah titik).
const SISI_PENANDA: Dictionary = {"ban": Sisi.AWAL, "rem": Sisi.AKHIR, "rantai": Sisi.BAWAH}


## Keadaan satu kartu servis komponen.
class InfoServis extends RefCounted:
	## Jenis kartu: PERLU_BENGKEL menonjol, BAIK redup, AUS biasa (`KomponenUi.kartu_servis`).
	var kartu: KomponenUi.JenisKartu = KomponenUi.JenisKartu.BIASA
	## True bila komponen penuh (1,0): tidak bisa diservis, chip "Baik" menggantikan harga dan tombol.
	var penuh: bool = false
	var harga: int = 0
	var aksi: TampilBengkel.Aksi = TampilBengkel.Aksi.TIDAK_ADA
	## Kunci teks status kecil di bawah nama ("" bila penuh: chip "Baik" sudah menyatakannya).
	var kunci_status: String = ""
	## True bila ada chip penanda di sepeda (AUS atau PERLU_BENGKEL); sepeda yang baik tampil bersih.
	var penanda: bool = false
	## Status chip penanda (`KomponenUi.StatusChip.AUS` atau `PERLU_SERVIS`) dan kunci format teksnya ("! {nama}" atau "{nama} aus").
	var status_penanda: KomponenUi.StatusChip = KomponenUi.StatusChip.AUS
	var kunci_penanda: String = ""
	## Chip pernyataan bila penuh (`KomponenUi.StatusChip.BAIK`).
	var status_chip: KomponenUi.StatusChip = KomponenUi.StatusChip.BAIK


## Keadaan satu kartu upgrade komponen (satu kartu per komponen; tingkat berikutnya menggantikan isinya, kanvas Bengkel_Tingkat).
class InfoUpgrade extends RefCounted:
	## Indeks tingkat yang ditampilkan (yang sedang dijual, atau yang terakhir bila semua dimiliki).
	var indeks: int = 0
	## Tingkat (angka) yang ditampilkan dan jumlah tingkat komponen ini.
	var tingkat: int = 1
	var jumlah: int = 1
	## True bila semua tingkat dimiliki: kartu redup bertuliskan "Dimiliki".
	var dimiliki: bool = false
	var harga: int = 0
	var aksi: TampilBengkel.Aksi = TampilBengkel.Aksi.TIDAK_ADA
	var kartu: KomponenUi.JenisKartu = KomponenUi.JenisKartu.BIASA
	## Status jejak per tingkat (urut tingkat); ditampilkan hanya bila `jejak_tampil`.
	var jejak: Array[TampilBengkel.StatusJejak] = []
	var jejak_tampil: bool = false
	## Status chip tingkat di bawah ikon (AKSEN bila sudah dimiliki atau komponen bertingkat, selain itu NETRAL).
	var status_tingkat: KomponenUi.StatusChip = KomponenUi.StatusChip.TINGKAT_LAIN
	## Tinggi kartu, piksel game (`Config.BENGKEL_KARTU_UPGRADE_PX`, atau `..._JEJAK_PX` bila ada jejak).
	var tinggi: int = 0


## Posisi (piksel game, relatif pojok kiri atas panggung) papan alat dan sepeda.
class TataPanggung extends RefCounted:
	var papan: Vector2i = Vector2i.ZERO
	var sepeda: Vector2i = Vector2i.ZERO


## Status aksi: TIDAK_ADA bila tidak `tersedia`; AKTIF bila `saldo >= harga` (tepat sama sah); selain itu KURANG.
static func aksi(tersedia: bool, saldo: int, harga: int) -> Aksi:
	if not tersedia:
		return Aksi.TIDAK_ADA
	return Aksi.AKTIF if saldo >= harga else Aksi.KURANG


## Kunci teks tombol: alasan "Koin kurang" bila KURANG, selain itu `kunci_aksi` ("Servis" atau "Beli"). Terbaca tanpa warna.
static func kunci_tombol(status: Aksi, kunci_aksi: String) -> String:
	return KUNCI_KURANG if status == Aksi.KURANG else kunci_aksi


## Keadaan kartu servis komponen berkondisi `kondisi` (0..1) berharga servis `harga` untuk pemain bersaldo `saldo`. Penuh (Economy.penuh) = tanpa harga dan tombol; selain itu tombol Servis.
static func servis(kondisi: float, harga: int, saldo: int) -> InfoServis:
	var hasil: InfoServis = InfoServis.new()
	var tingkat: BikeCondition.Tingkat = BikeCondition.tingkat(kondisi)
	hasil.penuh = Economy.penuh(kondisi)
	hasil.kartu = KomponenUi.kartu_servis(tingkat)
	hasil.harga = 0 if hasil.penuh else harga
	hasil.aksi = aksi(not hasil.penuh, saldo, harga)
	hasil.kunci_status = "" if hasil.penuh else TampilKondisi.kunci_tingkat(kondisi)
	hasil.penanda = tingkat != BikeCondition.Tingkat.BAIK
	hasil.status_penanda = KomponenUi.status_chip_servis(tingkat)
	hasil.kunci_penanda = KUNCI_PENANDA_PERLU if tingkat == BikeCondition.Tingkat.PERLU_BENGKEL else KUNCI_PENANDA_AUS
	return hasil


## Keadaan kartu upgrade satu komponen. `tingkat` = tingkat yang ada di data (urut naik), `harga` = harga tiap tingkat (sejajar), `level_dimiliki` = level komponen di save, `saldo` = saldo koin.
## Yang ditampilkan: tingkat pertama yang belum dimiliki (yang dijual); semua dimiliki = tingkat terakhir, kartu redup, tanpa aksi. Jejak muncul hanya bila lebih dari satu tingkat.
static func upgrade(tingkat: Array[int], harga: Array[int], level_dimiliki: int, saldo: int) -> InfoUpgrade:
	var hasil: InfoUpgrade = InfoUpgrade.new()
	hasil.jumlah = tingkat.size()
	if tingkat.is_empty():
		return hasil
	var dijual: int = -1
	for i: int in range(tingkat.size()):
		if tingkat[i] > level_dimiliki:
			dijual = i
			break
	hasil.dimiliki = dijual < 0
	hasil.indeks = tingkat.size() - 1 if hasil.dimiliki else dijual
	hasil.tingkat = tingkat[hasil.indeks]
	hasil.harga = harga[hasil.indeks]
	hasil.aksi = aksi(not hasil.dimiliki, saldo, hasil.harga)
	hasil.kartu = KomponenUi.kartu_upgrade(hasil.dimiliki)
	hasil.jejak_tampil = tingkat.size() > 1
	for i: int in range(tingkat.size()):
		if tingkat[i] <= level_dimiliki:
			hasil.jejak.append(StatusJejak.DIMILIKI)
		elif i == hasil.indeks:
			hasil.jejak.append(StatusJejak.AKTIF)
		else:
			hasil.jejak.append(StatusJejak.MENUNGGU)
	hasil.status_tingkat = status_chip_tingkat(hasil.dimiliki, hasil.jumlah)
	hasil.tinggi = Config.BENGKEL_KARTU_UPGRADE_JEJAK_PX if hasil.jejak_tampil else Config.BENGKEL_KARTU_UPGRADE_PX
	return hasil


## Status chip tingkat di bawah ikon kartu upgrade: AKSEN bila sudah dimiliki atau komponen bertingkat (> 1), selain itu NETRAL (kanvas Bengkel a dan d, Bengkel_Tingkat).
static func status_chip_tingkat(dimiliki: bool, jumlah: int) -> KomponenUi.StatusChip:
	if dimiliki or jumlah > 1:
		return KomponenUi.StatusChip.TINGKAT_AKTIF
	return KomponenUi.StatusChip.TINGKAT_LAIN


## Status chip satu tingkat pada jejak: DIMILIKI netral bercentang, AKTIF aksen, MENUNGGU netral tanpa centang (kanvas meredupkannya dengan opacity .55, tetapi teks redup < 7:1; dibedakan dari DIMILIKI lewat centang dan dari AKTIF lewat gaya).
static func status_chip_jejak(status: StatusJejak) -> KomponenUi.StatusChip:
	if status == StatusJejak.AKTIF:
		return KomponenUi.StatusChip.TINGKAT_AKTIF
	return KomponenUi.StatusChip.TINGKAT_LAIN


## Kunci teks angka tingkat: I, II, III untuk tingkat 1..3, selain itu angka biasa (`KUNCI_TINGKAT_LAIN`).
static func kunci_tingkat(tingkat: int) -> String:
	if tingkat >= 1 and tingkat <= Config.BENGKEL_TINGKAT_ROMAWI_MAKS:
		return KUNCI_TINGKAT[tingkat - 1]
	return KUNCI_TINGKAT_LAIN


## Lebar kolom servis dan upgrade (x = servis, y = upgrade) untuk lebar isi `total` (viewport dikurangi margin): servis `Config.BENGKEL_KOLOM_SERVIS_FRAKSI` dibulatkan, jarak 8, sisanya upgrade.
static func lebar_kolom(total: int) -> Vector2i:
	var servis_lebar: int = roundi(float(total) * Config.BENGKEL_KOLOM_SERVIS_FRAKSI)
	return Vector2i(servis_lebar, total - servis_lebar - Config.BENGKEL_KOLOM_JARAK_PX)


## Letak papan alat (bawah panggung, tengah mendatar) dan sepeda (tengah mendatar, `BENGKEL_SEPEDA_BAWAH_PX` di atas dasar) di panggung berukuran `lebar` x `tinggi`.
static func tata_panggung(lebar: int, tinggi: int) -> TataPanggung:
	var tata: TataPanggung = TataPanggung.new()
	tata.sepeda = Vector2i((lebar >> 1) - (Config.BENGKEL_SEPEDA_LEBAR_PX >> 1), tinggi - Config.BENGKEL_SEPEDA_BAWAH_PX - Config.BENGKEL_SEPEDA_TINGGI_PX)
	tata.papan = Vector2i((lebar >> 1) - (Config.BENGKEL_PAPAN_LEBAR_PX >> 1), tinggi - Config.BENGKEL_PAPAN_TINGGI_PX)
	return tata


## Titik penanda komponen ke-`indeks` (urut `Config.KONDISI_KOMPONEN`) di sepeda kecil, piksel gambar sepeda.
static func titik_sepeda(indeks: int) -> Vector2i:
	return Vector2i(Config.BENGKEL_SEPEDA_TITIK[indeks * 2], Config.BENGKEL_SEPEDA_TITIK[indeks * 2 + 1])


## Persegi titik penanda (3x3 berbingkai gelap 1 px, jadi 5x5) di panggung, untuk komponen ke-`indeks`.
static func rect_titik(indeks: int, tata: TataPanggung) -> Rect2i:
	var cincin: int = Config.UI_GARIS_PX
	var pusat: Vector2i = tata.sepeda + titik_sepeda(indeks)
	var tepi: int = (Config.BENGKEL_PENANDA_TITIK_PX >> 1) + cincin
	return Rect2i(pusat - Vector2i(tepi, tepi), Vector2i.ONE * (Config.BENGKEL_PENANDA_TITIK_PX + 2 * cincin))


## Persegi chip penanda komponen ke-`indeks` (ukuran `chip`) di panggung berukuran `panggung`: AWAL di depan titik (tidak melewati tepi), AKHIR sesudah titik, BAWAH di bawah titik; selain
## BAWAH chip naik di atas titik. Selalu dijepit ke dalam panggung (tepi minimum `BENGKEL_PENANDA_TEPI_PX` mendatar).
static func rect_chip(indeks: int, tata: TataPanggung, chip: Vector2i, panggung: Vector2i) -> Rect2i:
	var pusat: Vector2i = tata.sepeda + titik_sepeda(indeks)
	var sisi: Sisi = SISI_PENANDA[Config.KONDISI_KOMPONEN[indeks]]
	var x: int = pusat.x
	match sisi:
		Sisi.AWAL:
			x = maxi(Config.BENGKEL_PENANDA_TEPI_PX, pusat.x - chip.x - Config.BENGKEL_PENANDA_JARAK_AWAL_PX)
		Sisi.AKHIR:
			x = pusat.x + Config.BENGKEL_PENANDA_JARAK_AKHIR_PX
		Sisi.BAWAH:
			x = pusat.x - Config.BENGKEL_PENANDA_BAWAH_X_PX
	var y: int = pusat.y + Config.BENGKEL_PENANDA_BAWAH_Y_PX if sisi == Sisi.BAWAH else pusat.y - Config.BENGKEL_PENANDA_ATAS_Y_PX
	x = clampi(x, Config.BENGKEL_PENANDA_TEPI_PX, maxi(Config.BENGKEL_PENANDA_TEPI_PX, panggung.x - chip.x - Config.BENGKEL_PENANDA_TEPI_PX))
	y = clampi(y, 0, maxi(0, panggung.y - chip.y))
	return Rect2i(Vector2i(x, y), chip)
