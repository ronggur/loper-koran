extends SceneTree
## QA REPRO (run 6A1 QA iterasi 1): app di-background (NOTIFICATION_APPLICATION_PAUSED / FOCUS_OUT) saat layar bengkel terbuka.
## `RuteMain` (AdeganJalan) masih di pohon di bawah bengkel dan menerima notifikasi itu: menjeda dirinya, `get_tree().paused = true`.
## Dijalankan: godot --headless --path . --script res://tests/qa_repro_bengkel_background.gd
## Harapan benar: bengkel tetap bisa disentuh sesudah background (tombol "Hari berikutnya" bekerja lewat sentuhan sungguhan). Tes ini mencetak PASS/FAIL.

func _initialize() -> void:
	_jalan()


func _cek(kondisi: bool, label: String) -> void:
	print(("PASS: " if kondisi else "FAIL: ") + label)


func _judul(teks: String) -> void:
	print("== " + teks)


func _jalan() -> void:
	var a: TesAlurHari = TesAlurHari.new(_cek, _judul, self)
	a._bersihkan_folder()
	var m: Node = a._manajer()
	var hari: HariMain = await a._siapkan(m)
	hari.koran().tombol_lewati().ditekan.emit()
	var rute: RuteMain = await a._berangkat(hari)
	await a._selesaikan_rute(rute)
	rute.layar_hasil().tombol_main_lagi().ditekan.emit()
	var bengkel: LayarBengkel = hari.bengkel()
	_cek(bengkel != null and hari.status().keadaan == MesinHari.Keadaan.BENGKEL, "bengkel terbuka")
	hari.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await process_frame
	print("INFO: tree.paused=", paused, " rute.sedang_jeda=", rute.sedang_jeda(), " bengkel.can_process=", bengkel.can_process(), " layar_jeda.visible=", rute.find_child("LayarJeda", true, false).visible)
	if DisplayServer.get_name() != "headless":
		await process_frame
		root.get_texture().get_image().save_png("res://docs/loop/20261020-fase6a1-bengkel-kondisi/shots/qa1/qa_bengkel_sesudah_background.png")
	_cek(not paused, "sesudah app ke background di bengkel pohon TIDAK dalam keadaan paused (bengkel tetap menerima sentuhan)")
	_cek(bengkel.can_process(), "bengkel masih dapat memproses input sesudah background")
	# Sentuhan sungguhan pada "Hari berikutnya"
	var r: Rect2 = bengkel.tombol_hari_berikutnya().get_global_rect()
	var titik: Vector2 = (r.position + r.size / 2.0) * 3.0
	for tekan: bool in [true, false]:
		var p: InputEventScreenTouch = InputEventScreenTouch.new()
		p.index = 0
		p.position = titik
		p.pressed = tekan
		Input.parse_input_event(p)
		Input.flush_buffered_events()
		await process_frame
	await process_frame
	_cek(hari.status().keadaan == MesinHari.Keadaan.KORAN, "sentuhan pada 'Hari berikutnya' sesudah background bekerja (keadaan KORAN), dapat %s" % [hari.status().keadaan])
	a._bersihkan(hari)
	a._tutup_manajer(m)
	a._bersihkan_folder()
	quit()
