#!/usr/bin/env python3
"""Uji mutasi QA untuk `tests/run_tests.gd` (loop Dev-QA, run 0A). Hanya pustaka standar Python 3.

Menerapkan satu per satu perubahan kecil (mutasi) pada sebuah SALINAN repo, menjalankan
`run_tests.gd` + `cek_keluaran_tes.py`, lalu mencetak apakah tes MERAH (mutasi tertangkap) atau
HIJAU (mutasi lolos = celah tes). Berkas dikembalikan ke isi semula setelah tiap mutasi.

JANGAN dijalankan pada repo kerja. Pakai klon sementara yang sudah di-import:

    git clone --branch <branch> <repo> /jalur/klon && cd /jalur/klon && godot --headless --import
    python3 tools/tests_cek/qa_mutasi.py /jalur/klon

Mutasi yang diharapkan HIJAU: batas sudut 22,5 / 67,5 "eksklusif" (setara karena toleransi) dan
RADAR_BG 0.60 -> 0.6 (nilai sama). Mutasi yang lolos tetapi merupakan celah tes, dicatat di LOG.md:
abs pada pedal_rate (Q-002); zoom kamera pecahan, Color.RED, string "kiri", teks pemain di skrip
(Q-003); toleransi sudut 0.08 dan is_zero_approx (Q-007).
"""
import subprocess, sys, os, re
ROOT = sys.argv[1]
os.chdir(ROOT)
os.makedirs("build", exist_ok=True)
M = []
def m(f, old, new, desc, count=1):
    M.append((f, old, new, desc, count))

