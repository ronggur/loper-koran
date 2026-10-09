class_name TesExport
extends RefCounted
## Tes export Android run 0C (AC-19, AC-23): isi `export_presets.cfg`, `.gitignore`, berkas yang dilacak git,
## dan penjaga `docs/SETUP_ANDROID.md` (AC-20).
##
## Dipanggil dari `tests/run_tests.gd` (`TesExport.new(check, judul).jalankan()`), memakai `check` milik runner supaya
## hitungan lolos/gagal dan ringkasan tetap satu. Tes hanya membaca berkas teks di repo: TIDAK butuh APK, export templates,
## Java, atau Android SDK (CI tidak punya satu pun). Satu-satunya program luar adalah `git` (ada di CI dan di mesin dev).
## Setiap penjaga dibuktikan dengan contoh buruk sintetis yang harus ditolak, bukan hanya berkas asli yang lolos.

const BERKAS_PRESET: String = "res://export_presets.cfg"
const BERKAS_GITIGNORE: String = "res://.gitignore"
const BERKAS_SETUP: String = "res://docs/SETUP_ANDROID.md"
const BERKAS_README_DOCS: String = "res://docs/README.md"

## Nama package final (pilihan user 2026-10-09, ROADMAP 4b). Tidak boleh diganti: terkunci setelah upload pertama ke Play Console.
const PACKAGE_FINAL: String = "com.rmh.kring"
const NAMA_PRESET: String = "Android"
const VERSI_KODE: int = 1
const VERSI_NAMA: String = "0.1.0"
const ARSITEKTUR_AKTIF: String = "architectures/arm64-v8a"
const ARSITEKTUR_MATI: Array[String] = ["architectures/armeabi-v7a", "architectures/x86", "architectures/x86_64"]
## Folder yang tidak boleh ikut APK walau berisi skrip (tests/) atau berkas dev lain.
const FILTER_DIKECUALIKAN: Array[String] = ["docs/*", "tests/*", "tools/*", "build/*", "builds/*"]
## Potongan nama kunci yang nilainya wajib kosong di preset (rahasia tidak boleh masuk repo).
const KUNCI_RAHASIA: Array[String] = ["password", "secret", "token", "encryption_key", "salt"]
## Potongan nilai yang menandakan jalur lokal atau berkas keystore di dalam preset.
const POLA_JALUR_LOKAL: Array[String] = ["/Users/", "/home/", "C:\\", ".keystore", ".jks", ".p12"]
## Pola `.gitignore` wajib: AC-19 (builds, apk, aab, .godot) ditambah keystore dan kredensial export (AC-23).
const POLA_GITIGNORE: Array[String] = [".godot/", "build/", "builds/", "*.apk", "*.aab", "*.keystore", "*.jks", "*.p12", "export_credentials.cfg"]
## Jalur contoh yang harus diabaikan git (cek dengan `git check-ignore`).
const CONTOH_DIABAIKAN: Array[String] = [
	"builds/kring-kring-debug.apk", "build/tests.log", "uji.apk", "rilis.aab", ".godot/export_credentials.cfg",
	".godot/imported/x.ctex", "rilis.keystore", "kunci/unggah.jks", "kunci.p12", "export_credentials.cfg",
]
## Jalur sumber yang TIDAK boleh diabaikan (kontrol negatif: pola yang terlalu lebar akan menyembunyikan sumber).
const CONTOH_DILACAK: Array[String] = ["export_presets.cfg", "docs/SETUP_ANDROID.md", "scripts/config.gd", "tests/tes_export.gd", "project.godot"]
## Kata yang tidak boleh ada di panduan setup repo ini (nilai spesifik project lain atau plugin yang belum dipakai, AC-20).
const KATA_TERLARANG_SETUP: Array[String] = ["brainydungeon", "startlights", "quicksplit", "firebase", "admob", "release-please", "godot-share", "shareplugin"]
## Isi minimum panduan setup (AC-20): perintah dan istilah yang dipakai tes lain dan orchestrator.
const KATA_WAJIB_SETUP: Array[String] = [
	"com.rmh.kring", "--export-debug", "--export-pack", "java_sdk_path", "adb install -r", "pm list packages", "pm clear",
	"aapt2 dump badging", "aapt2 dump permissions", "apksigner verify", "targetSdkVersion", "cek_blok_piksel.py", "builds/",
]

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_preset_asli()
	_test_preset_contoh_buruk()
	_test_gitignore()
	_test_berkas_dilacak()
	_test_panduan_setup()


