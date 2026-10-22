extends SceneTree
## Cek paket run 5D (AC-14): dijalankan dengan --main-pack dari folder di luar repo.
## godot --headless --main-pack <repo>/build/kring-uji.pck --script <skrip ini>   (cwd = folder di luar repo)

var gagal: int = 0
var lolos: int = 0


func cek(k: bool, label: String) -> void:
	if k:
		lolos += 1
	else:
		gagal += 1
		print("PAKET GAGAL: ", label)


func kumpul(folder: String, hasil: Array[String]) -> void:
	for f: String in DirAccess.get_files_at(folder):
		hasil.append(folder.path_join(f))
	for d: String in DirAccess.get_directories_at(folder):
		kumpul(folder.path_join(d), hasil)


func _initialize() -> void:
	var semua: Array[String] = []
	kumpul("res://", semua)
	print("berkas di paket: ", semua.size())
	var teks_semua: String = "\n".join(semua)
	for terlarang: String in ["res://tests/", "res://docs/", "res://tools/", "res://build/", "spike_sisi_dekat", "res://assets/sprites/_spike/", "cek_render", "warna_bayangan"]:
		cek(not teks_semua.contains(terlarang), "tidak ada %s di paket" % terlarang)
	cek(not teks_semua.to_lower().contains("tem" + "bok"), "tidak ada berkas dengan nama tembok di paket (aset, skrip TembokDekat/VarianTembok)")
	# Rumah dekat baru: enam PNG (remap .import) dimuat, ukuran = JSON, tanpa kotak surat terpanggang tidak bisa dicek dari paket (dicek tes piksel), tapi JSON teras ada.
	var rumah_dekat: Array[String] = []
	var rumah_seberang: int = 0
	for f: String in semua:
		if f.begins_with("res://assets/sprites/houses/perumahan/") and f.ends_with(".png.import"):
			if f.contains("_dekat_"):
				rumah_dekat.append(f.trim_suffix(".import"))
			else:
				rumah_seberang += 1
	cek(rumah_dekat.size() == 6 and rumah_seberang == 6, "6 rumah dekat + 6 seberang di paket, dapat %d + %d" % [rumah_dekat.size(), rumah_seberang])
	for jalur: String in rumah_dekat:
		var t: Texture2D = load(jalur) as Texture2D
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(jalur.get_basename() + ".json"))
		cek(t != null and j is Dictionary, "%s dan JSON dimuat dari paket" % jalur)
		if t == null or not (j is Dictionary):
			continue
		var d: Dictionary = j
		cek(int(d["size"][0]) == t.get_width() and int(d["size"][1]) == t.get_height(), "%s: size JSON = tekstur %s" % [jalur, t.get_size()])
		cek((d["teras_ubin"] as Array).size() == 4 and (d["penutup_ubin"] as Array).size() == 4 and float(d["penutup_tinggi_ubin"]) > 0.0, "%s: teras_ubin dan penutup_ubin di JSON paket" % jalur)
	# Kotak surat.
	for nama: String in ["prop_kotak_surat", "prop_kotak_surat_bukan"]:
		var t: Texture2D = load("res://assets/sprites/props/%s.png" % nama) as Texture2D
		cek(t != null, "%s dimuat dari paket (%s)" % [nama, t.get_size() if t != null else Vector2.ZERO])
	# Kunci tip hari 3 lewat terjemahan hasil impor.
	TranslationServer.set_locale("id")
	for kunci: String in ["RUTE_TIP_LABEL", "RUTE_TIP_SISI_DEKAT"]:
		var teks: String = TranslationServer.translate(kunci)
		cek(teks != kunci and not teks.is_empty(), "kunci %s diterjemahkan dari paket: '%s'" % [kunci, teks])
	# Segmen dari paket.
	var kumpulan: PemuatRute.Kumpulan = PemuatRute.muat_folder()
	cek(kumpulan.galat.is_empty() and kumpulan.segmen.size() == 9, "9 segmen dimuat dari paket tanpa galat: %s" % [kumpulan.galat])
	var boleh_dekat: int = 0
	var tag_salah: int = 0
	for s: SegmenRute in kumpulan.segmen:
		if s.sisi_pelanggan != "dua_sisi":
			tag_salah += 1
		for r: SegmenRute.Rumah in s.rumah:
			if r.sisi == LoperAnim.Sisi.DEKAT and r.pelanggan_boleh:
				boleh_dekat += 1
	cek(boleh_dekat == 34 and tag_salah == 0, "34 rumah dekat pelanggan_boleh dan semua segmen dua_sisi dari paket (dapat %d, tag salah %d)" % [boleh_dekat, tag_salah])
	# Rute dari paket: hari 1 dan 2 tanpa pelanggan dekat, hari 3 dan 4 dengan 8-9, 25 total.
	var ringkas: Array[String] = []
	for hari: int in [1, 2, 3, 4, 10]:
		var h: RouteBuilder.Hasil = RouteBuilder.bangun(SeedHari.rute(hari), kumpulan.segmen, hari)
		cek(h.sah() and h.rute.pelanggan.size() == 25, "rute hari %d dari paket sah, 25 pelanggan" % hari)
		if not h.sah():
			continue
		var dekat: int = 0
		for r: RouteBuilder.RumahRute in h.rute.pelanggan:
			if r.sisi == LoperAnim.Sisi.DEKAT:
				dekat += 1
		ringkas.append("hari %d: %d dekat" % [hari, dekat])
		if hari < 3:
			cek(dekat == 0, "hari %d: 0 pelanggan dekat dari paket, dapat %d" % [hari, dekat])
		else:
			cek(dekat == 8 or dekat == 9, "hari %d: 8 atau 9 pelanggan dekat dari paket, dapat %d" % [hari, dekat])
	print("rute dari paket: ", ringkas)
	# Scene dimuat dari paket: rute dan panel tip.
	var rute: PackedScene = load("res://scenes/rute/rute.tscn") as PackedScene
	cek(rute != null, "rute.tscn dimuat dari paket")
	var tip: PackedScene = load("res://scenes/ui/panel_tip_sisi_dekat.tscn") as PackedScene
	cek(tip != null, "panel_tip_sisi_dekat.tscn dimuat dari paket")
	if tip != null:
		var node: Node = tip.instantiate()
		cek(node != null, "panel tip bisa dibuat dari paket")
		node.free()
	print("cek paket 5D: %d lolos, %d gagal" % [lolos, gagal])
	quit(1 if gagal > 0 else 0)
