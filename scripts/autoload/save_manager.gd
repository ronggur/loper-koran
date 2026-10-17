extends Node
## Autoload `SaveManager` (TECH_PLAN 3.1, DATA_SCHEMA 4, rule `save-system`; AC-7 sampai AC-9, AC-14 run fase4a-koran-hari, usulan): satu
## Dictionary state (`DataSave.templat`) yang dibaca dari `user://save.json` dan ditulis ATOMIK (ke berkas sementara `save.tmp` di folder
## yang sama, diperiksa terbaca, lalu di-rename; berkas lama utuh bila langkah mana pun gagal). Semua aturan format ada di `DataSave`.
##
## - `muat`: tidak ada berkas = state bawaan tanpa notifikasi. Berkas rusak atau versinya lebih baru (`DataSave.Status`) tidak ditimpa
##   diam-diam: disalin dulu ke `<jalur tanpa ekstensi>.corrupt.<detik unix>.json` (di `user://`: `save.corrupt.<detik>.json`; isi yang sama
##   dengan salinan yang sudah ada tidak disalin lagi, jadi peluncuran berulang tidak menumpuk salinan), state bawaan dipakai, dan
##   `ambil_notifikasi` mengembalikan kunci `KORAN_SAVE_RUSAK` SEKALI. Berkas yang ADA tetapi tidak bisa dibuka (izin, galat I/O), atau
##   berkas rusak yang salinannya gagal dibuat, TIDAK PERNAH ditimpa: `simpan` ditahan sepanjang sesi (mengembalikan false, berkas lama
##   utuh), dan notifikasinya `KORAN_SAVE_TIDAK_TERBACA` (teks jujur: tidak mengaku menyimpan salinan).
## - `simpan`: dipanggil tepat sekali per hari, saat "Hari berikutnya" (`akhiri_hari`); tidak ada simpan di layar koran, jeda, background,
##   hasil terbuka, atau rute yang ditutup (simpan hanya di akhir hari). `jumlah_simpan` mencatat pemanggilan untuk tes. `_ready` HANYA
##   memanggil `muat` (tidak pernah menulis; dijaga tes yang memasang node ini ke pohon dan oleh tes yang memeriksa autoload asli).
## - `jalur` bisa disuntik (tes memakai jalur sementara dan TIDAK PERNAH menyentuh `user://save.json`); `baca_balik` bisa disuntik
##   (tes memaksa berkas sementara terbaca beda).
## - Catatan tes: autoload asli ikut dibuat di setiap `godot --headless --script`, jadi `_ready` asli memuat `user://save.json` milik mesin
##   itu bila ada. Ia tidak menulis; bila berkas itu rusak, `muat` menyalinnya sekali ke `save.corrupt.<detik>.json` (salinan yang sama tidak
##   dibuat dua kali) dan tidak bisa dihindari tanpa mengubah perilaku `muat` hanya untuk tes, jadi cukup dicatat di sini.
## Tidak merujuk autoload lain (rule `gdscript`); diuji tanpa scene tree (`load(...).new()` lalu `free()`) dan di pohon (`_ready`).

## Save selesai ditulis (hanya bila berhasil).
signal disimpan

## Kunci terjemahan notifikasi layar koran (teks di `translations/ui.csv`).
const KUNCI_RUSAK: String = "KORAN_SAVE_RUSAK"
const KUNCI_TIDAK_TERBACA: String = "KORAN_SAVE_TIDAK_TERBACA"

## Jalur berkas save; disuntik tes.
var jalur: String = Config.SAVE_BERKAS
## State save (Dictionary hasil `DataSave`); diganti utuh tiap `akhiri_hari`.
var state: Dictionary = DataSave.templat()
## Hasil `muat` terakhir.
var status_muat: DataSave.Status = DataSave.Status.BARU
## Jalur salinan berkas rusak yang dipakai `muat` ("" bila tidak ada atau gagal dibuat).
var jalur_salinan_rusak: String = ""
## Berapa kali `simpan` dipanggil (berhasil atau gagal), untuk tes "simpan hanya di akhir hari".
var jumlah_simpan: int = 0
## False hanya di tes yang sengaja memicu galat: galat dan peringatan tidak dicetak ke log (pemeriksa keluaran tes menolak baris `ERROR:`).
var lapor_ke_log: bool = true
## Pembaca berkas sementara untuk pemeriksaan baca-balik (menerima jalur, mengembalikan isi). Tidak valid = `FileAccess.get_file_as_string`.
## Disuntik tes supaya cabang "berkas sementara tidak sama dengan yang ditulis" bisa dijalankan.
var baca_balik: Callable = Callable()

