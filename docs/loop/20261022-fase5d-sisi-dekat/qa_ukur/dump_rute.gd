extends SceneTree
# QA1: dump generik rute (refleksi) ke JSON. Argumen: --  <keluaran.json> <mode: lama|baru>
func _dump(v: Variant) -> Variant:
	if v is RefCounted and not (v is SegmenRute):
		var d: Dictionary = {}
		for p: Dictionary in (v as Object).get_property_list():
			if (int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
				d[p["name"]] = _dump((v as Object).get(p["name"]))
		return d
	if v is SegmenRute:
		return "SEG:" + str((v as SegmenRute).id)
	if v is Array:
		var a: Array = []
		for e: Variant in v:
			a.append(_dump(e))
		return a
	if v is Dictionary:
		var d2: Dictionary = {}
		for k: Variant in v:
			d2[str(k)] = _dump(v[k])
		return d2
	if v is PackedFloat64Array or v is PackedInt32Array or v is PackedStringArray:
		return Array(v)
	if v is float:
		return snappedf(v, 0.000001)
	return v

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var keluar: String = args[0]
	var mode: String = args[1]
	var kum: PemuatRute.Kumpulan = PemuatRute.muat_folder()
	var hasil: Dictionary = {}
	var seeds: Array[int] = []
	for h: int in range(1, 101):
		seeds.append(SeedHari.rute(h))
	for s: int in range(1, 101):
		seeds.append(s)
	for s: int in seeds:
		var f: Callable = Callable(RouteBuilder, "bangun")
		var h1: RouteBuilder.Hasil = f.call(s, kum.segmen)
		var d: Dictionary = {"galat": h1.galat, "rute": _dump(h1.rute) if h1.rute != null else null}
		if mode == "baru":
			(d["rute"] as Dictionary).erase("hari")
			var h2: RouteBuilder.Hasil = f.call(s, kum.segmen, 2)
			d["hari2"] = _dump(h2.rute)
			(d["hari2"] as Dictionary).erase("hari")
		hasil[str(s)] = d
	var f: FileAccess = FileAccess.open(keluar, FileAccess.WRITE)
	f.store_string(JSON.stringify(hasil, "", true))
	f.close()
	print("tulis ", keluar, " ", hasil.size())
	quit()
