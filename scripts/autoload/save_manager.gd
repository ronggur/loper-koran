extends Node
## Autoload `SaveManager` (TECH_PLAN 3.1, DATA_SCHEMA 4, rule `save-system`; AC-7 sampai AC-9, AC-14 run fase4a-koran-hari, usulan): satu
## Dictionary state (`DataSave.templat`) yang dibaca dari `user://save.json` dan ditulis ATOMIK (ke berkas sementara `save.tmp` di folder
## yang sama, diperiksa terbaca, lalu di-rename; berkas lama utuh bila langkah mana pun gagal). Semua aturan format ada di `DataSave`.
##
## - `muat`: tidak ada berkas = state bawaan tanpa notifikasi; berkas rusak atau versinya lebih baru (`DataSave.Status`) tidak ditimpa
##   diam-diam: disalin dulu ke `<jalur tanpa ekstensi>.corrupt.<detik unix>.json` (di `user://`: `save.corrupt.<detik>.json`), state
##   bawaan dipakai, dan `ambil_notifikasi_rusak` mengembalikan true SEKALI supaya layar koran memberi tahu pemain satu baris netral.
## - `simpan`: dipanggil tepat sekali per hari, saat "Hari berikutnya" (`akhiri_hari`); tidak ada simpan di layar koran, jeda, background,
##   hasil terbuka, atau rute yang ditutup (simpan hanya di akhir hari). `jumlah_simpan` mencatat pemanggilan untuk tes.
## - `jalur` bisa disuntik (tes memakai jalur sementara dan TIDAK PERNAH menyentuh `user://save.json`).
## Tidak merujuk autoload lain (rule `gdscript`); diuji tanpa scene tree (`load(...).new()` lalu `free()`).

## Save selesai ditulis (hanya bila berhasil).
signal disimpan

## Jalur berkas save; disuntik tes.
var jalur: String = Config.SAVE_BERKAS
## State save (Dictionary hasil `DataSave`); diganti utuh tiap `akhiri_hari`.
var state: Dictionary = DataSave.templat()
## Hasil `muat` terakhir.
var status_muat: DataSave.Status = DataSave.Status.BARU
## Jalur salinan berkas rusak yang dibuat `muat` ("" bila tidak ada).
var jalur_salinan_rusak: String = ""
## Berapa kali `simpan` dipanggil (berhasil atau gagal), untuk tes "simpan hanya di akhir hari".
var jumlah_simpan: int = 0
## False hanya di tes yang sengaja memicu galat: galat dan peringatan tidak dicetak ke log (pemeriksa keluaran tes menolak baris `ERROR:`).
var lapor_ke_log: bool = true

var _notifikasi_rusak: bool = false


func _ready() -> void:
	muat()


## Membaca berkas save ke `state`. `detik_unix` (-1 = waktu sistem) hanya dipakai menamai salinan berkas rusak.
func muat(detik_unix: int = -1) -> void:
	state = DataSave.templat()
	jalur_salinan_rusak = ""
	_notifikasi_rusak = false
	if not FileAccess.file_exists(jalur):
		status_muat = DataSave.Status.BARU
		return
	var hasil: DataSave.Hasil = DataSave.dari_teks(FileAccess.get_file_as_string(jalur))
	status_muat = hasil.status
	state = hasil.state
	if hasil.perlu_salinan():
		var waktu: int = detik_unix if detik_unix >= 0 else int(Time.get_unix_time_from_system())
		jalur_salinan_rusak = _salin_rusak(waktu)
		_notifikasi_rusak = true
		_lapor("Save tidak terbaca (%s); disalin ke '%s', memakai state bawaan" % [hasil.alasan, jalur_salinan_rusak], false)


## True SEKALI sesudah `muat` menemukan save rusak (lalu false), untuk satu baris notifikasi di layar koran.
func ambil_notifikasi_rusak() -> bool:
	var nilai: bool = _notifikasi_rusak
	_notifikasi_rusak = false
	return nilai


## Menulis `state` secara atomik. True bila berkas baru sudah di tempatnya; false (dan berkas lama utuh) bila gagal.
func simpan() -> bool:
	jumlah_simpan += 1
	var sementara: String = jalur.get_basename() + "." + Config.SAVE_SEMENTARA_EKSTENSI
	var teks: String = DataSave.ke_teks(state)
	DirAccess.make_dir_recursive_absolute(jalur.get_base_dir())
	var berkas: FileAccess = FileAccess.open(sementara, FileAccess.WRITE)
	if berkas == null:
		_lapor("Save tidak bisa ditulis ke '%s' (kode %d)" % [sementara, FileAccess.get_open_error()], true)
		return false
	berkas.store_string(teks)
	berkas.close()
	if FileAccess.get_file_as_string(sementara) != teks:
		_lapor("Berkas sementara save '%s' tidak sama dengan yang ditulis; berkas lama dibiarkan" % sementara, true)
		DirAccess.remove_absolute(sementara)
		return false
	if DirAccess.rename_absolute(sementara, jalur) != OK:
		_lapor("Save tidak bisa dipindah dari '%s' ke '%s'; berkas lama dibiarkan" % [sementara, jalur], true)
		return false
	disimpan.emit()
	return true


## Mencatat satu hari yang selesai (`DataSave.catat_hari`) lalu menyimpannya: SATU-SATUNYA jalan simpan di alur hari (AC-14).
func akhiri_hari(catatan: DataSave.CatatanHari) -> bool:
	state = DataSave.catat_hari(state, catatan)
	return simpan()


## Hari yang akan dimainkan berikutnya.
func hari() -> int:
	return int(state["hari"])


## Flag yang aktif.
func flag() -> Array[String]:
	return DataSave.daftar_flag(state)


## Pengaturan (kidal, mode_bantu, suara, musik): salinan.
func pengaturan() -> Dictionary:
	var nilai: Dictionary = state["pengaturan"]
	return nilai.duplicate(true)


## Menyalin berkas save yang tidak terbaca ke nama baru (tidak menimpa salinan lain: ditambah nomor bila nama sudah ada). "" bila gagal.
func _salin_rusak(detik_unix: int) -> String:
	var dasar: String = jalur.get_basename() + Config.SAVE_RUSAK_PENANDA + str(detik_unix)
	var tujuan: String = dasar + "." + jalur.get_extension()
	var nomor: int = 1
	while FileAccess.file_exists(tujuan):
		nomor += 1
		tujuan = "%s_%d.%s" % [dasar, nomor, jalur.get_extension()]
	if DirAccess.copy_absolute(jalur, tujuan) != OK:
		_lapor("Salinan save rusak ke '%s' gagal" % tujuan, true)
		return ""
	return tujuan


## Mencatat galat (`galat` true) atau peringatan ke log developer, kecuali dimatikan tes.
func _lapor(pesan: String, galat: bool) -> void:
	if not lapor_ke_log:
		return
	if galat:
		push_error(pesan)
	else:
		push_warning(pesan)