var _notifikasi: String = ""
## True bila berkas lama ada tetapi tidak aman ditimpa (tidak terbaca, atau salinannya gagal): `simpan` menolak sampai `muat` berikutnya.
var _simpan_ditahan: bool = false


func _ready() -> void:
	muat()


## Membaca berkas save ke `state`. `detik_unix` (-1 = waktu sistem) hanya dipakai menamai salinan berkas rusak.
func muat(detik_unix: int = -1) -> void:
	state = DataSave.templat()
	jalur_salinan_rusak = ""
	_notifikasi = ""
	_simpan_ditahan = false
	if not FileAccess.file_exists(jalur):
		status_muat = DataSave.Status.BARU
		return
	var berkas: FileAccess = FileAccess.open(jalur, FileAccess.READ)
	if berkas == null:
		# Ada tetapi tidak bisa dibuka: BUKAN berkas kosong. Jangan dianggap rusak lalu ditimpa (progres bisa hilang karena galat I/O sesaat).
		status_muat = DataSave.Status.TIDAK_TERBACA
		_simpan_ditahan = true
		_notifikasi = KUNCI_TIDAK_TERBACA
		_lapor("Save '%s' ada tetapi tidak bisa dibuka (kode %d); tidak ditimpa, simpan ditahan sampai game dibuka lagi" % [jalur, FileAccess.get_open_error()], true)
		return
	var isi: PackedByteArray = berkas.get_buffer(berkas.get_length())
	berkas.close()
	var hasil: DataSave.Hasil = DataSave.dari_teks(isi.get_string_from_utf8())
	status_muat = hasil.status
	state = hasil.state
	if hasil.perlu_salinan():
		var waktu: int = detik_unix if detik_unix >= 0 else int(Time.get_unix_time_from_system())
		jalur_salinan_rusak = _salin_rusak(waktu, isi)
		if jalur_salinan_rusak.is_empty():
			# Salinan gagal: berkas lama satu-satunya yang tersisa, jadi jangan ditimpa.
			_simpan_ditahan = true
			_notifikasi = KUNCI_TIDAK_TERBACA
			_lapor("Save tidak terbaca (%s) dan salinannya gagal dibuat; tidak ditimpa, simpan ditahan sampai game dibuka lagi" % hasil.alasan, true)
		else:
			_notifikasi = KUNCI_RUSAK
			_lapor("Save tidak terbaca (%s); disalin ke '%s', memakai state bawaan" % [hasil.alasan, jalur_salinan_rusak], false)


## Kunci notifikasi layar koran SEKALI sesudah `muat` menemukan masalah pada save (lalu ""): `KORAN_SAVE_RUSAK` (disalin lalu mulai dari
## awal) atau `KORAN_SAVE_TIDAK_TERBACA` (tidak terbaca atau tidak bisa disalin; berkas lama tidak ditimpa dan simpan ditahan).
func ambil_notifikasi() -> String:
	var nilai: String = _notifikasi
	_notifikasi = ""
	return nilai


## True bila `simpan` ditolak untuk sesi ini karena berkas lama tidak aman ditimpa.
func simpan_ditahan() -> bool:
	return _simpan_ditahan


