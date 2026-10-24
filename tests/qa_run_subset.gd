extends SceneTree
## QA UI-2 iterasi 1: runner subset untuk mutan (TIDAK terdaftar di run_tests.gd). Hanya tes tampilan; mutan yang lolos di sini diulang dengan run_tests.gd penuh.

var _lolos: int = 0
var _gagal: int = 0


func _initialize() -> void:
	await process_frame
	var audio: Node = root.get_node_or_null(^"Audio")
	if audio != null:
		audio.set(&"putar_di_driver_dummy", true)
	var komponen_ui: TesKomponenUi = TesKomponenUi.new(check, _judul)
	komponen_ui.jalankan()
	var tampil_bengkel: TesTampilBengkel = TesTampilBengkel.new(check, _judul)
	tampil_bengkel.jalankan()
	var tampil_hasil: TesTampilHasil = TesTampilHasil.new(check, _judul)
	tampil_hasil.jalankan()
	var tampil_koran: TesTampilKoran = TesTampilKoran.new(check, _judul)
	tampil_koran.jalankan()
	var tampil_layar_c: TesTampilLayarC = TesTampilLayarC.new(check, _judul)
	tampil_layar_c.jalankan()
	var halaman_koran: TesHalamanKoran = TesHalamanKoran.new(check, _judul, self)
	await halaman_koran.jalankan()
	var scene_hud_rute: TesHudRuteScene = TesHudRuteScene.new(check, _judul, self)
	await scene_hud_rute.jalankan()
	var scene_jeda: TesJedaScene = TesJedaScene.new(check, _judul, self)
	await scene_jeda.jalankan()
	var scene_gerak: TesGerakScene = TesGerakScene.new(check, _judul, self)
	await scene_gerak.jalankan()
	var scene_kondisi: TesKondisiScene = TesKondisiScene.new(check, _judul, self)
	await scene_kondisi.jalankan()
	var scene_bengkel: TesBengkelScene = TesBengkelScene.new(check, _judul, self)
	await scene_bengkel.jalankan()
	var tata_c: TesBengkelTataC = TesBengkelTataC.new(check, _judul, self)
	await tata_c.jalankan()
	var scene_potongan: TesPotonganScene = TesPotonganScene.new(check, _judul, self)
	await scene_potongan.jalankan()
	var scene_reputasi: TesReputasiScene = TesReputasiScene.new(check, _judul, self)
	await scene_reputasi.jalankan()
	var hasil_struk: TesHasilStruk = TesHasilStruk.new(check, _judul, self)
	await hasil_struk.jalankan()
	var hasil_dunia: TesHasilDunia = TesHasilDunia.new(check, _judul, self)
	await hasil_dunia.jalankan()
	var layar_c_scene: TesLayarCScene = TesLayarCScene.new(check, _judul, self)
	await layar_c_scene.jalankan()
	var tata_letak: TesTataLetak = TesTataLetak.new(check, _judul, self)
	await tata_letak.jalankan()
	var scene_misi: TesMisiScene = TesMisiScene.new(check, _judul, self)
	await scene_misi.jalankan()
	if audio != null:
		audio.call(&"hentikan_sepeda")
		audio.call(&"hentikan_lempar")
		audio.set(&"putar_di_driver_dummy", false)
		await create_timer(0.25).timeout
	print("%d lolos, %d gagal" % [_lolos, _gagal])
	quit(1 if _gagal > 0 else 0)


func check(kondisi: bool, label: String) -> void:
	if kondisi:
		_lolos += 1
	else:
		_gagal += 1
		print("GAGAL: %s" % label)


func _judul(teks: String) -> void:
	print("== %s ==" % teks)
