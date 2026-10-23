extends SceneTree
var lolos: int = 0
var gagal: int = 0
func check(k: bool, label: String) -> void:
	if k:
		lolos += 1
	else:
		gagal += 1
		print("GAGAL: ", label)
func judul(t: String) -> void:
	pass
func _initialize() -> void:
	var a: TesTampilBengkel = TesTampilBengkel.new(check, judul)
	a.jalankan()
	var k: TesKomponenUi = TesKomponenUi.new(check, judul)
	k.jalankan()
	var e: TesExport = TesExport.new(check, judul)
	e.jalankan()
	var b: TesBengkelTataC = TesBengkelTataC.new(check, judul, self)
	await b.jalankan()
	var c: TesBengkelScene = TesBengkelScene.new(check, judul, self)
	await c.jalankan()
	print("%d lolos, %d gagal" % [lolos, gagal])
	quit(1 if gagal > 0 else 0)
