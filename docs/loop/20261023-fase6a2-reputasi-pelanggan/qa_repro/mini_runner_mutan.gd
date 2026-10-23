extends SceneTree
var g := 0
var l := 0
func _cek(k: bool, label: String) -> void:
	if k: l += 1
	else:
		g += 1
		if g <= 4: print("GAGAL: ", label)
func _j(t: String) -> void: pass
func _initialize() -> void:
	var grp: String = OS.get_cmdline_user_args()[0]
	if "pure" in grp:
		TesReputasi.new(_cek, _j).jalankan()
		TesSaveV4.new(_cek, _j).jalankan()
		TesPotongan.new(_cek, _j).jalankan()
		TesMilestone.new(_cek, _j).jalankan()
	if "rute" in grp:
		TesRutePelanggan.new(_cek, _j).jalankan()
	if "scene" in grp:
		await TesPotonganScene.new(_cek, _j, self).jalankan()
		await TesReputasiScene.new(_cek, _j, self).jalankan()
	if "old" in grp:
		TesSkor.new(_cek, _j).jalankan()
		TesRute.new(_cek, _j).jalankan()
	print("RINGKAS lolos ", l, " gagal ", g)
	quit()
