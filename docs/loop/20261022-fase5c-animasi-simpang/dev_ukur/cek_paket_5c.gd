extends SceneTree
## Cek paket run 5C (AC-22): dijalankan dengan --main-pack dari folder di luar repo.

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
	# Animasi pemain.
	var frames: SpriteFrames = load("res://assets/sprites/loper/loper_agen_frames.tres") as SpriteFrames
	cek(frames != null and frames.get_animation_names().size() == 68, "SpriteFrames 68 animasi, dapat %d" % (frames.get_animation_names().size() if frames != null else -1))
	var ukuran: Dictionary = {"jatuh_": Vector2(140, 88), "terjerembab_": Vector2(140, 88), "bangkit_": Vector2(140, 88), "berhenti_": Vector2(46, 58)}
	var n_anim: int = 0
	for arah: String in ["kiri", "serong_kiri", "normal", "serong_kanan", "kanan"]:
		for awalan: String in ukuran:
			var nama: String = awalan + arah
			cek(frames.has_animation(nama), "animasi %s ada" % nama)
			if not frames.has_animation(nama):
				continue
			n_anim += 1
			for i: int in frames.get_frame_count(nama):
				var t: Texture2D = frames.get_frame_texture(nama, i)
				cek(t != null and Vector2(t.get_size()) == ukuran[awalan], "%s f%d ukuran %s, dapat %s" % [nama, i, ukuran[awalan], t.get_size() if t != null else Vector2.ZERO])
	print("animasi 5C diperiksa: ", n_anim, " frame bangkit_normal: ", frames.get_frame_count("bangkit_normal"), " jatuh_kiri: ", frames.get_frame_count("jatuh_kiri"))
	for png: String in ["loper_agen_jatuh", "loper_agen_bangkit", "loper_agen_berhenti"]:
		var tex: Texture2D = load("res://assets/sprites/loper/%s.png" % png) as Texture2D
		cek(tex != null, "%s.png dimuat dari paket (%s)" % [png, tex.get_size() if tex != null else Vector2.ZERO])
	# Sheet kucing 9 kolom.
	var kucing: Texture2D = load("res://assets/sprites/npc/mission_kucing_sheet.png") as Texture2D
	var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/npc/mission_kucing_sheet.json"))
	cek(kucing != null and int(j["columns"]) == 9 and kucing.get_width() == 9 * int(j["cell"][0]) and kucing.get_height() == int(j["rows"]) * int(j["cell"][1]), "sheet kucing 9 kolom %s" % [kucing.get_size() if kucing != null else Vector2.ZERO])
	# Ubin ujung kerb dan simpang.
	var ubin: Array[String] = []
	for f: String in semua:
		if f.begins_with("res://assets/sprites/tiles/perumahan/") and (f.contains("simpang_") or f.contains("_ujung")) and f.ends_with(".png.import"):
			ubin.append(f.trim_suffix(".import"))
	cek(ubin.size() == 36, "36 ubin ujung/simpang (remap .import) di paket, dapat %d" % ubin.size())
	var n_dekat: int = 0
	var n_seberang: int = 0
	var n_ujung: int = 0
	for jalur: String in ubin:
		var t: Texture2D = load(jalur) as Texture2D
		cek(t != null, "%s dimuat dari paket" % jalur)
		if jalur.contains("simpang_dekat_"):
			n_dekat += 1
		elif jalur.contains("simpang_seberang_"):
			n_seberang += 1
		elif jalur.contains("_ujung"):
			n_ujung += 1
	cek(n_dekat == 18 and n_seberang == 16 and n_ujung == 2, "18 simpang dekat, 16 seberang, 2 ujung; dapat %d %d %d" % [n_dekat, n_seberang, n_ujung])
	for tidak: String in ["aspal_1", "aspal_2", "aspal_3", "trotoar_dekat_masuk", "rumput_dekat_masuk", "simpang_dekat_aspal_dekat_depan_2", "simpang_seberang_aspal_seberang_depan_1", "polisi_tidur", "zebra"]:
		cek(not teks_semua.contains("tile_perumahan_" + tidak), "ubin tak dipasang %s tidak di paket" % tidak)
	# Segmen dan simpang dari paket.
	var kumpulan: PemuatRute.Kumpulan = PemuatRute.muat_folder()
	cek(kumpulan.galat.is_empty() and kumpulan.segmen.size() == 9, "9 segmen dimuat dari paket tanpa galat: %s" % [kumpulan.galat])
	var simpang_segmen: Array[String] = []
	for s: SegmenRute in kumpulan.segmen:
		for sp: SegmenRute.Simpang in s.simpang:
			simpang_segmen.append("%s@%d:%s" % [s.id, sp.pos, "dekat" if sp.sisi == LoperAnim.Sisi.DEKAT else "seberang"])
	print("simpang di segmen paket: ", simpang_segmen)
	cek(simpang_segmen.size() == 4, "4 simpang di data paket, dapat %d" % simpang_segmen.size())
	var hari1: RouteBuilder.Hasil = RouteBuilder.bangun(SeedHari.rute(1), kumpulan.segmen)
	cek(hari1.sah() and hari1.rute.pelanggan.size() == 25, "rute hari 1 dari paket sah, 25 pelanggan")
	if hari1.sah():
		var ss: Array[String] = []
		for it: RouteBuilder.SimpangItem in RouteBuilder.simpang_di(hari1.rute):
			ss.append(it.id)
		print("simpang rute hari 1: ", ss)
	# Scene rute memuat tekstur simpang dan ujung.
	var adegan: PackedScene = load("res://scenes/rute/rute.tscn") as PackedScene
	var akar: Node = adegan.instantiate()
	var tanah: Node = akar.get_node("Tanah")
	var dekat: Array = tanah.get("tekstur_simpang_dekat")
	var seberang: Array = tanah.get("tekstur_simpang_seberang")
	cek(dekat.size() == 18 and seberang.size() == 16 and not dekat.has(null) and not seberang.has(null), "rute.tscn: 18 + 16 tekstur simpang dari paket")
	cek(tanah.get("tekstur_ujung_trotoar_seberang") != null and tanah.get("tekstur_ujung_rumput_seberang") != null, "rute.tscn: dua tekstur ujung kerb dari paket")
	akar.free()
	print("cek paket 5C: %d lolos, %d gagal" % [lolos, gagal])
	quit(1 if gagal > 0 else 0)
