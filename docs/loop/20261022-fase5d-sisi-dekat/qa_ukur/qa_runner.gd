extends SceneTree
var _lolos: int = 0
var _gagal: int = 0
func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var pilih: String = args[0] if args.size() > 0 else "semua"
	var check: Callable = Callable(self, "check")
	var judul: Callable = Callable(self, "_judul")
	if pilih in ["semua", "A"]:
		var a: TesSisiDekat = TesSisiDekat.new(check, judul, self)
		await a.jalankan()
	if pilih in ["semua", "B"]:
		var b: TesSisiDekatB = TesSisiDekatB.new(check, judul)
		b.jalankan()
	if pilih in ["semua", "S"]:
		root.size = Vector2i(780, 360)
		var s: TesSisiDekatScene = TesSisiDekatScene.new(check, judul, self)
		await s.jalankan()
	if pilih in ["semua", "R"]:
		var r: TesRute = TesRute.new(check, judul)
		r.jalankan()
	if pilih in ["semua", "H"]:
		var h: TesHudRuteScene = TesHudRuteScene.new(check, judul, self)
		await h.jalankan()
		var rd: TesRadar = TesRadar.new(check, judul)
		rd.jalankan()
	if pilih in ["semua", "K"]:
		var k: TesKotakSurat = TesKotakSurat.new(check, judul, self)
		await k.jalankan()
		var sc: TesRuteScene = TesRuteScene.new(check, judul, self)
		await sc.jalankan()
	print("%d lolos, %d gagal" % [_lolos, _gagal])
	quit(1 if _gagal > 0 else 0)
func check(kondisi: bool, label: String) -> void:
	if kondisi:
		_lolos += 1
	else:
		_gagal += 1
		print("GAGAL: ", label)
func _judul(teks: String) -> void:
	pass
