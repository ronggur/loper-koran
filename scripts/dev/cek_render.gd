class_name CekRender
extends Node2D
## Probe render Compatibility (D-8 run fase1b-umpan-balik; bukti untuk butir Q-014 "light 2D, glow, partikel, shader" di A54).
##
## Empat panel berdampingan di zona aman 640x360 (ART_DIRECTION 2.3 dan 7):
## 1. **light2d** (CanvasLayer 1): `CanvasModulate` gelap, `PointLight2D` dengan tekstur cahaya radial dari kode (tanpa PNG),
##    bayangan lembut (PCF5) dari `LightOccluder2D` kotak kecil, di atas ubin graybox dan sprite pemain.
## 2. **glow** (kanvas dasar, layer 0): `WorldEnvironment` mode latar Canvas dengan glow aktif; kotak `TEXT` di atas ambang glow.
## 3. **partikel** (CanvasLayer 2): `CPUParticles2D` (kiri, `ACCENT`) dan `GPUParticles2D` (kanan, `OK`), kotak 2 px.
## 4. **shader warna bayangan** (CanvasLayer 2): dua sprite pemain di latar rata `TEXT_2`; kiri tanpa shader (kontrol), kanan dengan
##    `assets/shaders/warna_bayangan.gdshader` yang mengganti piksel penanda (hitam RGB 0, alpha 71) dengan `Palette.BAYANGAN_CONTOH`.
## Glow hanya mengenai layer 0 (`background_canvas_max_layer` 0), jadi panel lain tidak ikut berpendar dan pengukurannya bersih.
##
## Sesudah `durasi_ukur_detik` probe mencetak satu baris per fitur berawalan `[cek_render]` (hasil, renderer, GPU, fps rata-rata),
## lalu baris ringkasan. Hasil tiap fitur dibaca dari **piksel hasil render** (tekstur viewport): cahaya lebih terang dari tepi dan
## bayangan occluder, halo glow di luar kotak, jumlah piksel partikel, dan untuk shader: piksel penanda di sprite ber-shader sama
## dengan campuran latar dan warna bayangan (alpha 71/255), piksel lain sama dengan sprite kontrol (`cocok`/`tidak cocok`). Di
## `--headless` piksel tidak bisa dibaca dan ditulis "tidak bisa dibaca headless" (bukan lolos).
##
## Cara membuka (lihat `docs/SETUP_ANDROID.md` bagian 6.1): desktop `godot --path . scenes/dev/cek_render.tscn -- --tangkap=<png>`
## (simpan tangkapan layar lalu keluar) atau `-- --keluar`; headless `godot --headless --path . scenes/dev/cek_render.tscn`
## (keluar sendiri); APK probe terpisah lewat `python3 tools/ekspor_cek_render.py --apk ...` yang mengganti scene utama hanya selama
## ekspor. Scene utama yang di-commit tetap `jalan_uji.tscn` dan tidak ada jalan dari game ke probe ini. Di HP probe tetap terbuka.
## Scene dev: angka tata letak di bawah adalah konstanta probe, bukan angka tuning game (tidak masuk `Config`).

## Pengukuran selesai; isi log ada di `laporan()`.
signal selesai

