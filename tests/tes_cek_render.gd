class_name TesCekRender
extends RefCounted
## Tes probe render Compatibility (AC-8, D-8 run fase1b-umpan-balik): pembantu murni pembaca piksel, scene `cek_render.tscn` di
## headless (node fitur terpasang, satu baris `[cek_render]` per fitur + ringkasan, pembacaan piksel ditulis "tidak bisa dibaca
## headless" dan TIDAK diklaim cocok), dan probe terisolasi dari game: scene utama tetap `hari.tscn` (sebelum run fase4a-koran-hari `rute.tscn`, sebelum run fase3a-rute `jalan_uji.tscn`), tidak ada skrip atau scene
## lain yang merujuknya, tidak ada `override.cfg`. Hasil piksel sungguhan hanya bisa dilihat di jendela asli (LOG, shots/).

const BERKAS_PROBE: String = "res://scenes/dev/cek_render.tscn"
const BERKAS_SKRIP_PROBE: String = "res://scripts/dev/cek_render.gd"
const BERKAS_SHADER: String = "res://assets/shaders/warna_bayangan.gdshader"
const BERKAS_EKSPOR: String = "res://tools/ekspor_cek_render.py"
const SCENE_UTAMA: String = "res://scenes/hari/hari.tscn"
const FITUR: Array[String] = ["light2d", "glow", "cpu_partikel", "gpu_partikel", "shader_bayangan"]

var _cek: Callable
var _judul: Callable
var _tree: SceneTree


func _init(cek: Callable, judul: Callable, tree: SceneTree) -> void:
	_cek = cek
	_judul = judul
	_tree = tree


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_murni()
	_test_isolasi()
	await _test_scene_headless()


func _test_murni() -> void:
	_judul.call("Probe render: pembantu murni pembaca piksel (AC-8)")
	check(CekRender.adalah_penanda(Color8(0, 0, 0, 71)), "#000000 alpha 71 = piksel penanda bayangan (ART_DIRECTION 2.1 no. 5)")
	for c: Color in [Color8(0, 0, 0, 70), Color8(0, 0, 0, 72), Color8(0, 0, 0, 255), Color8(1, 0, 0, 71), Color8(0, 0, 1, 71), Color8(0, 0, 0, 0)]:
		check(not CekRender.adalah_penanda(c), "bukan penanda: %s" % c.to_html())
	var latar: Color = Palette.TEXT_2
	var alpha: float = 71.0 / 255.0
	var hasil: Color = CekRender.campur(latar, Palette.BAYANGAN_CONTOH, alpha)
	check(absf(hasil.r - (latar.r * (1.0 - alpha) + Palette.BAYANGAN_CONTOH.r * alpha)) < 0.000001 and hasil.a == 1.0, "campur = latar x (1 - a) + warna x a, alpha hasil 1")
	check(CekRender.campur(latar, Palette.OUTLINE, 0.0).is_equal_approx(Color(latar, 1.0)) and CekRender.campur(latar, Palette.OUTLINE, 1.0).is_equal_approx(Palette.OUTLINE), "campur alpha 0 = latar, alpha 1 = warna")
	check(CekRender.cocok(Color8(100, 100, 100), Color8(103, 97, 100), 3.0 / 255.0), "cocok: selisih 3 langkah 8 bit diterima pada toleransi 3")
	check(not CekRender.cocok(Color8(100, 100, 100), Color8(104, 100, 100), 3.0 / 255.0), "tidak cocok: selisih 4 langkah ditolak pada toleransi 3")
	check(not CekRender.cocok(Palette.BAYANGAN_CONTOH, Color8(0, 0, 0), 3.0 / 255.0), "warna bayangan contoh berbeda dari hitam (shader yang tidak jalan terdeteksi)")
	check(Palette.BAYANGAN_CONTOH.to_html(false) == "2e3550", "Palette.BAYANGAN_CONTOH = #2E3550 (ART_DIRECTION 2.5 siang)")


func _test_isolasi() -> void:
	_judul.call("Probe render terisolasi dari game: scene utama tetap rute (AC-8)")
	check(ProjectSettings.get_setting("application/run/main_scene") == SCENE_UTAMA, "scene utama project.godot = hari.tscn (probe tidak menggantikannya)")
	check(not FileAccess.file_exists("res://override.cfg"), "tidak ada override.cfg di root repo")
	check(FileAccess.get_file_as_string("res://.gitignore").split("\n").has("override.cfg"), ".gitignore menutup override.cfg")
	var perujuk: Array[String] = []
	for folder: String in ["res://scripts", "res://scenes"]:
		for berkas: String in _daftar(folder):
			if berkas == BERKAS_SKRIP_PROBE or berkas == BERKAS_PROBE:
				continue
			var teks: String = FileAccess.get_file_as_string(berkas)
			if teks.contains("cek_render") or teks.contains("CekRender"):
				perujuk.append(berkas)
	check(perujuk.is_empty(), "tidak ada skrip atau scene game yang merujuk probe (tidak bisa dipicu pemain): %s" % [perujuk])
	var ekspor: String = FileAccess.get_file_as_string(BERKAS_EKSPOR)
	check(ekspor.contains("SCENE_UTAMA = '%s'" % SCENE_UTAMA) and ekspor.contains("SCENE_PROBE = '%s'" % BERKAS_PROBE) and ekspor.contains("finally:"), "tools/ekspor_cek_render.py mengganti scene utama hanya selama ekspor dan memulihkannya (finally)")
	var shader: String = FileAccess.get_file_as_string(BERKAS_SHADER)
	check(shader.contains("shader_type canvas_item") and shader.contains("alpha_penanda") and shader.contains("warna_bayangan"), "shader warna bayangan canvas_item ada")


