extends SceneTree
## Tes reproduksi QA run fase3a-rute (iterasi 1), dijalankan sendiri: `godot --headless --path . --script res://tests/qa_repro_rute.gd`.
## Bukan bagian `run_tests.gd`. Tiap `CEK` mencetak LOLOS atau GAGAL; keluar dengan kode 1 bila ada yang gagal.
##
## R1: pilihan pelanggan bergantung pada seed walau urutan segmen sama (menangkap mutan "goyangan nol", QA-001).
## R2: ketukan sentuh sungguhan pada tombol "Main lagi" menyusun ulang rute dengan seed berikutnya (jalur `TombolSentuh`).
## R3: semua 9 segmen termuat dan 400 seed membangun rute sah; pelanggan tidak pernah di sisi dekat; panjang rute dalam 200 sampai 300.

var _gagal: int = 0


func _cek(kondisi: bool, label: String) -> void:
	if kondisi:
		print("LOLOS: ", label)
	else:
		_gagal += 1
		print("GAGAL: ", label)


func _initialize() -> void:
	_r1_r3()
	await _r2()
	await ProbeKeluar.keluar(self, 1 if _gagal > 0 else 0)


func _r1_r3() -> void:
	var kumpulan: PemuatRute.Kumpulan = PemuatRute.muat_folder()
	_cek(kumpulan.galat.is_empty() and kumpulan.segmen.size() == 9, "R3 sembilan segmen termuat tanpa galat")
	var per_urutan: Dictionary = {}
	var rute_sah: int = 0
	var pelanggan_dekat: int = 0
	var panjang_luar: int = 0
	for benih: int in range(1000, 1400):
		var hasil: RouteBuilder.Hasil = RouteBuilder.bangun(benih, kumpulan.segmen)
		if not hasil.sah():
			continue
		rute_sah += 1
		var r: RouteBuilder.Rute = hasil.rute
		var kunci: String = ""
		for s: SegmenRute in r.segmen:
			kunci += s.id + ","
		var ids: String = ""
		for p: RouteBuilder.RumahRute in r.pelanggan:
			ids += p.id + ","
			if p.sisi != LoperAnim.Sisi.SEBERANG:
				pelanggan_dekat += 1
		if not per_urutan.has(kunci):
			per_urutan[kunci] = {}
		(per_urutan[kunci] as Dictionary)[ids] = true
		if r.panjang_ubin < 200.0 or r.panjang_ubin > 300.0:
			panjang_luar += 1
	_cek(rute_sah == 400, "R3 400 seed membangun rute sah (%d)" % rute_sah)
	_cek(pelanggan_dekat == 0 and panjang_luar == 0, "R3 pelanggan hanya seberang dan panjang 200..300")
	var urutan_dengan_variasi: int = 0
	for kunci: String in per_urutan.keys():
		if (per_urutan[kunci] as Dictionary).size() > 1:
			urutan_dengan_variasi += 1
	_cek(urutan_dengan_variasi >= 20, "R1 pilihan pelanggan berbeda antar seed pada urutan segmen yang sama (%d dari %d urutan punya variasi)" % [urutan_dengan_variasi, per_urutan.size()])


func _r2() -> void:
	await process_frame
	root.size = Vector2i(2340, 1080)
	await process_frame
	var akar: RuteMain = (load("res://scenes/rute/rute.tscn") as PackedScene).instantiate() as RuteMain
	root.add_child(akar)
	await process_frame
	await process_frame
	akar.set_process(false)
	var seed_awal: int = akar.benih()
	akar.panel_akhir().tampilkan(true)
	await process_frame
	await process_frame
	var tombol: Rect2 = akar.panel_akhir().rect_tombol()
	var pusat: Vector2 = (tombol.position + tombol.size / 2.0) * 3.0
	var turun: InputEventScreenTouch = InputEventScreenTouch.new()
	turun.index = 5
	turun.position = pusat
	turun.pressed = true
	Input.parse_input_event(turun)
	Input.flush_buffered_events()
	var naik: InputEventScreenTouch = InputEventScreenTouch.new()
	naik.index = 5
	naik.position = pusat
	naik.pressed = false
	Input.parse_input_event(naik)
	Input.flush_buffered_events()
	await process_frame
	_cek(akar.benih() == seed_awal + 1, "R2 ketukan sentuh pada tombol Main lagi memakai seed berikutnya (%d -> %d)" % [seed_awal, akar.benih()])
	_cek(not akar.panel_akhir().tampil(), "R2 banner dan tombol tersembunyi lagi sesudah Main lagi")
	root.remove_child(akar)
	akar.free()