# --- AC-19: isi export_presets.cfg ---

func _test_preset_asli() -> void:
	_judul.call("Preset export Android")
	check(FileAccess.file_exists(BERKAS_PRESET), "export_presets.cfg ada di root repo (di-commit)")
	var teks: String = FileAccess.get_file_as_string(BERKAS_PRESET)
	var pelanggaran: Array[String] = _pelanggaran_preset(teks)
	check(pelanggaran.is_empty(), "export_presets.cfg memenuhi AC-19 (satu preset Android, package, landscape, arm64, tanpa Gradle, tanpa izin, tanpa keystore): %s" % "; ".join(pelanggaran))
	# Pemindai tidak boleh lolos kosong: pastikan ia benar-benar melihat daftar izin dan kunci keystore.
	var cfg: ConfigFile = ConfigFile.new()
	check(cfg.parse(teks) == OK, "export_presets.cfg bisa diurai sebagai ConfigFile")
	check(cfg.has_section("preset.0") and cfg.has_section("preset.0.options"), "ada bagian [preset.0] dan [preset.0.options]")
	var jumlah_izin: int = 0
	var jumlah_keystore: int = 0
	var kunci_opsi: PackedStringArray = PackedStringArray()
	if cfg.has_section("preset.0.options"):
		kunci_opsi = cfg.get_section_keys("preset.0.options")
	for kunci: String in kunci_opsi:
		if kunci.begins_with("permissions/") and kunci != "permissions/custom_permissions":
			jumlah_izin += 1
		if kunci.begins_with("keystore/"):
			jumlah_keystore += 1
	check(jumlah_izin >= 100, "preset mendaftar semua izin Godot secara eksplisit (permissions/*=false), dapat %d" % jumlah_izin)
	check(jumlah_keystore == 6, "preset memuat enam kolom keystore (debug/release x jalur/user/sandi), semuanya kosong, dapat %d" % jumlah_keystore)
	# Orientasi diatur di project.godot (preset Godot 4 tidak punya opsi orientasi sendiri): landscape terkunci.
	check(int(ProjectSettings.get_setting("display/window/handheld/orientation")) == DisplayServer.SCREEN_LANDSCAPE, "orientasi landscape terkunci di project.godot (display/window/handheld/orientation = 0), dipakai preset export")
	check(not ProjectSettings.has_setting("display/window/handheld/orientation_override"), "preset tidak menimpa orientasi lewat pengaturan lain")