func _daftar(folder: String) -> Array[String]:
	var hasil: Array[String] = []
	var dir: DirAccess = DirAccess.open(folder)
	if dir == null:
		return hasil
	for nama: String in dir.get_files():
		if nama.ends_with(".gd") or nama.ends_with(".tscn"):
			hasil.append(folder.path_join(nama))
	for sub: String in dir.get_directories():
		hasil.append_array(_daftar(folder.path_join(sub)))
	return hasil


func _test_scene_headless() -> void:
	_judul.call("Probe render di headless: node fitur, baris [cek_render], piksel tidak diklaim (AC-8)")
	var paket: PackedScene = load(BERKAS_PROBE) as PackedScene
	check(paket != null, "scenes/dev/cek_render.tscn termuat")
	if paket == null:
		return
	var probe: CekRender = paket.instantiate() as CekRender
	probe.durasi_ukur_detik = 0.1
	probe.boleh_keluar = false
	var selesai: Array[bool] = []
	probe.selesai.connect(func() -> void: selesai.append(true))
	_tree.root.add_child(probe)
	var batas: int = 600
	while selesai.is_empty() and batas > 0:
		await _tree.process_frame
		batas -= 1
	check(not selesai.is_empty(), "probe selesai mengukur (sinyal selesai)")
	var node: Dictionary = probe.node_uji()
	var cahaya: PointLight2D = node["cahaya"]
	check(cahaya != null and cahaya.shadow_enabled and cahaya.shadow_filter == Light2D.SHADOW_FILTER_PCF5 and cahaya.texture is GradientTexture2D, "PointLight2D: bayangan lembut PCF5, tekstur cahaya dari kode (GradientTexture2D)")
	check((node["occluder"] as LightOccluder2D).occluder != null and (node["modulasi"] as CanvasModulate).color == Palette.UI_PANEL_RAISED, "LightOccluder2D berbentuk dan CanvasModulate gelap (Palette)")
	var env: Environment = (node["lingkungan"] as WorldEnvironment).environment
	check(env.background_mode == Environment.BG_CANVAS and env.glow_enabled and env.background_canvas_max_layer == 0, "WorldEnvironment: latar Canvas, glow menyala, hanya layer 0")
	check((node["cpu"] as CPUParticles2D).emitting and (node["gpu"] as GPUParticles2D).emitting and (node["gpu"] as GPUParticles2D).process_material is ParticleProcessMaterial, "CPUParticles2D dan GPUParticles2D sama-sama memancar")
	var bahan: ShaderMaterial = (node["shader"] as AnimatedSprite2D).material as ShaderMaterial
	check(bahan != null and bahan.shader.resource_path == BERKAS_SHADER and bahan.get_shader_parameter(&"warna_bayangan") == Palette.BAYANGAN_CONTOH and is_equal_approx(float(bahan.get_shader_parameter(&"alpha_penanda")), 71.0 / 255.0), "sprite kanan memakai shader warna bayangan dengan Palette.BAYANGAN_CONTOH dan alpha penanda 71/255")
	check((node["kontrol"] as AnimatedSprite2D).material == null and (node["kontrol"] as AnimatedSprite2D).frame == (node["shader"] as AnimatedSprite2D).frame, "sprite kontrol tanpa shader, frame sama")
	var laporan: PackedStringArray = probe.laporan()
	for fitur: String in FITUR:
		var ada: bool = false
		for baris: String in laporan:
			if baris.begins_with("[cek_render] %s: " % fitur):
				ada = true
				check(baris.contains("renderer=") and baris.contains("fps="), "baris %s memuat renderer dan fps" % fitur)
		check(ada, "satu baris [cek_render] %s ada" % fitur)
	var perangkat: bool = false
	var ringkasan: String = ""
	var baris_shader: String = ""
	for baris: String in laporan:
		perangkat = perangkat or baris.begins_with("[cek_render] perangkat: ")
		if baris.begins_with("[cek_render] ringkasan: "):
			ringkasan = baris
		if baris.begins_with("[cek_render] shader_bayangan: "):
			baris_shader = baris
	check(perangkat and not ringkasan.is_empty(), "baris perangkat (renderer, GPU, fps) dan ringkasan ada")
	check(baris_shader.contains("tidak bisa dibaca headless"), "headless: pembacaan piksel shader ditulis \"tidak bisa dibaca headless\": %s" % baris_shader)
	var hasil: Dictionary = probe.hasil()
	var diklaim: Array[String] = []
	for fitur: String in FITUR:
		if hasil.get(fitur, "") != "tidak_terbaca":
			diklaim.append(fitur)
	check(diklaim.is_empty() and ringkasan.contains("shader_bayangan=tidak_terbaca"), "headless: tidak ada fitur yang diklaim lolos dari piksel (%s)" % [diklaim])
	_tree.root.remove_child(probe)
	probe.free()