const AWALAN: String = "[cek_render]"
const BERKAS_FRAMES: String = "res://assets/sprites/loper/loper_agen_frames.tres"
const BERKAS_UBIN: String = "res://assets/sprites/_placeholder/tile_graybox_aspal.png"
const BERKAS_UBIN_TROTOAR: String = "res://assets/sprites/_placeholder/tile_graybox_trotoar.png"
const BERKAS_SHADER: String = "res://assets/shaders/warna_bayangan.gdshader"
const ANIMASI: StringName = &"santai_normal"
## Alpha piksel penanda bayangan tanah di sprite (ART_DIRECTION 2.1 no. 5), skala 0..255.
const ALPHA_PENANDA_8: int = 71
## Warna RGB piksel penanda bayangan tanah (hitam), bukan warna yang tampil di game.
const WARNA_PENANDA: Color = Color(0, 0, 0)
const SKALA_8: float = 255.0
## Toleransi warna per kanal saat membandingkan piksel (3 langkah 8 bit).
const TOLERANSI_WARNA: float = 3.0 / 255.0
## Toleransi "tidak berubah" untuk piksel non-penanda (1 langkah 8 bit).
const TOLERANSI_SAMA: float = 1.0 / 255.0
## Tata letak panel, piksel game.
const PANEL_X: float = 8.0
const PANEL_Y: float = 80.0
const PANEL_LEBAR: float = 152.0
const PANEL_TINGGI: float = 200.0
const PANEL_CELAH: float = 8.0
## Titik sampel latar di pojok panel, dari pojok kiri atas panel.
const SAMPEL_POJOK: Vector2 = Vector2(6, 6)
## Panel cahaya: letak lampu dari pojok panel, ukuran tekstur cahaya, energi, letak occluder dari lampu, setengah sisi occluder,
## jarak titik ukur bayangan dan pembanding dari lampu, titik terang dari lampu.
const LAMPU: Vector2 = Vector2(76, 96)
const LAMPU_TEKSTUR_PX: int = 128
const LAMPU_ENERGI: float = 1.6
const OCCLUDER: Vector2 = Vector2(16, 0)
const OCCLUDER_SETENGAH: float = 4.0
const UKUR_BAYANGAN: Vector2 = Vector2(36, 0)
const UKUR_TERANG: Vector2 = Vector2(-10, 0)
const BEDA_TERANG_MIN: float = 0.15
const BEDA_BAYANGAN_MIN: float = 0.08
const UBIN_LETAK: Array[Vector2] = [Vector2(44, 160), Vector2(108, 160), Vector2(76, 176), Vector2(76, 144)]
const PEMAIN_CAHAYA: Vector2 = Vector2(76, 150)
## Panel glow: kotak terang (pusat dari pojok panel, sisi), titik ukur halo di atas kotak, ambang glow, beda halo minimum.
const GLOW_KOTAK_PUSAT: Vector2 = Vector2(76, 100)
const GLOW_KOTAK_SISI: float = 12.0
const GLOW_UKUR_JARAK: float = 4.0
## Ambang 0,5: di Compatibility 2D (LDR) ambang 0,8-0,9 hampir tidak memendarkan kotak TEXT (diuji di desktop 2026-10-14).
const GLOW_AMBANG: float = 0.5
const GLOW_INTENSITAS: float = 2.0
const GLOW_KEKUATAN: float = 1.2
const BEDA_GLOW_MIN: float = 0.02
## Panel partikel: titik pancar CPU dan GPU dari pojok panel, jumlah, umur, kecepatan, sebaran, sisi kotak.
const PANCAR_CPU: Vector2 = Vector2(38, 180)
const PANCAR_GPU: Vector2 = Vector2(114, 180)
const PARTIKEL_JUMLAH: int = 24
const PARTIKEL_UMUR_DETIK: float = 1.5
const PARTIKEL_KECEPATAN_MIN: float = 40.0
const PARTIKEL_KECEPATAN_MAKS: float = 70.0
const PARTIKEL_SEBARAN_DERAJAT: float = 20.0
const PARTIKEL_SISI_PX: float = 2.0
## Panel shader: letak sprite kontrol dan sprite ber-shader dari pojok panel, jumlah sampel penanda dan piksel lain.
const PEMAIN_KONTROL: Vector2 = Vector2(40, 110)
const PEMAIN_SHADER: Vector2 = Vector2(112, 110)
const SAMPEL_PENANDA_MAKS: int = 12
const SAMPEL_LAIN_MAKS: int = 24
## Layer kanvas panel (glow hanya di layer 0).
const LAYER_CAHAYA: int = 1
const LAYER_LAIN: int = 2

## Lama mengukur fps sebelum membaca piksel, detik.
@export var durasi_ukur_detik: float = 5.0
## False: probe tidak pernah memanggil `quit()` (dipakai tes di dalam runner).
@export var boleh_keluar: bool = true

var _laporan: PackedStringArray = PackedStringArray()
var _hasil: Dictionary = {}
var _cahaya: PointLight2D
var _occluder: LightOccluder2D
var _modulasi: CanvasModulate
var _lingkungan: WorldEnvironment
var _cpu: CPUParticles2D
var _gpu: GPUParticles2D
var _sprite_kontrol: AnimatedSprite2D
var _sprite_shader: AnimatedSprite2D


func _ready() -> void:
	_bangun_cahaya(_panel(0))
	_bangun_glow(_panel(1))
	_bangun_partikel(_panel(2))
	_bangun_bayangan(_panel(3))
	_ukur.call_deferred()


