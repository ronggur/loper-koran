extends SceneTree
## Tes reproduksi QA run 20261018-fase4a-koran-hari iterasi 1 (QA-001, QA-002). TIDAK dipanggil dari `run_tests.gd`: dijalankan sendiri,
## `godot --headless --script res://tests/qa_repro_4a.gd`. Lulus di kode asli, tetapi mutan di bawah ini juga lulus di `run_tests.gd`
## (tanpa tes yang menjaganya); Dev memindahkan pemeriksaan ini ke `run_tests.gd` (mis. `tes_alur_hari.gd`) lalu berkas ini boleh dihapus.
## - QA-001: `SaveManager._ready` (autoload sungguhan) tidak boleh menulis apa pun. Mutan: `_ready` memanggil `simpan()`.
## - QA-002: Berangkat tanpa memilih Ambil/Lewati = Lewati (S-7), jadi `misi_diambil` kosong. Mutan: `!= Pilihan.LEWATI` menggantikan `== Pilihan.AMBIL`.
## I/O hanya di `user://tes_qa_4a_repro/`; `user://save.json` tidak disentuh (ada/ukuran dicek sebelum dan sesudah).

const SKRIP_SIMPAN: String = "res://scripts/autoload/save_manager.gd"
const BERKAS_HARI: String = "res://scenes/hari/hari.tscn"
const FOLDER: String = "user://tes_qa_4a_repro"

var _lolos: int = 0
var _gagal: int = 0


func _initialize() -> void:
	var asli_ada: bool = FileAccess.file_exists("user://save.json")
	var asli_ukuran: int = FileAccess.get_file_as_string("user://save.json").length() if asli_ada else -1
	_bersihkan_folder()
	DirAccess.make_dir_recursive_absolute(FOLDER)
	await _test_ready_tidak_menulis()
	await _test_berangkat_tanpa_memilih()
	_bersihkan_folder()
	var asli_ada2: bool = FileAccess.file_exists("user://save.json")
	var asli_ukuran2: int = FileAccess.get_file_as_string("user://save.json").length() if asli_ada2 else -1
	_cek(asli_ada == asli_ada2 and asli_ukuran == asli_ukuran2, "user://save.json asli tidak tersentuh")
	print("%d lolos, %d gagal" % [_lolos, _gagal])
	quit(1 if _gagal > 0 else 0)


func _cek(kondisi: bool, label: String) -> void:
	if kondisi:
		_lolos += 1
	else:
		_gagal += 1
		print("GAGAL: ", label)


func _test_ready_tidak_menulis() -> void:
	# Catatan: node yang ditambahkan ke root di dalam `_initialize` baru mendapat `_ready` sesudah satu frame, jadi tiap blok menunggu satu frame.
	# Tanpa berkas: masuk pohon (memicu _ready) tidak boleh membuat save.json atau save.tmp.
	var jalur: String = FOLDER + "/ready_kosong.json"
	var m: Node = (load(SKRIP_SIMPAN) as GDScript).new()
	m.set(&"jalur", jalur)
	m.set(&"lapor_ke_log", false)
	root.add_child(m)
	await process_frame
	_cek(not FileAccess.file_exists(jalur), "QA-001: _ready tanpa berkas save tidak membuat berkas save")
	_cek(int(m.get(&"jumlah_simpan")) == 0, "QA-001: _ready tidak memanggil simpan (jumlah_simpan = 0)")
	root.remove_child(m)
	m.free()
	# Berkas rusak: _ready tidak boleh menimpanya (hanya salinan yang boleh dibuat), isi sama byte demi byte.
	var rusak: String = FOLDER + "/ready_rusak.json"
	var f: FileAccess = FileAccess.open(rusak, FileAccess.WRITE)
	f.store_string("{bukan json")
	f.close()
	var m2: Node = (load(SKRIP_SIMPAN) as GDScript).new()
	m2.set(&"jalur", rusak)
	m2.set(&"lapor_ke_log", false)
	root.add_child(m2)
	await process_frame
	_cek(FileAccess.get_file_as_string(rusak) == "{bukan json", "QA-001: _ready tidak menimpa save rusak")
	_cek(int(m2.get(&"jumlah_simpan")) == 0, "QA-001: _ready di atas save rusak tidak memanggil simpan")
	root.remove_child(m2)
	m2.free()


func _test_berangkat_tanpa_memilih() -> void:
	root.size = Vector2i(2340, 1080)
	var m: Node = (load(SKRIP_SIMPAN) as GDScript).new()
	m.set(&"jalur", FOLDER + "/berangkat.json")
	m.set(&"lapor_ke_log", false)
	m.call(&"muat", 1700000000)
	var hari: HariMain = (load(BERKAS_HARI) as PackedScene).instantiate() as HariMain
	hari.simpanan = m
	hari.panggil_quit = false
	root.add_child(hari)
	await process_frame
	await process_frame
	_cek(hari.halaman().misi != null and hari.koran().pilihan() == HalamanKoran.Pilihan.BELUM, "QA-002 prasyarat: hari 1 punya misi dan belum ada pilihan")
	hari.koran().tombol_berangkat().ditekan.emit()
	await process_frame
	await process_frame
	_cek(hari.rute() != null, "QA-002 prasyarat: rute dibuat")
	_cek(hari.misi_diambil() == "", "QA-002: Berangkat tanpa memilih = Lewati (S-7): misi_diambil kosong, dapat '%s'" % hari.misi_diambil())
	var rute: RuteMain = hari.rute()
	if rute != null:
		rute.set_process(false)
	root.remove_child(hari)
	hari.free()
	m.free()


func _bersihkan_folder() -> void:
	var dir: DirAccess = DirAccess.open(FOLDER)
	if dir == null:
		return
	for nama: String in dir.get_files():
		dir.remove(nama)
	DirAccess.remove_absolute(FOLDER)