func _test_preset_contoh_buruk() -> void:
	_judul.call("Preset export: contoh buruk sintetis ditolak")
	var asli: String = FileAccess.get_file_as_string(BERKAS_PRESET)
	# Tiap mutan: [teks lama, teks baru, potongan pesan pelanggaran yang diharapkan, label].
	var mutan: Array = [
		['package/unique_name="com.rmh.kring"', 'package/unique_name="com.rmh.loperkoran"', "package", "package diganti ke com.rmh.loperkoran"],
		['package/unique_name="com.rmh.kring"', 'package/unique_name=""', "package", "package kosong"],
		['architectures/armeabi-v7a=false', 'architectures/armeabi-v7a=true', "armeabi-v7a", "arsitektur ekstra armeabi-v7a menyala"],
		['architectures/x86_64=false', 'architectures/x86_64=true', "x86_64", "arsitektur ekstra x86_64 menyala"],
		['architectures/arm64-v8a=true', 'architectures/arm64-v8a=false', "arm64-v8a", "arm64-v8a mati"],
		['gradle_build/use_gradle_build=false', 'gradle_build/use_gradle_build=true', "gradle", "Gradle build menyala"],
		['permissions/internet=false', 'permissions/internet=true', "permissions/internet", "izin INTERNET menyala"],
		['permissions/camera=false', 'permissions/camera=true', "permissions/camera", "izin CAMERA menyala"],
		['permissions/custom_permissions=PackedStringArray()', 'permissions/custom_permissions=PackedStringArray("android.permission.CAMERA")', "custom_permissions", "izin kustom terisi"],
		['keystore/release_password=""', 'keystore/release_password="rahasia"', "keystore/release_password", "kata sandi keystore rilis terisi"],
		['keystore/debug_password=""', 'keystore/debug_password="android"', "keystore/debug_password", "kata sandi keystore debug terisi"],
		['keystore/release=""', 'keystore/release="/Users/dev/kunci/rilis.keystore"', "keystore/release", "jalur keystore rilis terisi"],
		['keystore/release_user=""', 'keystore/release_user="unggah"', "keystore/release_user", "nama kunci rilis terisi"],
		['name="Android"', 'name="Android uji"', "nama", "nama preset bukan Android"],
		['runnable=true', 'runnable=false', "runnable", "runnable mati"],
		['version/code=1', 'version/code=2', "version/code", "version/code bukan 1"],
		['version/name="0.1.0"', 'version/name="1.0.0"', "version/name", "version/name bukan 0.1.0"],
		['screen/immersive_mode=true', 'screen/immersive_mode=false', "imersif", "mode imersif mati"],
		['user_data_backup/allow=false', 'user_data_backup/allow=true', "user_data_backup", "cadangan data pengguna menyala"],
		['tests/*, ', '', "tests/*", "tests/ tidak dikecualikan dari APK"],
		['exclude_filter="docs/*, tests/*, tools/*, build/*, builds/*"', 'exclude_filter=""', "exclude_filter", "filter pengecualian kosong"],
		['export_path=""', 'export_path="/Users/dev/builds/kring.apk"', "export_path", "jalur ekspor lokal"],
		['custom_template/debug=""', 'custom_template/debug="/Users/dev/templat/android_debug.apk"', "custom_template", "template kustom lokal"],
		['seed=0', 'seed=0\nscript_encryption_key="0123456789abcdef"', "encryption_key", "kunci enkripsi skrip terisi"],
	]
	var ditolak: int = 0
	for baris: Array in mutan:
		var dari: String = baris[0]
		var ke: String = baris[1]
		var potongan: String = baris[2]
		var label: String = baris[3]
		check(asli.contains(dari), "contoh buruk '%s': teks asal ditemukan di export_presets.cfg (mutan nyata, bukan no-op)" % label)
		var pelanggaran: Array[String] = _pelanggaran_preset(asli.replace(dari, ke))
		var cocok: bool = false
		for p: String in pelanggaran:
			if p.contains(potongan):
				cocok = true
		check(cocok, "contoh buruk ditolak: %s (pelanggaran memuat '%s'), dapat %s" % [label, potongan, pelanggaran])
		if cocok:
			ditolak += 1
	check(ditolak == mutan.size(), "semua %d contoh buruk ditolak, %d ditolak" % [mutan.size(), ditolak])
	# Struktur: nol preset, preset ganda. (Berkas yang tidak bisa diurai tidak dites: ConfigFile mencetak ERROR: ke keluaran,
	# yang memang ditolak pemeriksa keluaran tes.)
	check(not _pelanggaran_preset("").is_empty(), "berkas tanpa preset ditolak")
	var ganda: String = asli + '\n[preset.1]\n\nname="Web"\nplatform="Web"\nrunnable=false\n\n[preset.1.options]\n\n'
	var p_ganda: Array[String] = _pelanggaran_preset(ganda)
	check(not p_ganda.is_empty() and "; ".join(p_ganda).contains("satu preset"), "dua preset ditolak (harus tepat satu), dapat %s" % [p_ganda])
	# Bagian opsi hilang sama sekali.
	var tanpa_opsi: String = '[preset.0]\n\nname="Android"\nplatform="Android"\nrunnable=true\n'
	check(not _pelanggaran_preset(tanpa_opsi).is_empty(), "preset tanpa [preset.0.options] ditolak")
	# Kontrol positif: berkas asli tidak dimutasi tetap bersih (pemindai tidak menolak semuanya).
	check(_pelanggaran_preset(asli).is_empty(), "berkas asli tanpa mutasi tetap diterima (kontrol positif)")