## Pojok kiri atas panel ke-`i` (0..3), piksel game.
func _panel(i: int) -> Vector2:
	return Vector2(PANEL_X + float(i) * (PANEL_LEBAR + PANEL_CELAH), PANEL_Y)


## Baris log yang sudah dicetak.
func laporan() -> PackedStringArray:
	return _laporan


## Ringkasan hasil: {"light2d", "glow", "cpu_partikel", "gpu_partikel", "shader_bayangan"} -> teks hasil.
func hasil() -> Dictionary:
	return _hasil


## Node yang diuji (untuk tes): cahaya, occluder, modulasi, lingkungan, partikel CPU dan GPU, sprite kontrol dan ber-shader.
func node_uji() -> Dictionary:
	return {"cahaya": _cahaya, "occluder": _occluder, "modulasi": _modulasi, "lingkungan": _lingkungan, "cpu": _cpu, "gpu": _gpu, "kontrol": _sprite_kontrol, "shader": _sprite_shader}


# --- Pembangun panel ---

func _lapis(nama: String, layer: int) -> CanvasLayer:
	var lapis: CanvasLayer = CanvasLayer.new()
	lapis.name = nama
	lapis.layer = layer
	add_child(lapis)
	return lapis


func _kotak(induk: Node, pojok: Vector2, ukuran: Vector2, warna: Color, nama: String) -> ColorRect:
	var kotak: ColorRect = ColorRect.new()
	kotak.name = nama
	kotak.position = pojok
	kotak.size = ukuran
	kotak.color = warna
	kotak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	induk.add_child(kotak)
	return kotak


func _pemain(induk: Node, posisi: Vector2, nama: String) -> AnimatedSprite2D:
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.name = nama
	sprite.sprite_frames = load(BERKAS_FRAMES) as SpriteFrames
	sprite.animation = ANIMASI
	sprite.frame = 0
	sprite.position = posisi
	induk.add_child(sprite)
	return sprite


func _bangun_cahaya(pojok: Vector2) -> void:
	var lapis: CanvasLayer = _lapis("PanelCahaya", LAYER_CAHAYA)
	_kotak(lapis, pojok, Vector2(PANEL_LEBAR, PANEL_TINGGI), Palette.TEXT_2, "Latar")
	for i: int in range(UBIN_LETAK.size()):
		var ubin: Sprite2D = Sprite2D.new()
		ubin.name = "Ubin%d" % i
		ubin.texture = load(BERKAS_UBIN if i % 2 == 0 else BERKAS_UBIN_TROTOAR) as Texture2D
		ubin.position = pojok + UBIN_LETAK[i]
		lapis.add_child(ubin)
	_pemain(lapis, pojok + PEMAIN_CAHAYA, "PemainCahaya")
	_modulasi = CanvasModulate.new()
	_modulasi.name = "Modulasi"
	_modulasi.color = Palette.UI_PANEL_RAISED
	lapis.add_child(_modulasi)
	var gradien: Gradient = Gradient.new()
	gradien.set_color(0, Palette.TEXT)
	gradien.set_color(1, Color(Palette.TEXT, 0.0))
	var tekstur: GradientTexture2D = GradientTexture2D.new()
	tekstur.gradient = gradien
	tekstur.width = LAMPU_TEKSTUR_PX
	tekstur.height = LAMPU_TEKSTUR_PX
	tekstur.fill = GradientTexture2D.FILL_RADIAL
	tekstur.fill_from = Vector2(0.5, 0.5)
	tekstur.fill_to = Vector2(1.0, 0.5)
	_cahaya = PointLight2D.new()
	_cahaya.name = "Cahaya"
	_cahaya.texture = tekstur
	_cahaya.energy = LAMPU_ENERGI
	_cahaya.position = pojok + LAMPU
	_cahaya.range_layer_min = LAYER_CAHAYA
	_cahaya.range_layer_max = LAYER_CAHAYA
	_cahaya.shadow_enabled = true
	_cahaya.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	_cahaya.shadow_color = Palette.OUTLINE
	lapis.add_child(_cahaya)
	var bentuk: OccluderPolygon2D = OccluderPolygon2D.new()
	var s: float = OCCLUDER_SETENGAH
	bentuk.polygon = PackedVector2Array([Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)])
	_occluder = LightOccluder2D.new()
	_occluder.name = "Occluder"
	_occluder.occluder = bentuk
	_occluder.position = pojok + LAMPU + OCCLUDER
	lapis.add_child(_occluder)