# config.gd
m("scripts/config.gd", "KECEPATAN_SANTAI_UD: float = 3.0", "KECEPATAN_SANTAI_UD: float = 3.1", "config: kecepatan santai 3.0->3.1")
m("scripts/config.gd", "UBIN_UNIT_DUNIA: int = 32", "UBIN_UNIT_DUNIA: int = 33", "config: unit dunia 32->33")
m("scripts/config.gd", "REM_TAHAN_DETIK: float = 0.25", "REM_TAHAN_DETIK: float = 0.3", "config: rem tahan 0.25->0.3")
m("scripts/config.gd", "ZONA_MATI_STICK: float = 0.15", "ZONA_MATI_STICK: float = 0.16", "config: zona mati 0.15->0.16")
m("scripts/config.gd", "SPRITE_AMBANG_CEPAT: float = 0.33", "SPRITE_AMBANG_CEPAT: float = 0.34", "config: ambang cepat 0.33->0.34")
m("scripts/config.gd", "SPRITE_AMBANG_NGEBUT: float = 0.80", "SPRITE_AMBANG_NGEBUT: float = 0.79", "config: ambang ngebut 0.80->0.79")
m("scripts/config.gd", "SPRITE_SUDUT_SERONG_DERAJAT: float = 22.5", "SPRITE_SUDUT_SERONG_DERAJAT: float = 23.0", "config: sudut serong 22.5->23")
m("scripts/config.gd", "SPRITE_SUDUT_SIKU_DERAJAT: float = 67.5", "SPRITE_SUDUT_SIKU_DERAJAT: float = 67.0", "config: sudut siku 67.5->67")
m("scripts/config.gd", "SPRITE_SUDUT_TOLERANSI_DERAJAT: float = 0.000001", "SPRITE_SUDUT_TOLERANSI_DERAJAT: float = 0.0", "config: toleransi sudut 1e-6->0")
m("scripts/config.gd", "SPRITE_SUDUT_TOLERANSI_DERAJAT: float = 0.000001", "SPRITE_SUDUT_TOLERANSI_DERAJAT: float = 0.08", "config: toleransi sudut 1e-6->0.08")
m("scripts/config.gd", "LAYAR_SKALA_PIKSEL: int = 3", "LAYAR_SKALA_PIKSEL: int = 4", "config: skala piksel 3->4")
m("scripts/config.gd", "KECEPATAN_LATERAL_UD: float = 3.0", "KECEPATAN_LATERAL_UD: float = 3.5", "config: lateral 3.0->3.5")
m("scripts/config.gd", "const AKSELERASI_UD2: float = 3.0", "const AKSELERASI_UD2: float = 3", "config: float tanpa titik (aturan parser)")
m("scripts/config.gd", "const UBIN_TINGGI_PX: int = 32", "const UBIN_TINGGI_PX: int = 32 * 1", "config: ekspresi")
m("scripts/config.gd", "const UBIN_TINGGI_PX: int = 32", "const UBIN_TINGGI_PX: int = \\\n\t32", "config: multi-baris (backslash)")
# palette
m("scripts/ui/palette.gd", 'Color("#1C130F")', 'Color("#1C130E")', "palette: UI_BG 1 digit")
m("scripts/ui/palette.gd", 'Color("#0E0A1C", 0.84)', 'Color("#0E0A1C", 0.85)', "palette: HUD_PANEL alpha 0.84->0.85")
m("scripts/ui/palette.gd", 'Color("#0E0A1C", 0.60)', 'Color("#0E0A1C", 0.6)', "palette: RADAR_BG alpha 0.60 -> 0.6 (identik, harus tetap hijau)")
m("scripts/ui/palette.gd", 'Color("#969AA0")', 'Color("#969AA1")', "palette: RADAR_BUKAN 1 digit")
m("scripts/ui/palette.gd", "const WARN: Color = Color(\"#FF8A3D\")", "const WARN: Color = Color(\"#FF8A3D\")\nconst EXTRA: Color = Color(\"#FFFFFF\")", "palette: token karangan")
# loper_anim
m("scripts/systems/loper_anim.gd", "-2: \"kiri\",", "-2: \"kanan\",", "anim: nama arah -2 'kiri'->'kanan'")
m("scripts/systems/loper_anim.gd", "1: \"serong_kanan\",", "1: \"serong_kiri\",", "anim: arah 1 serong_kanan->serong_kiri")
m("scripts/systems/loper_anim.gd", 'NAMA_TINGKAT: Array[String] = ["santai", "cepat", "ngebut"]', 'NAMA_TINGKAT: Array[String] = ["cepat", "santai", "ngebut"]', "anim: tukar santai/cepat")
m("scripts/systems/loper_anim.gd", "return besar if lateral > 0.0 else -besar", "return besar if lateral < 0.0 else -besar", "anim: tanda lateral dibalik")
m("scripts/systems/loper_anim.gd", "if k <= Config.SPRITE_AMBANG_NGEBUT:", "if k < Config.SPRITE_AMBANG_NGEBUT:", "anim: batas 0.80 eksklusif")
m("scripts/systems/loper_anim.gd", "if k < Config.SPRITE_AMBANG_CEPAT:", "if k <= Config.SPRITE_AMBANG_CEPAT:", "anim: batas 0.33 eksklusif")
m("scripts/systems/loper_anim.gd", "if sudut < Config.SPRITE_SUDUT_SERONG_DERAJAT - Config.SPRITE_SUDUT_TOLERANSI_DERAJAT:", "if sudut <= Config.SPRITE_SUDUT_SERONG_DERAJAT - Config.SPRITE_SUDUT_TOLERANSI_DERAJAT:", "anim: batas 22.5 eksklusif")
m("scripts/systems/loper_anim.gd", "if sudut <= Config.SPRITE_SUDUT_SIKU_DERAJAT + Config.SPRITE_SUDUT_TOLERANSI_DERAJAT:", "if sudut < Config.SPRITE_SUDUT_SIKU_DERAJAT + Config.SPRITE_SUDUT_TOLERANSI_DERAJAT:", "anim: batas 67.5 eksklusif")
m("scripts/systems/loper_anim.gd", "var sudut: float = rad_to_deg(atan2(absf(lateral), maju))", "var sudut: float = rad_to_deg(atan2(absf(lateral), absf(maju)))", "anim: mundur dianggap maju (absf maju)")
m("scripts/systems/loper_anim.gd", "return maxf(laju_kayuh, 0.0)", "return absf(laju_kayuh)", "anim: skala_kayuh absf bukan maxf")
m("scripts/systems/loper_anim.gd", "return clampi(arah, -2, 2)", "return clampi(arah, -2, 3)", "anim: jepit arah -2..3")
m("scripts/systems/loper_anim.gd", "if is_zero_approx(lateral):\n\t\treturn 0", "if lateral == 0.0:\n\t\treturn 0", "anim: is_zero_approx -> == 0")
m("scripts/systems/loper_anim.gd", "if is_nan(kekuatan):\n\t\treturn 0", "if false:\n\t\treturn 0", "anim: hapus guard NaN stick")
# sprite
m("scripts/entities/loper_sprite.gd", "var nama: StringName = LoperAnim.nama_animasi(speed_level, steer)", "var nama: StringName = LoperAnim.nama_animasi(steer, speed_level)", "sprite: argumen terbalik")
m("scripts/entities/loper_sprite.gd", "set_frame_and_progress(frame_lama, progres_lama)", "pass", "sprite: fase kayuh tidak dijaga")
m("scripts/entities/loper_sprite.gd", "if not is_playing():\n\t\tplay(animation)", "pass", "sprite: tidak play() di _ready")
m("scripts/entities/loper_sprite.gd", "speed_scale = LoperAnim.skala_kayuh(nilai)", "speed_scale = nilai", "sprite: pedal_rate langsung ke speed_scale")
m("scripts/entities/loper_sprite.gd", "speed_level = LoperAnim.jepit_tingkat(nilai)", "speed_level = nilai", "sprite: speed_level tidak dijepit")
m("scripts/entities/loper_sprite.gd", "steer = LoperAnim.jepit_arah(nilai)", "steer = nilai", "sprite: steer tidak dijepit")
# assets
m("assets/sprites/loper/loper_agen_frames.tres", '"speed": 12.0', '"speed": 11.0', "tres: fps ngebut 12->11 (semua)", count=0)
m("assets/sprites/loper/loper_agen_frames.tres", '"loop": true', '"loop": false', "tres: loop false (satu)", count=1)
m("assets/sprites/loper/loper_agen.json", '"fps": 8', '"fps": 9', "json: fps 8->9 (satu)", count=1)
m("assets/sprites/loper/loper_agen.png.import", "compress/mode=0", "compress/mode=1", "import: loper lossy")
m("assets/sprites/loper/loper_agen.png.import", "mipmaps/generate=false", "mipmaps/generate=true", "import: loper mipmap")
m("assets/sprites/_placeholder/tile_graybox_aspal.png.import", "compress/mode=0", "compress/mode=2", "import: aspal VRAM compressed")
# project
m("project.godot", 'window/stretch/scale_mode="integer"', 'window/stretch/scale_mode="fractional"', "project: scale_mode fractional")
m("project.godot", 'window/stretch/aspect="expand"', 'window/stretch/aspect="keep"', "project: aspect keep")
m("project.godot", "2d/snap/snap_2d_transforms_to_pixel=true", "2d/snap/snap_2d_transforms_to_pixel=false", "project: snap off")
m("project.godot", "window/handheld/orientation=0", "window/handheld/orientation=4", "project: sensor landscape")
m("project.godot", "textures/canvas_textures/default_texture_filter=0", "textures/canvas_textures/default_texture_filter=1", "project: filter linear")
m("project.godot", "window/size/viewport_width=640", "window/size/viewport_width=800", "project: viewport 800")
# scene
m("scenes/entities/loper_agen.tscn", "texture_filter = 1\n", "", "tscn pemain: hapus texture_filter=1 (bawaan proyek tetap Nearest)")
m("scenes/entities/loper_agen.tscn", "offset = Vector2(0, -17)", "offset = Vector2(0, -16)", "tscn pemain: offset -17 -> -16")
m("scenes/dev/graybox.tscn", "position = Vector2(80, -72)", "position = Vector2(80.5, -72)", "graybox: kamera tidak bulat")
m("scenes/dev/graybox.tscn", "speed_level = 1", "speed_level = 2", "graybox: pemain ngebut (bukan cepat)")
m("scenes/dev/graybox.tscn", 'name="Tanah" type="Node2D" parent="."]\ntexture_filter = 1', 'name="Tanah" type="Node2D" parent="."]\ntexture_filter = 2', "graybox: Tanah filter linear")
m("scenes/dev/graybox.tscn", '[node name="Kamera" type="Camera2D" parent="."]\nposition', '[node name="Kamera" type="Camera2D" parent="."]\nzoom = Vector2(1.5, 1.5)\nposition', "graybox: zoom kamera pecahan 1.5")
m("scenes/dev/graybox.tscn", '[node name="Tanah" type="Node2D" parent="."]', '[node name="Tanah" type="Node2D" parent="."]\nscale = Vector2(1.5, 1.5)', "graybox: skala Tanah 1.5")
m("scenes/dev/graybox.tscn", '[node name="Objek" type="Node2D" parent="."]\ny_sort_enabled = true', '[node name="Objek" type="Node2D" parent="."]\nmodulate = Color(1, 0, 0, 1)\ny_sort_enabled = true', "graybox: warna literal Color(1,0,0)")
# hex di skrip
m("scripts/entities/loper_sprite.gd", "func _ready() -> void:", "func _ready() -> void:\n\tvar w: Color = Color.RED", "sprite: Color.RED (konstanta bernama)")
m("scripts/entities/loper_sprite.gd", "func _ready() -> void:", "func _ready() -> void:\n\tvar w: int = 15", "sprite: angka ajaib 15")
m("scripts/entities/loper_sprite.gd", "func _ready() -> void:", "func _ready() -> void:\n\tvar jarak: float = 0.5", "sprite: angka ajaib 0.5")
m("scripts/entities/loper_sprite.gd", "func _ready() -> void:", "func _ready() -> void:\n\tvar sisi: String = \"kiri\"", "sprite: string 'kiri' untuk sisi")
m("scripts/entities/loper_sprite.gd", "func _ready() -> void:", "func _ready() -> void:\n\tvar teks: String = \"Halo pemain\"\n\tprint(teks)", "sprite: teks pemain di skrip")
# gitignore
m(".gitignore", "builds/\n", "", "gitignore: hapus builds/")