## Semua pelanggaran AC-19 pada isi sebuah `export_presets.cfg`. Daftar kosong = bersih.
func _pelanggaran_preset(teks: String) -> Array[String]:
	var hasil: Array[String] = []
	var cfg: ConfigFile = ConfigFile.new()
	var galat: int = cfg.parse(teks)
	if galat != OK:
		hasil.append("berkas tidak bisa diurai (kode galat %d)" % galat)
		return hasil
	var induk: Array[String] = []
	for bagian: String in cfg.get_sections():
		if bagian.begins_with("preset.") and not bagian.ends_with(".options"):
			induk.append(bagian)
	if induk.size() != 1:
		hasil.append("harus tepat satu preset, dapat %d" % induk.size())
		return hasil
	var kepala: String = induk[0]
	var opsi: String = kepala + ".options"
	if not cfg.has_section(opsi):
		hasil.append("bagian %s tidak ada" % opsi)
		return hasil
	# Kepala preset.
	if cfg.get_value(kepala, "name", null) != NAMA_PRESET:
		hasil.append("nama preset harus '%s'" % NAMA_PRESET)
	if cfg.get_value(kepala, "platform", null) != "Android":
		hasil.append("platform preset harus Android")
	if cfg.get_value(kepala, "runnable", null) != true:
		hasil.append("runnable harus true")
	var kecuali: Array[String] = []
	for bagian_filter: String in str(cfg.get_value(kepala, "exclude_filter", "")).split(","):
		kecuali.append(bagian_filter.strip_edges())
	for wajib: String in FILTER_DIKECUALIKAN:
		if not kecuali.has(wajib):
			hasil.append("exclude_filter harus memuat %s (tidak ikut APK)" % wajib)
	if str(cfg.get_value(kepala, "export_path", "")) != "":
		hasil.append("export_path harus kosong (jalur ekspor lokal tidak di-commit)")
	# Opsi Android.
	if cfg.get_value(opsi, "package/unique_name", null) != PACKAGE_FINAL:
		hasil.append("package/unique_name harus %s" % PACKAGE_FINAL)
	if cfg.get_value(opsi, "screen/immersive_mode", null) != true:
		hasil.append("screen/immersive_mode harus true (imersif)")
	if cfg.get_value(opsi, "gradle_build/use_gradle_build", null) != false:
		hasil.append("gradle_build/use_gradle_build harus false (tanpa Gradle, SPEC D-8)")
	if cfg.get_value(opsi, ARSITEKTUR_AKTIF, null) != true:
		hasil.append("%s harus true" % ARSITEKTUR_AKTIF)
	for arsitektur: String in ARSITEKTUR_MATI:
		if cfg.get_value(opsi, arsitektur, null) != false:
			hasil.append("%s harus ada dan false (arm64-v8a saja)" % arsitektur)
	if cfg.get_value(opsi, "version/code", null) != VERSI_KODE:
		hasil.append("version/code harus %d" % VERSI_KODE)
	if cfg.get_value(opsi, "version/name", null) != VERSI_NAMA:
		hasil.append("version/name harus %s" % VERSI_NAMA)
	# allowBackup: usulan awal mati, karena belum ada save yang layak dicadangkan (SETUP_ANDROID bagian preset).
	if cfg.get_value(opsi, "user_data_backup/allow", null) != false:
		hasil.append("user_data_backup/allow harus false (usulan awal, SETUP_ANDROID)")
	for template_kunci: String in ["custom_template/debug", "custom_template/release"]:
		if str(cfg.get_value(opsi, template_kunci, "")) != "":
			hasil.append("%s harus kosong (jalur template lokal tidak di-commit)" % template_kunci)
	# Izin: tidak ada yang menyala, tidak ada izin kustom.
	var izin_kustom: Variant = cfg.get_value(opsi, "permissions/custom_permissions", null)
	var izin_kustom_kosong: bool = false
	if izin_kustom is PackedStringArray:
		var daftar_izin: PackedStringArray = izin_kustom
		izin_kustom_kosong = daftar_izin.is_empty()
	if not izin_kustom_kosong:
		hasil.append("permissions/custom_permissions harus PackedStringArray() kosong")
	for kunci: String in cfg.get_section_keys(opsi):
		if kunci.begins_with("permissions/") and kunci != "permissions/custom_permissions":
			if cfg.get_value(opsi, kunci) != false:
				hasil.append("izin menyala: %s" % kunci)
		if kunci.begins_with("architectures/") and kunci != ARSITEKTUR_AKTIF and cfg.get_value(opsi, kunci) != false:
			hasil.append("arsitektur ekstra menyala: %s" % kunci)
		# Keystore: jalur, nama kunci, dan kata sandi semuanya kosong (keystore rilis di luar folder project).
		if kunci.begins_with("keystore/") and str(cfg.get_value(opsi, kunci)) != "":
			hasil.append("keystore terisi: %s" % kunci)
	# Rahasia dan jalur lokal di bagian mana pun.
	for bagian: String in cfg.get_sections():
		for kunci: String in cfg.get_section_keys(bagian):
			var nilai: Variant = cfg.get_value(bagian, kunci)
			if not (nilai is String):
				continue
			var isi: String = nilai
			if isi == "":
				continue
			for potongan: String in KUNCI_RAHASIA:
				if kunci.to_lower().contains(potongan):
					hasil.append("kolom rahasia terisi: %s/%s" % [bagian, kunci])
			for pola: String in POLA_JALUR_LOKAL:
				if isi.contains(pola):
					hasil.append("jalur lokal atau keystore di %s/%s" % [bagian, kunci])
	return hasil