func _bangun_glow(pojok: Vector2) -> void:
	var induk: Node2D = Node2D.new()
	induk.name = "PanelGlow"
	add_child(induk)
	_kotak(induk, pojok, Vector2(PANEL_LEBAR, PANEL_TINGGI), Palette.OUTLINE, "Latar")
	var sisi: Vector2 = Vector2(GLOW_KOTAK_SISI, GLOW_KOTAK_SISI)
	_kotak(induk, pojok + GLOW_KOTAK_PUSAT - sisi / 2, sisi, Palette.TEXT, "KotakTerang")
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.background_canvas_max_layer = 0
	env.glow_enabled = true
	env.glow_hdr_threshold = GLOW_AMBANG
	env.glow_strength = GLOW_KEKUATAN
	env.glow_intensity = GLOW_INTENSITAS
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	for level: int in range(1, 4):
		env.set_glow_level(level, 1.0)
	_lingkungan = WorldEnvironment.new()
	_lingkungan.name = "Lingkungan"
	_lingkungan.environment = env
	add_child(_lingkungan)


func _bangun_partikel(pojok: Vector2) -> void:
	var lapis: CanvasLayer = _lapis("PanelPartikel", LAYER_LAIN)
	_kotak(lapis, pojok, Vector2(PANEL_LEBAR, PANEL_TINGGI), Palette.OUTLINE, "Latar")
	_cpu = CPUParticles2D.new()
	_cpu.name = "PartikelCpu"
	_cpu.position = pojok + PANCAR_CPU
	_cpu.amount = PARTIKEL_JUMLAH
	_cpu.lifetime = PARTIKEL_UMUR_DETIK
	_cpu.direction = Vector2.UP
	_cpu.spread = PARTIKEL_SEBARAN_DERAJAT
	_cpu.gravity = Vector2.ZERO
	_cpu.initial_velocity_min = PARTIKEL_KECEPATAN_MIN
	_cpu.initial_velocity_max = PARTIKEL_KECEPATAN_MAKS
	_cpu.scale_amount_min = PARTIKEL_SISI_PX
	_cpu.scale_amount_max = PARTIKEL_SISI_PX
	_cpu.color = Palette.ACCENT
	_cpu.emitting = true
	lapis.add_child(_cpu)
	var bahan: ParticleProcessMaterial = ParticleProcessMaterial.new()
	bahan.direction = Vector3(0, -1, 0)
	bahan.spread = PARTIKEL_SEBARAN_DERAJAT
	bahan.gravity = Vector3.ZERO
	bahan.initial_velocity_min = PARTIKEL_KECEPATAN_MIN
	bahan.initial_velocity_max = PARTIKEL_KECEPATAN_MAKS
	bahan.scale_min = PARTIKEL_SISI_PX
	bahan.scale_max = PARTIKEL_SISI_PX
	bahan.color = Palette.OK
	_gpu = GPUParticles2D.new()
	_gpu.name = "PartikelGpu"
	_gpu.position = pojok + PANCAR_GPU
	_gpu.amount = PARTIKEL_JUMLAH
	_gpu.lifetime = PARTIKEL_UMUR_DETIK
	_gpu.process_material = bahan
	_gpu.emitting = true
	lapis.add_child(_gpu)


func _bangun_bayangan(pojok: Vector2) -> void:
	var lapis: CanvasLayer = _lapis("PanelBayangan", LAYER_LAIN)
	_kotak(lapis, pojok, Vector2(PANEL_LEBAR, PANEL_TINGGI), Palette.TEXT_2, "Latar")
	_sprite_kontrol = _pemain(lapis, pojok + PEMAIN_KONTROL, "PemainKontrol")
	_sprite_shader = _pemain(lapis, pojok + PEMAIN_SHADER, "PemainShader")
	var bahan: ShaderMaterial = ShaderMaterial.new()
	bahan.shader = load(BERKAS_SHADER) as Shader
	bahan.set_shader_parameter(&"warna_bayangan", Palette.BAYANGAN_CONTOH)
	bahan.set_shader_parameter(&"alpha_penanda", float(ALPHA_PENANDA_8) / SKALA_8)
	_sprite_shader.material = bahan


# --- Pengukuran ---