def jalankan():
    p = subprocess.run("godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/m.log >/dev/null; python3 tools/cek_keluaran_tes.py build/m.log", shell=True, capture_output=True, text=True, timeout=120)
    log = open("build/m.log", errors="replace").read()
    return p.returncode, log, p.stdout

hijau_awal = jalankan()
print("baseline: exit pemeriksa", hijau_awal[0])
hasil = []
for f, old, new, desc, count in M:
    teks = open(f).read()
    if old not in teks:
        print("TIDAK DITEMUKAN: %s -- %s" % (f, desc)); continue
    if count == 0:
        mut = teks.replace(old, new)
    else:
        mut = teks.replace(old, new, count)
    open(f, "w").write(mut)
    try:
        kode, log, out = jalankan()
    except subprocess.TimeoutExpired:
        kode, log, out = 99, "TIMEOUT", "TIMEOUT"
    finally:
        open(f, "w").write(teks)
    gagal = [l for l in log.splitlines() if l.startswith("GAGAL")]
    se = [l for l in log.splitlines() if "SCRIPT ERROR" in l]
    status = "MERAH" if kode != 0 else "HIJAU"
    print("%-6s | %-62s | gagal=%d script_err=%d | %s" % (status, desc, len(gagal), len(se), (gagal[0][:110] if gagal else (se[0][:110] if se else ""))))