# --- AC-19, AC-23: .gitignore ---

func _test_gitignore() -> void:
	_judul.call("Kebersihan repo: .gitignore")
	var teks: String = FileAccess.get_file_as_string(BERKAS_GITIGNORE)
	var hilang: Array[String] = _pola_hilang(teks)
	check(hilang.is_empty(), ".gitignore menutup builds/, build/, *.apk, *.aab, .godot/, *.keystore, *.jks, *.p12, export_credentials.cfg; hilang: %s" % [hilang])
	# Penjaga harus menangkap .gitignore yang bolong.
	check(_pola_hilang("build/\n*.apk\n").size() == POLA_GITIGNORE.size() - 2, ".gitignore tanpa builds/, *.aab, .godot/, keystore, dst. dikenali bolong")
	check(_pola_hilang(teks.replace("builds/\n", "")).has("builds/"), ".gitignore tanpa baris builds/ ditolak (mutan)")
	check(_pola_hilang(teks.replace("*.aab\n", "")).has("*.aab"), ".gitignore tanpa baris *.aab ditolak (mutan)")
	# Bukti sesungguhnya: git sendiri yang bilang jalur itu diabaikan, dan sumber tetap dilacak.
	var akar: String = ProjectSettings.globalize_path("res://")
	for jalur: String in CONTOH_DIABAIKAN:
		var kode: int = _git_ignore(akar, jalur)
		check(kode == 0, "git check-ignore: %s diabaikan (kode %d; 0 = diabaikan, 1 = tidak, -1 = git tidak jalan)" % [jalur, kode])
	for jalur: String in CONTOH_DILACAK:
		var kode: int = _git_ignore(akar, jalur)
		check(kode == 1, "git check-ignore: %s TIDAK diabaikan (kontrol negatif, kode %d)" % [jalur, kode])


## Pola wajib yang tidak ada sebagai baris utuh di isi `.gitignore`.
func _pola_hilang(teks: String) -> Array[String]:
	var hasil: Array[String] = []
	var baris: PackedStringArray = teks.split("\n")
	for pola: String in POLA_GITIGNORE:
		if not baris.has(pola):
			hasil.append(pola)
	return hasil


## Kode keluar `git check-ignore -q`: 0 diabaikan, 1 tidak diabaikan, 128 galat git, -1 git tidak bisa dijalankan.
func _git_ignore(akar: String, jalur: String) -> int:
	var keluaran: Array = []
	return OS.execute("git", ["-C", akar, "check-ignore", "-q", "--", jalur], keluaran, true)


# --- AC-23: berkas yang dilacak git ---

func _test_berkas_dilacak() -> void:
	_judul.call("Kebersihan repo: berkas yang dilacak git")
	var akar: String = ProjectSettings.globalize_path("res://")
	var keluaran: Array = []
	var kode: int = OS.execute("git", ["-C", akar, "ls-files"], keluaran, true)
	check(kode == 0 and keluaran.size() == 1, "git ls-files berjalan (kode %d)" % kode)
	if kode == 0 and keluaran.size() == 1:
		var dilacak: PackedStringArray = str(keluaran[0]).split("\n", false)
		check(dilacak.size() > 100, "git ls-files mengembalikan daftar berkas repo (%d berkas)" % dilacak.size())
		var terlarang: Array[String] = _berkas_terlarang(dilacak)
		check(terlarang.is_empty(), "tidak ada keystore, kredensial export, APK/AAB, .godot/, build/, builds/ yang dilacak git: %s" % [terlarang])
		check(dilacak.has("export_presets.cfg"), "export_presets.cfg dilacak git (preset di-commit, tanpa rahasia)")
	# Penjaga harus menangkap tiap jenis berkas terlarang.
	var buruk: PackedStringArray = PackedStringArray([
		"builds/kring.apk", "uji.apk", "rilis.aab", "kunci/rilis.keystore", "unggah.jks", "x/kunci.p12",
		"export_credentials.cfg", ".godot/export_credentials.cfg", ".godot/imported/a.ctex", "build/tests.log", "builds/a.txt",
	])
	for jalur: String in buruk:
		check(not _berkas_terlarang(PackedStringArray([jalur])).is_empty(), "berkas terlarang ditolak: %s" % jalur)
	var baik: PackedStringArray = PackedStringArray(["export_presets.cfg", "docs/SETUP_ANDROID.md", "scripts/config.gd", "assets/sprites/loper/loper_agen.png.import", "tools/build_helper.py", "docs/builds.md"])
	check(_berkas_terlarang(baik).is_empty(), "berkas sumber biasa (termasuk nama yang mirip, tools/build_helper.py) diterima")