func _ukur() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	var tangkap: String = ""
	for a: String in argumen:
		if a.begins_with("--tangkap="):
			tangkap = a.trim_prefix("--tangkap=")
	var headless: bool = DisplayServer.get_name() == "headless"
	await get_tree().process_frame
	await get_tree().process_frame
	var mulai_us: int = Time.get_ticks_usec()
	var mulai_frame: int = Engine.get_process_frames()
	while float(Time.get_ticks_usec() - mulai_us) / 1000000.0 < durasi_ukur_detik:
		await get_tree().process_frame
	var detik: float = float(Time.get_ticks_usec() - mulai_us) / 1000000.0
	var fps: float = float(Engine.get_process_frames() - mulai_frame) / maxf(detik, 0.000001)
	var gambar: Image = null
	if not headless:
		await RenderingServer.frame_post_draw
		gambar = get_viewport().get_texture().get_image()
	var akhiran: String = "renderer=%s gpu=\"%s\" fps=%.1f" % [RenderingServer.get_current_rendering_method(), RenderingServer.get_video_adapter_name(), fps]
	_cetak("perangkat: display=%s os=%s model=\"%s\" renderer=%s driver=%s gpu=\"%s\" vendor=\"%s\" api=\"%s\" jendela=%s viewport=%s skala=%s fps_rata=%.1f selama %.1f detik" % [DisplayServer.get_name(), OS.get_name(), OS.get_model_name(), RenderingServer.get_current_rendering_method(), RenderingServer.get_current_rendering_driver_name(), RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor(), RenderingServer.get_video_adapter_api_version(), get_window().size, get_viewport_rect().size, get_viewport().get_final_transform().get_scale(), fps, detik])
	if gambar == null or gambar.is_empty():
		var alasan: String = "tidak bisa dibaca headless" if headless else "tidak bisa dibaca (tekstur viewport kosong)"
		_tulis("light2d", "PointLight2D (bayangan PCF5) + LightOccluder2D + CanvasModulate terpasang; piksel %s" % alasan, akhiran)
		_tulis("glow", "WorldEnvironment latar Canvas, glow menyala %s; piksel %s" % [_lingkungan.environment.glow_enabled, alasan], akhiran)
		_tulis("cpu_partikel", "CPUParticles2D memancar %s; piksel %s" % [_cpu.emitting, alasan], akhiran)
		_tulis("gpu_partikel", "GPUParticles2D memancar %s; piksel %s" % [_gpu.emitting, alasan], akhiran)
		_tulis("shader_bayangan", alasan, akhiran)
	else:
		_ukur_cahaya(gambar, akhiran)
		_ukur_glow(gambar, akhiran)
		_ukur_partikel(gambar, akhiran)
		_ukur_bayangan(gambar, akhiran)
	_cetak("ringkasan: light2d=%s glow=%s cpu_partikel=%s gpu_partikel=%s shader_bayangan=%s %s" % [_hasil["light2d"], _hasil["glow"], _hasil["cpu_partikel"], _hasil["gpu_partikel"], _hasil["shader_bayangan"], akhiran])
	if not tangkap.is_empty() and gambar != null and not gambar.is_empty():
		var galat: int = gambar.save_png(tangkap)
		_cetak("tangkapan layar %dx%d ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), tangkap, galat])
	selesai.emit()
	if boleh_keluar and (headless or not tangkap.is_empty() or argumen.has("--keluar")):
		get_tree().quit()


func _cetak(teks: String) -> void:
	var baris: String = "%s %s" % [AWALAN, teks]
	_laporan.append(baris)
	print(baris)


## Satu baris hasil fitur; kata pertama `ringkas` (atau seluruhnya bila tanpa titik dua) masuk ringkasan.
func _tulis(fitur: String, teks: String, akhiran: String) -> void:
	_hasil[fitur] = "tidak_terbaca" if teks.contains("tidak bisa dibaca") else teks.get_slice(" ", 0)
	_cetak("%s: %s | %s" % [fitur, teks, akhiran])


## Warna piksel jendela di titik global `titik` (piksel game, diambil di tengah bloknya). Probe tanpa kamera dan semua
## CanvasLayer bertransformasi identitas, jadi jendela = transformasi akhir viewport (skala stretch) x posisi global.
func _piksel(gambar: Image, titik: Vector2) -> Color:
	var jendela: Vector2 = get_viewport().get_final_transform() * (titik + Vector2(0.5, 0.5))
	var x: int = clampi(int(jendela.x), 0, gambar.get_width() - 1)
	var y: int = clampi(int(jendela.y), 0, gambar.get_height() - 1)
	return gambar.get_pixel(x, y)


func _ukur_cahaya(gambar: Image, akhiran: String) -> void:
	var pojok: Vector2 = _panel(0)
	var terang: float = _terang(_piksel(gambar, pojok + LAMPU + UKUR_TERANG))
	var gelap: float = _terang(_piksel(gambar, pojok + SAMPEL_POJOK))
	var bayangan: float = _terang(_piksel(gambar, pojok + LAMPU + UKUR_BAYANGAN))
	var banding: float = _terang(_piksel(gambar, pojok + LAMPU - UKUR_BAYANGAN))
	var menyala: bool = terang - gelap > BEDA_TERANG_MIN
	var berbayang: bool = banding - bayangan > BEDA_BAYANGAN_MIN
	var hasil_teks: String = "ya" if menyala and berbayang else ("cahaya_tanpa_bayangan" if menyala else "tidak")
	_tulis("light2d", "%s (terang dekat lampu %.3f, tepi gelap %.3f; bayangan occluder %.3f vs sisi lain %.3f)" % [hasil_teks, terang, gelap, bayangan, banding], akhiran)


func _ukur_glow(gambar: Image, akhiran: String) -> void:
	var pojok: Vector2 = _panel(1)
	var inti: Color = _piksel(gambar, pojok + GLOW_KOTAK_PUSAT)
	var dekat: float = _terang(_piksel(gambar, pojok + GLOW_KOTAK_PUSAT - Vector2(0, GLOW_KOTAK_SISI / 2 + GLOW_UKUR_JARAK)))
	var jauh: float = _terang(_piksel(gambar, pojok + SAMPEL_POJOK))
	var hasil_teks: String = "ya" if dekat - jauh > BEDA_GLOW_MIN else "tidak"
	_tulis("glow", "%s (halo %d px di luar kotak %.3f vs latar jauh %.3f; inti #%s)" % [hasil_teks, int(GLOW_UKUR_JARAK), dekat, jauh, inti.to_html(false)], akhiran)


func _ukur_partikel(gambar: Image, akhiran: String) -> void:
	var pojok: Vector2 = _panel(2)
	var setengah: float = PANEL_LEBAR / 2
	var cpu: int = _hitung_warna(gambar, Rect2(pojok, Vector2(setengah, PANEL_TINGGI)), Palette.ACCENT)
	var gpu: int = _hitung_warna(gambar, Rect2(pojok + Vector2(setengah, 0), Vector2(setengah, PANEL_TINGGI)), Palette.OK)
	_tulis("cpu_partikel", "%s (%d piksel game ACCENT terlihat, memancar %s, %d partikel)" % ["ya" if cpu > 0 else "tidak", cpu, _cpu.emitting, _cpu.amount], akhiran)
	_tulis("gpu_partikel", "%s (%d piksel game OK terlihat, memancar %s, %d partikel)" % ["ya" if gpu > 0 else "tidak", gpu, _gpu.emitting, _gpu.amount], akhiran)


## Jumlah piksel game di `kotak` yang warnanya sama dengan `warna` (toleransi `TOLERANSI_WARNA`).
func _hitung_warna(gambar: Image, kotak: Rect2, warna: Color) -> int:
	var jumlah: int = 0
	for y: int in range(int(kotak.position.y), int(kotak.end.y)):
		for x: int in range(int(kotak.position.x), int(kotak.end.x)):
			if cocok(_piksel(gambar, Vector2(x, y)), warna, TOLERANSI_WARNA):
				jumlah += 1
	return jumlah


func _ukur_bayangan(gambar: Image, akhiran: String) -> void:
	var latar: Color = _piksel(gambar, _panel(3) + SAMPEL_POJOK)
	var kalibrasi: bool = cocok(latar, Palette.TEXT_2, TOLERANSI_WARNA)
	var tekstur: Texture2D = _sprite_kontrol.sprite_frames.get_frame_texture(ANIMASI, 0)
	var sel: Image = tekstur.get_image() if tekstur != null else null
	if sel == null or sel.is_empty():
		_tulis("shader_bayangan", "tidak cocok (gambar sprite tidak bisa dibaca dari GPU)", akhiran)
		return
	var penanda: Array[Vector2i] = []
	var lain: Array[Vector2i] = []
	for y: int in range(sel.get_height()):
		for x: int in range(sel.get_width()):
			var c: Color = sel.get_pixel(x, y)
			if c.a8 == 0:
				continue
			if adalah_penanda(c):
				penanda.append(Vector2i(x, y))
			else:
				lain.append(Vector2i(x, y))
	var alpha: float = float(ALPHA_PENANDA_8) / SKALA_8
	var harapan_shader: Color = campur(latar, Palette.BAYANGAN_CONTOH, alpha)
	var harapan_kontrol: Color = campur(latar, WARNA_PENANDA, alpha)
	var salah_penanda: Array[String] = []
	var kontrol_salah: int = 0
	var diperiksa: int = 0
	var langkah: int = maxi(1, penanda.size() / SAMPEL_PENANDA_MAKS)
	var ukuran: Vector2 = Vector2(sel.get_width(), sel.get_height())
	for i: int in range(0, penanda.size(), langkah):
		var t: Vector2 = Vector2(penanda[i]) - ukuran / 2
		var c_shader: Color = _piksel(gambar, _sprite_shader.global_position + t)
		var c_kontrol: Color = _piksel(gambar, _sprite_kontrol.global_position + t)
		diperiksa += 1
		if not cocok(c_shader, harapan_shader, TOLERANSI_WARNA):
			salah_penanda.append("%s: #%s (harapan #%s)" % [penanda[i], c_shader.to_html(false), harapan_shader.to_html(false)])
		if not cocok(c_kontrol, harapan_kontrol, TOLERANSI_WARNA):
			kontrol_salah += 1
	var berubah: Array[String] = []
	var langkah_lain: int = maxi(1, lain.size() / SAMPEL_LAIN_MAKS)
	var diperiksa_lain: int = 0
	for i: int in range(0, lain.size(), langkah_lain):
		var t: Vector2 = Vector2(lain[i]) - ukuran / 2
		var a: Color = _piksel(gambar, _sprite_shader.global_position + t)
		var b: Color = _piksel(gambar, _sprite_kontrol.global_position + t)
		diperiksa_lain += 1
		if not cocok(a, b, TOLERANSI_SAMA):
			berubah.append("%s: #%s vs #%s" % [lain[i], a.to_html(false), b.to_html(false)])
	var lolos: bool = kalibrasi and diperiksa > 0 and salah_penanda.is_empty() and berubah.is_empty() and diperiksa_lain > 0
	_tulis("shader_bayangan", "%s (penanda %d diperiksa, salah %d %s; kontrol hitam sesuai campuran %d/%d; piksel lain %d diperiksa, berubah %d %s; latar #%s kalibrasi %s; warna bayangan #%s alpha %d/255)" % ["cocok" if lolos else "tidak cocok", diperiksa, salah_penanda.size(), salah_penanda.slice(0, 2), diperiksa - kontrol_salah, diperiksa, diperiksa_lain, berubah.size(), berubah.slice(0, 2), latar.to_html(false), "cocok" if kalibrasi else "tidak cocok", Palette.BAYANGAN_CONTOH.to_html(false), ALPHA_PENANDA_8], akhiran)


# --- Pembantu murni (dites di tests/tes_cek_render.gd) ---

## Kecerahan piksel (rata-rata RGB), 0..1.
static func _terang(c: Color) -> float:
	return (c.r + c.g + c.b) / 3.0


## True bila `c` adalah piksel penanda bayangan tanah: RGB 0 dan alpha 71/255 (ART_DIRECTION 2.1 no. 5).
static func adalah_penanda(c: Color) -> bool:
	return c.r8 == 0 and c.g8 == 0 and c.b8 == 0 and c.a8 == ALPHA_PENANDA_8


## Warna `warna` dengan `alpha` di atas `latar` buram (campuran biasa ruang warna 2D), alpha hasil 1.
static func campur(latar: Color, warna: Color, alpha: float) -> Color:
	var hasil_campur: Color = latar.lerp(warna, alpha)
	hasil_campur.a = 1.0
	return hasil_campur


## True bila tiap kanal RGB `a` dan `b` berbeda tidak lebih dari `toleransi`.
static func cocok(a: Color, b: Color, toleransi: float) -> bool:
	return absf(a.r - b.r) <= toleransi + 0.000001 and absf(a.g - b.g) <= toleransi + 0.000001 and absf(a.b - b.b) <= toleransi + 0.000001