## Menulis `state` secara atomik. True bila berkas baru sudah di tempatnya; false (dan berkas lama utuh) bila gagal atau ditahan.
func simpan() -> bool:
	jumlah_simpan += 1
	if _simpan_ditahan:
		_lapor("Simpan ditolak: save lama '%s' tidak terbaca atau tidak bisa disalin, jadi tidak boleh ditimpa" % jalur, true)
		return false
	var sementara: String = jalur.get_basename() + "." + Config.SAVE_SEMENTARA_EKSTENSI
	var teks: String = DataSave.ke_teks(state)
	DirAccess.make_dir_recursive_absolute(jalur.get_base_dir())
	var berkas: FileAccess = FileAccess.open(sementara, FileAccess.WRITE)
	if berkas == null:
		_lapor("Save tidak bisa ditulis ke '%s' (kode %d)" % [sementara, FileAccess.get_open_error()], true)
		return false
	berkas.store_string(teks)
	berkas.close()
	var terbaca: String = baca_balik.call(sementara) if baca_balik.is_valid() else FileAccess.get_file_as_string(sementara)
	if terbaca != teks:
		_lapor("Berkas sementara save '%s' tidak sama dengan yang ditulis; berkas lama dibiarkan" % sementara, true)
		DirAccess.remove_absolute(sementara)
		return false
	if DirAccess.rename_absolute(sementara, jalur) != OK:
		_lapor("Save tidak bisa dipindah dari '%s' ke '%s'; berkas lama dibiarkan" % [sementara, jalur], true)
		DirAccess.remove_absolute(sementara)
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


## Salinan berkas save yang tidak terbaca (`isi` = byte yang sudah dibaca): bila isinya sama dengan salinan `<nama>.corrupt.*` yang sudah ada, salinan itu dipakai (tidak
## menumpuk tiap peluncuran); selain itu disalin ke nama baru (tidak menimpa salinan lain: ditambah nomor bila nama sudah ada). "" bila gagal.
func _salin_rusak(detik_unix: int, isi: PackedByteArray) -> String:
	var ada: String = _salinan_sama()
	if not ada.is_empty():
		return ada
	var dasar: String = jalur.get_basename() + Config.SAVE_RUSAK_PENANDA + str(detik_unix)
	var tujuan: String = dasar + "." + jalur.get_extension()
	var nomor: int = 1
	while FileAccess.file_exists(tujuan):
		nomor += 1
		tujuan = "%s_%d.%s" % [dasar, nomor, jalur.get_extension()]
	# Ditulis sendiri (bukan `DirAccess.copy_absolute`, yang mencetak ERROR mesin saat gagal) dan dicocokkan sidiknya dengan aslinya.
	var salinan: FileAccess = FileAccess.open(tujuan, FileAccess.WRITE)
	if salinan == null:
		_lapor("Salinan save rusak ke '%s' gagal (kode %d)" % [tujuan, FileAccess.get_open_error()], true)
		return ""
	salinan.store_buffer(isi)
	salinan.close()
	if FileAccess.get_sha256(tujuan) != FileAccess.get_sha256(jalur):
		_lapor("Salinan save rusak ke '%s' tidak sama dengan aslinya; dibuang" % tujuan, true)
		DirAccess.remove_absolute(tujuan)
		return ""
	return tujuan


## Jalur salinan rusak yang sudah ada dan isinya sama dengan `jalur` (sidik sha256), "" bila tidak ada.
func _salinan_sama() -> String:
	var folder: String = jalur.get_base_dir()
	var awalan: String = jalur.get_file().get_basename() + Config.SAVE_RUSAK_PENANDA
	var akhiran: String = "." + jalur.get_extension()
	var sidik: String = FileAccess.get_sha256(jalur)
	if sidik.is_empty():
		return ""
	var dir: DirAccess = DirAccess.open(folder)
	if dir == null:
		return ""
	var nama_berkas: PackedStringArray = dir.get_files()
	nama_berkas.sort()
	for nama: String in nama_berkas:
		if nama.begins_with(awalan) and nama.ends_with(akhiran) and FileAccess.get_sha256(folder.path_join(nama)) == sidik:
			return folder.path_join(nama)
	return ""


## Mencatat galat (`galat` true) atau peringatan ke log developer, kecuali dimatikan tes.
func _lapor(pesan: String, galat: bool) -> void:
	if not lapor_ke_log:
		return
	if galat:
		push_error(pesan)
	else:
		push_warning(pesan)