## Jalur dari `git ls-files` yang tidak boleh pernah dilacak (git-workflow, privacy-ads).
func _berkas_terlarang(daftar: PackedStringArray) -> Array[String]:
	var hasil: Array[String] = []
	for jalur: String in daftar:
		var nama: String = jalur.get_file()
		var ekstensi: String = jalur.get_extension().to_lower()
		if ["keystore", "jks", "p12", "apk", "aab"].has(ekstensi):
			hasil.append(jalur)
		elif nama == "export_credentials.cfg":
			hasil.append(jalur)
		elif jalur.begins_with(".godot/") or jalur.begins_with("build/") or jalur.begins_with("builds/"):
			hasil.append(jalur)
	return hasil


# --- AC-20: panduan setup ---

func _test_panduan_setup() -> void:
	_judul.call("Panduan setup Android")
	check(FileAccess.file_exists(BERKAS_SETUP), "docs/SETUP_ANDROID.md ada")
	var teks: String = FileAccess.get_file_as_string(BERKAS_SETUP)
	var terlarang: Array[String] = _kata_terlarang(teks)
	check(terlarang.is_empty(), "SETUP_ANDROID.md tidak memuat nilai project lain (package, plugin, keystore, release-please): %s" % [terlarang])
	var hilang: Array[String] = _kata_hilang(teks)
	check(hilang.is_empty(), "SETUP_ANDROID.md memuat perintah dan istilah wajib (AC-20); hilang: %s" % [hilang])
	check(FileAccess.get_file_as_string(BERKAS_README_DOCS).contains("SETUP_ANDROID.md"), "docs/README.md mendaftarkan SETUP_ANDROID.md di tabel dokumen")
	# Penjaga harus menangkap contoh buruk.
	check(_kata_terlarang("package com.rmh.brainydungeon di HP").has("brainydungeon"), "package project lain (brainydungeon) ditolak")
	check(_kata_terlarang("Plugin AdMob dan Firebase").size() == 2, "plugin iklan dan analytics yang belum dipakai ditolak (huruf besar tetap dikenali)")
	check(_kata_terlarang("workflow release-please.yml").has("release-please"), "release-please ditolak")
	check(_kata_terlarang("diadaptasi dari panduan Brainy Dungeon").is_empty(), "menyebut nama Brainy Dungeon sebagai sumber adaptasi (dengan spasi) diizinkan")
	check(_kata_hilang("dokumen kosong").size() == KATA_WAJIB_SETUP.size(), "dokumen kosong kehilangan semua istilah wajib")
	check(not _kata_hilang(teks.replace("pm clear", "")).is_empty(), "panduan tanpa peringatan pm clear ditolak (mutan)")


## Kata terlarang (tanpa memandang huruf besar-kecil) yang ada di `teks`.
func _kata_terlarang(teks: String) -> Array[String]:
	var hasil: Array[String] = []
	var kecil: String = teks.to_lower()
	for kata: String in KATA_TERLARANG_SETUP:
		if kecil.contains(kata):
			hasil.append(kata)
	return hasil


## Istilah wajib yang tidak ada di `teks`.
func _kata_hilang(teks: String) -> Array[String]:
	var hasil: Array[String] = []
	for kata: String in KATA_WAJIB_SETUP:
		if not teks.contains(kata):
			hasil.append(kata)
	return hasil
