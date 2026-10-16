class_name RuteMain
extends AdeganJalan
## Scene rute (run fase3a-rute bagian B, AC-10 sampai AC-16, usulan): satu rute perumahan dari segmen JSON, scene utama game.
##
## Memakai seluruh perilaku `AdeganJalan` (gerak, kamera, jeda, lemparan, mode bantu, bunyi, HUD) dan hanya mengisi kaitnya untuk rute:
## - Dunia (D-13): rute disusun `RouteBuilder.bangun(benih, pustaka)` dari segmen `PemuatRute.muat_folder`; seed bawaan
##   `Config.RUTE_SEED_DEV`, "Main lagi" memakai seed + 1. Rumah dan kotak surat digambar `RumahDaurRute` (jendela daur), tanah `TanahDaur`.
## - Penilaian koran dan mode bantu (AC-10): `MedanKoran.dari_rute` untuk penilaian dan garis bidik, `ZonaSasaran.zona_rute_rentang` untuk sasaran
##   mode bantu sejauh jangkauan lemparan. Koran awal = `rute.koran_awal` (30), tanpa isi ulang jalan uji.
## - Akhir rute (AC-14, `AkhirRute`): sepeda mencapai garis akhir (`panjang_ubin`) -> `rute_selesai` tepat sekali, stick sungguhan dikunci
##   dan diganti stick buatan ke bawah penuh (rem dengan laju rem biasa), lemparan baru tidak diterima (koran yang sudah terbang tetap
##   mendarat dan dinilai), banner `RUTE_SELESAI` dan tombol dev "Main lagi" tampil. Jeda dan back tetap bekerja.
## - Penutup pemain (AC-15): SATU penerap (`PenerapPenutup`) memanggil `PenutupPemain` tiap langkah untuk semua rumah di jendela daur.
## - "Main lagi": seed + 1, rute baru, sepeda, sisa koran, dan koran terbang dikembalikan ke awal (`_kembalikan_awal`).
## - Area kotak surat (tindak lanjut uji HP 2026-10-16): `AreaKotakGambar` menggambar persegi zona kotak surat rumah pelanggan seberang di
##   tanah (jendela daur yang sama dengan rumah), supaya area yang dinilai terlihat.
## - Rintangan (run fase3b-rintangan-skor bagian B, AC-20): `RintanganRute.dari_rute` (kait `_rintangan_awal`, juga tiap "Main lagi"),
##   perilaku dan tabrakan di `AdeganJalan`; digambar `RintanganDaur` (anak induk Y-sort rumah, jendela daur, penutup lewat penerap yang
##   SAMA dengan rumah).
## - Skor dan koin (AC-9 sampai AC-13): kait `_skor_aktif` true, `_rute_skor` = rute ini (pemberi tip); umpan balik melayang digambar
##   `UmpanMelayangGambar` di atas objek.

## Sepeda mencapai garis akhir rute (tepat sekali per rute; diulang hanya sesudah "Main lagi").
signal rute_selesai
## Rute baru disusun (saat scene siap dan tiap "Main lagi").
signal rute_disusun(rute: RouteBuilder.Rute)

## Seed rute yang sedang dimainkan.
var _benih: int = Config.RUTE_SEED_DEV
var _rute: RouteBuilder.Rute = RouteBuilder.Rute.new()
var _pustaka: Array[SegmenRute] = []
## Galat memuat segmen atau menyusun rute (kosong bila baik).
var _galat: Array[String] = []
## False hanya di tes yang sengaja memicu galat: galat tidak dicetak sebagai `ERROR:` ke log (pemeriksa keluaran tes menolak baris itu).
var lapor_galat_ke_log: bool = true
var _selesai: bool = false

@onready var _daur: RumahDaurRute = %Objek
@onready var _area_kotak: AreaKotakGambar = %AreaKotak
@onready var _penerap: PenerapPenutup = %PenerapPenutup
@onready var _panel_akhir: PanelAkhirRute = %PanelAkhir
@onready var _rintangan_daur: RintanganDaur = %Rintangan
@onready var _umpan_gambar: UmpanMelayangGambar = %UmpanMelayang


func _siapkan_dunia() -> void:
	_daur.penerap = _penerap
	_rintangan_daur.penerap = _penerap
	_panel_akhir.main_lagi_diminta.connect(main_lagi)
	_susun(_benih)


func _perbarui_dunia(jarak_ubin: float) -> void:
	_daur.perbarui(jarak_ubin)
	_area_kotak.perbarui(jarak_ubin)
	_rintangan_daur.perbarui(_rintangan, jarak_ubin)
	_umpan_gambar.tampilkan(_umpan)
	_penerap.terapkan(_sepeda.posisi_dunia())
	var status: AkhirRute.Status = AkhirRute.periksa(_selesai, jarak_ubin, _rute.panjang_ubin)
	_selesai = status.selesai
	if status.baru_selesai:
		_kontrol.lepas_semua()
		_garis_bidik.sembunyikan()
		_panel_akhir.tampilkan(true)
		rute_selesai.emit()


func _zona_bantu(maju_awal_ubin: float, maju_akhir_ubin: float) -> Array[ZonaSasaran.Zona]:
	return ZonaSasaran.zona_rute_rentang(_rute.rumah, maju_awal_ubin, maju_akhir_ubin)


func _skor_aktif() -> bool:
	return true


func _rute_skor() -> RouteBuilder.Rute:
	return _rute


func _rintangan_awal() -> RintanganRute.Keadaan:
	return RintanganRute.dari_rute(_rute)


func _vektor_stick() -> Vector2:
	if _selesai:
		return AkhirRute.stick_akhir()
	return super()


func _lempar_diizinkan() -> bool:
	return not _selesai


## Menyusun ulang rute dengan seed `benih`, dan mengembalikan adegan ke awal. Pustaka segmen dimuat sekali.
func _susun(benih: int) -> void:
	_benih = benih
	_galat = []
	if _pustaka.is_empty():
		var kumpulan: PemuatRute.Kumpulan = PemuatRute.muat_folder()
		_galat.append_array(kumpulan.galat)
		_pustaka = kumpulan.segmen
	var hasil: RouteBuilder.Hasil = RouteBuilder.bangun(benih, _pustaka)
	_galat.append_array(hasil.galat)
	var gagal: bool = false
	if hasil.rute != null and _galat.is_empty():
		_rute = hasil.rute
	else:
		if lapor_galat_ke_log:
			push_error("Rute tidak bisa disusun (seed %d): %s" % [benih, "; ".join(_galat)])
		_rute = RouteBuilder.Rute.new()
		gagal = true
	_medan = MedanKoran.dari_rute(_rute)
	_selesai = false
	_daur.atur_rute(_rute)
	_area_kotak.atur_rute(_rute)
	_rintangan_daur.lepas_semua()
	_penerap.terapkan(_sepeda.posisi_dunia())
	_panel_akhir.tampilkan(false)
	if gagal:
		_panel_akhir.tampilkan_galat()
	_kembalikan_awal(_rute.koran_awal)
	rute_disusun.emit(_rute)


## Tombol dev "Main lagi" (juga dipanggil tes): seed berikutnya (seed + 1), rute baru dari awal.
func main_lagi() -> void:
	_susun(_benih + 1)
	perbarui(0.0)


## Seed rute yang sedang dimainkan.
func benih() -> int:
	return _benih


## Rute yang sedang dimainkan (rute kosong bila gagal disusun).
func rute() -> RouteBuilder.Rute:
	return _rute


## Galat memuat segmen atau menyusun rute (kosong bila baik).
func galat_rute() -> Array[String]:
	return _galat


## True sejak sepeda mencapai garis akhir sampai "Main lagi".
func rute_sudah_selesai() -> bool:
	return _selesai


## Jendela daur rumah (untuk tes dan probe).
func daur() -> RumahDaurRute:
	return _daur


## Gambar rintangan (untuk tes dan probe).
func rintangan_daur() -> RintanganDaur:
	return _rintangan_daur


## Gambar umpan balik melayang (untuk tes dan probe).
func umpan_gambar() -> UmpanMelayangGambar:
	return _umpan_gambar


## Penerap penutup pemain (untuk tes dan probe).
func penerap_penutup() -> PenerapPenutup:
	return _penerap


## Panel banner dan tombol akhir rute (untuk tes dan probe).
func panel_akhir() -> PanelAkhirRute:
	return _panel_akhir


## Medan sasaran koran rute yang sedang dimainkan (untuk tes).
func medan() -> MedanKoran:
	return _medan
