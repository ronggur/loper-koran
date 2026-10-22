class_name TesExport
extends RefCounted
## Tes export Android run 0C (AC-19, AC-23): isi `export_presets.cfg`, `.gitignore`, berkas yang dilacak git,
## dan penjaga `docs/SETUP_ANDROID.md` (AC-20). Run fase1c-perapian (D-4, QA-004): berkas probe render dikecualikan dari APK
## normal, dan polanya sama dengan yang dilepas sementara oleh `tools/ekspor_cek_render.py`.
##
## Dipanggil dari `tests/run_tests.gd` (`TesExport.new(check, judul).jalankan()`), memakai `check` milik runner supaya
## hitungan lolos/gagal dan ringkasan tetap satu. Tes hanya membaca berkas teks di repo: TIDAK butuh APK, export templates,
## Java, atau Android SDK (CI tidak punya satu pun). Satu-satunya program luar adalah `git` (ada di CI dan di mesin dev).
## Setiap penjaga dibuktikan dengan contoh buruk sintetis yang harus ditolak, bukan hanya berkas asli yang lolos.

const BERKAS_PRESET: String = "res://export_presets.cfg"
const BERKAS_GITIGNORE: String = "res://.gitignore"
const BERKAS_SETUP: String = "res://docs/SETUP_ANDROID.md"
const BERKAS_README_DOCS: String = "res://docs/README.md"
const BERKAS_IKON: String = "res://icon.svg"
const BERKAS_PALET: String = "res://scripts/ui/palette.gd"

## Nama package final (pilihan user 2026-10-09, ROADMAP 4b). Tidak boleh diganti: terkunci setelah upload pertama ke Play Console.
const PACKAGE_FINAL: String = "com.rmh.kring"
const NAMA_PRESET: String = "Android"
const VERSI_KODE: int = 1
const VERSI_NAMA: String = "0.1.0"
const ARSITEKTUR_AKTIF: String = "architectures/arm64-v8a"
const ARSITEKTUR_MATI: Array[String] = ["architectures/armeabi-v7a", "architectures/x86", "architectures/x86_64"]
## Folder yang tidak boleh ikut APK walau berisi skrip (tests/) atau berkas dev lain.
const FILTER_DIKECUALIKAN: Array[String] = ["docs/*", "tests/*", "tools/*", "build/*", "builds/*"]
## Berkas konten dan scene alur hari yang WAJIB ikut paket (run fase4a-koran-hari AC-28): data misi dan headline, terjemahan hasil impor, dan scene baru.
const JALUR_WAJIB_IKUT: Array[String] = [
	"assets/data/missions/perumahan.json", "assets/data/headlines/utama.json", "assets/data/headlines/ringan.json", "assets/data/headlines/lanjutan.json",
	"translations/konten.id.translation", "translations/ui.id.translation", "scenes/hari/hari.tscn", "scenes/koran/halaman_koran.tscn", "scenes/rute/rute.tscn",
	"scripts/autoload/save_manager.gd",
	# Run fase4b-misi-kucing (AC-22): sheet kucing, scene kucing dan tutorial, bunyi misi, dan skrip misi.
	"assets/sprites/npc/mission_kucing_sheet.png", "scenes/entities/kucing_misi.tscn", "scenes/ui/tutorial.tscn", "scripts/systems/mission_manager.gd", "scripts/systems/rencana_misi.gd",
	"assets/audio/sfx/mission/sfx_mis_meong_01.wav", "assets/audio/sfx/mission/sfx_mis_terlihat_01.wav", "assets/audio/sfx/mission/sfx_mis_selesai_01.wav", "assets/audio/sfx/mission/sfx_mis_gagal_01.wav",
	# Run fase6a1-bengkel-kondisi (AC-30): data upgrade bengkel dan skrip kondisi, efek, ekonomi, serta pemuat data upgrade (scene, bunyi, dan skrip bengkel di bagian B).
	"assets/data/shop/upgrades.json", "scripts/systems/bike_condition.gd", "scripts/systems/efek_kondisi.gd", "scripts/systems/economy.gd", "scripts/systems/data_toko.gd", "scripts/systems/pemuat_toko.gd",
	# Bagian B: scene dan skrip bengkel, kondisi di rute, dan lima bunyi kondisi.
	"scenes/bengkel/bengkel.tscn", "scripts/ui/layar_bengkel.gd", "scripts/ui/kotak_kondisi.gd", "scripts/systems/kondisi_rute.gd", "scripts/systems/tampil_kondisi.gd", "scripts/systems/bunyi_kondisi.gd",
	"assets/audio/sfx/condition/sfx_cond_rantai_berisik_01.wav", "assets/audio/sfx/condition/sfx_cond_rem_berdecit_01.wav", "assets/audio/sfx/condition/sfx_cond_ban_mendesis_01.wav",
	"assets/audio/sfx/condition/sfx_cond_servis_01.wav", "assets/audio/sfx/condition/sfx_cond_upgrade_01.wav",
	# Run fase5a-pasang-aset-gelombang1 (AC-16): sprite koran, efek, kilau, dan ubin enam kolom beserta remap .import, dan skrip pemakainya. Aset gelombang 1 yang tidak dipasang tidak ada di repo (uji_aset_pasang_gelombang1.py).
	"assets/sprites/props/prop_koran_putar.png", "assets/sprites/props/prop_koran_putar.png.import", "assets/sprites/props/prop_koran_bayangan.png", "assets/sprites/props/prop_koran_bayangan.png.import", "assets/sprites/props/prop_koran_teras.png", "assets/sprites/props/prop_koran_teras.png.import", "assets/sprites/props/prop_koran_rumput.png", "assets/sprites/props/prop_koran_rumput.png.import", "assets/sprites/props/prop_koran_kotak_surat.png", "assets/sprites/props/prop_koran_kotak_surat.png.import", "assets/sprites/props/prop_koran_terlipat.png", "assets/sprites/props/prop_koran_terlipat.png.import",
	"assets/sprites/vfx/vfx_debu_roda.png", "assets/sprites/vfx/vfx_debu_roda.png.import", "assets/sprites/vfx/vfx_garis_kecepatan_a.png", "assets/sprites/vfx/vfx_garis_kecepatan_a.png.import", "assets/sprites/vfx/vfx_garis_kecepatan_b.png", "assets/sprites/vfx/vfx_garis_kecepatan_b.png.import", "assets/sprites/vfx/vfx_garis_kecepatan_c.png", "assets/sprites/vfx/vfx_garis_kecepatan_c.png.import", "assets/sprites/vfx/vfx_bintang_kena.png", "assets/sprites/vfx/vfx_bintang_kena.png.import", "assets/sprites/vfx/vfx_koin_tip.png", "assets/sprites/vfx/vfx_koin_tip.png.import", "assets/sprites/vfx/mission_kilau.png", "assets/sprites/vfx/mission_kilau.png.import",
	"assets/sprites/tiles/perumahan/tile_perumahan_rumput_seberang.png", "assets/sprites/tiles/perumahan/tile_perumahan_rumput_seberang.png.import", "assets/sprites/tiles/perumahan/tile_perumahan_trotoar_seberang.png", "assets/sprites/tiles/perumahan/tile_perumahan_trotoar_seberang.png.import", "assets/sprites/tiles/perumahan/tile_perumahan_aspal_seberang.png", "assets/sprites/tiles/perumahan/tile_perumahan_aspal_seberang.png.import", "assets/sprites/tiles/perumahan/tile_perumahan_aspal_dekat.png", "assets/sprites/tiles/perumahan/tile_perumahan_aspal_dekat.png.import", "assets/sprites/tiles/perumahan/tile_perumahan_trotoar_dekat.png", "assets/sprites/tiles/perumahan/tile_perumahan_trotoar_dekat.png.import", "assets/sprites/tiles/perumahan/tile_perumahan_rumput_dekat.png", "assets/sprites/tiles/perumahan/tile_perumahan_rumput_dekat.png.import", "assets/sprites/tiles/perumahan/tile_perumahan_rumput_1.png", "assets/sprites/tiles/perumahan/tile_perumahan_rumput_1.png.import",
	"scripts/systems/def_sprite.gd", "scripts/systems/permukaan_koran.gd", "scripts/systems/sprite_koran.gd", "scripts/systems/vfx_sepeda.gd", "scripts/systems/vfx_antaran.gd", "scripts/ui/gambar_sprite.gd", "scripts/entities/vfx_sepeda_gambar.gd",
	# Run fase5b-tembok-dekor bagian C (AC-17): dekor (tong sampah, pohon, lampu mati), enam ubin khusus beserta remap .import, skrip pemakainya, dan sembilan segmen rute.
	# Tembok sisi dekat run 5B dilepas run fase5d-sisi-dekat (P-1): sprite dan skripnya tidak ada lagi (`JALUR_TIDAK_ADA_5B`).
	"assets/sprites/props/prop_tong_sampah_logam.png", "assets/sprites/props/prop_tong_sampah_logam.png.import",
	"assets/sprites/props/prop_pohon_rindang.png", "assets/sprites/props/prop_pohon_rindang.png.import", "assets/sprites/props/prop_pohon_glodokan.png", "assets/sprites/props/prop_pohon_glodokan.png.import", "assets/sprites/props/prop_pohon_ketapang.png", "assets/sprites/props/prop_pohon_ketapang.png.import",
	"assets/sprites/props/prop_lampu_lengan_seberang.png", "assets/sprites/props/prop_lampu_lengan_seberang.png.import", "assets/sprites/props/prop_lampu_lengan_dekat.png", "assets/sprites/props/prop_lampu_lengan_dekat.png.import", "assets/sprites/tiles/perumahan/tile_perumahan_rumput_2.png", "assets/sprites/tiles/perumahan/tile_perumahan_rumput_2.png.import",
	"assets/sprites/tiles/perumahan/tile_perumahan_rumput_3.png", "assets/sprites/tiles/perumahan/tile_perumahan_rumput_3.png.import", "assets/sprites/tiles/perumahan/tile_perumahan_trotoar_seberang_masuk.png", "assets/sprites/tiles/perumahan/tile_perumahan_trotoar_seberang_masuk.png.import", "assets/sprites/tiles/perumahan/tile_perumahan_rumput_seberang_masuk.png", "assets/sprites/tiles/perumahan/tile_perumahan_rumput_seberang_masuk.png.import",
	"assets/sprites/tiles/perumahan/tile_perumahan_trotoar_seberang_simbol.png", "assets/sprites/tiles/perumahan/tile_perumahan_trotoar_seberang_simbol.png.import", "assets/sprites/tiles/perumahan/tile_perumahan_trotoar_dekat_simbol.png", "assets/sprites/tiles/perumahan/tile_perumahan_trotoar_dekat_simbol.png.import",
	"scripts/systems/dekor_rute.gd", "scripts/systems/ubin_khusus.gd", "scripts/entities/dekor_daur.gd", "scripts/entities/tanah_daur.gd", "scripts/entities/rumah_daur_rute.gd",
	"assets/data/routes/perumahan/per_buka_01.json", "assets/data/routes/perumahan/per_buka_02.json", "assets/data/routes/perumahan/per_tengah_01.json", "assets/data/routes/perumahan/per_tengah_02.json", "assets/data/routes/perumahan/per_tengah_03.json", "assets/data/routes/perumahan/per_tengah_04.json", "assets/data/routes/perumahan/per_tengah_05.json", "assets/data/routes/perumahan/per_tutup_01.json", "assets/data/routes/perumahan/per_tutup_02.json",
]
## Run fase5c-animasi-simpang (AC-22): animasi pemain (jatuh lima arah, bangkit, berhenti) beserta SpriteFrames gabungan 68 animasi, sheet kucing
## 9 kolom, dan skrip pemakai baru. Ubin ujung kerb dan simpang (36 PNG) diambil dari `TesUbin.UBIN_5C` (literal) di `_test_aset_5c_ikut_paket`.
## Daftar ini ikut diperiksa `_pelanggaran_preset` (ada di repo dan tidak cocok dengan exclude_filter), sama seperti `JALUR_WAJIB_IKUT`.
const JALUR_WAJIB_IKUT_5C: Array[String] = [
	"assets/sprites/loper/loper_agen_frames.tres", "assets/sprites/loper/loper_agen_jatuh.png", "assets/sprites/loper/loper_agen_jatuh.png.import", "assets/sprites/loper/loper_agen_jatuh.json",
	"assets/sprites/loper/loper_agen_bangkit.png", "assets/sprites/loper/loper_agen_bangkit.png.import", "assets/sprites/loper/loper_agen_bangkit.json",
	"assets/sprites/loper/loper_agen_berhenti.png", "assets/sprites/loper/loper_agen_berhenti.png.import", "assets/sprites/loper/loper_agen_berhenti.json",
	"assets/sprites/npc/mission_kucing_sheet.png.import", "assets/sprites/npc/mission_kucing_sheet.json", "assets/sprites/tiles/perumahan/tile_perumahan.json",
	"scripts/systems/pose_kucing.gd", "scripts/systems/segmen_rute.gd", "scripts/systems/pemuat_rute.gd", "scripts/systems/route_builder.gd", "scripts/entities/kucing_misi.gd", "scripts/entities/loper_sprite.gd",
]
## PNG 5C yang dicek impor Lossless (selain 36 ubin dari `TesUbin.UBIN_5C`): tiga sheet pemain dan sheet kucing.
const PNG_5C_NON_UBIN: Array[String] = [
	"assets/sprites/loper/loper_agen_jatuh.png", "assets/sprites/loper/loper_agen_bangkit.png", "assets/sprites/loper/loper_agen_berhenti.png", "assets/sprites/npc/mission_kucing_sheet.png",
]
## Jumlah animasi `loper_agen_frames.tres` dan kolom sheet kucing sesudah PR #51 (literal; sama dengan `uji_bangun_frames.py` dan `uji_aset_kucing.py`).
const JUMLAH_ANIMASI_5C: int = 68
const KOLOM_KUCING_5C: int = 9
## Ubin yang TIDAK dipasang run 5C (D-2): ujung kerb sisi dekat (renderer tidak membuatnya) dan ubin simpang yang sama dengan jalan lurus
## (renderer tidak mengekspornya). Tidak boleh ada di repo. Nama disambung supaya pemindai rujukan `tes_ubin.gd` tidak menandai berkas ini.
const JALUR_TIDAK_ADA_5C: Array[String] = [
	"assets/sprites/tiles/perumahan/tile_perumahan_" + "trotoar_dekat_masuk_ujung.png", "assets/sprites/tiles/perumahan/tile_perumahan_" + "rumput_dekat_masuk_ujung.png",
	"assets/sprites/tiles/perumahan/tile_perumahan_" + "simpang_dekat_aspal_dekat_depan_2.png", "assets/sprites/tiles/perumahan/tile_perumahan_" + "simpang_dekat_aspal_seberang_mulut_1.png",
	"assets/sprites/tiles/perumahan/tile_perumahan_" + "simpang_seberang_aspal_seberang_depan_1.png", "assets/sprites/tiles/perumahan/tile_perumahan_" + "simpang_seberang_aspal_dekat_mulut_1.png",
]
## Run fase5d-sisi-dekat (AC-14): rumah sisi dekat baru (teras menjorok, tanpa kotak surat terpanggang), tiga sprite kotak surat, panel tip hari 3, kunci terjemahannya, dan skrip
## pelanggan dekat. Daftar ini ikut diperiksa `_pelanggaran_preset` (ada di repo dan tidak cocok dengan exclude_filter), sama seperti `JALUR_WAJIB_IKUT`.
const FOLDER_RUMAH_5D: String = "assets/sprites/houses/perumahan/"
## Nama dasar (tanpa ekstensi) enam rumah sisi dekat dan enam rumah sisi seberang yang dipasang; folder rumah tidak boleh berisi PNG lain (tembok dilepas, P-1).
const RUMAH_DEKAT_5D: Array[String] = [
	"house_perumahan_dekat_limasan_bukan", "house_perumahan_dekat_limasan_pelanggan", "house_perumahan_dekat_pelana_lintang_bukan",
	"house_perumahan_dekat_pelana_lintang_pelanggan", "house_perumahan_dekat_pelana_sejajar_bukan", "house_perumahan_dekat_pelana_sejajar_pelanggan",
]
const RUMAH_SEBERANG_5D: Array[String] = [
	"house_perumahan_limasan_bukan", "house_perumahan_limasan_pelanggan", "house_perumahan_pelana_bukan", "house_perumahan_pelana_pelanggan",
	"house_perumahan_sayap_bukan", "house_perumahan_sayap_pelanggan",
]
const PROP_KOTAK_SURAT_5D: Array[String] = ["prop_kotak_surat", "prop_kotak_surat_bukan"]
const JALUR_WAJIB_IKUT_5D: Array[String] = [
	"assets/sprites/houses/perumahan/house_perumahan_dekat_limasan_bukan.png", "assets/sprites/houses/perumahan/house_perumahan_dekat_limasan_bukan.png.import", "assets/sprites/houses/perumahan/house_perumahan_dekat_limasan_bukan.json",
	"assets/sprites/houses/perumahan/house_perumahan_dekat_limasan_pelanggan.png", "assets/sprites/houses/perumahan/house_perumahan_dekat_limasan_pelanggan.png.import", "assets/sprites/houses/perumahan/house_perumahan_dekat_limasan_pelanggan.json",
	"assets/sprites/houses/perumahan/house_perumahan_dekat_pelana_lintang_bukan.png", "assets/sprites/houses/perumahan/house_perumahan_dekat_pelana_lintang_bukan.png.import", "assets/sprites/houses/perumahan/house_perumahan_dekat_pelana_lintang_bukan.json",
	"assets/sprites/houses/perumahan/house_perumahan_dekat_pelana_lintang_pelanggan.png", "assets/sprites/houses/perumahan/house_perumahan_dekat_pelana_lintang_pelanggan.png.import", "assets/sprites/houses/perumahan/house_perumahan_dekat_pelana_lintang_pelanggan.json",
	"assets/sprites/houses/perumahan/house_perumahan_dekat_pelana_sejajar_bukan.png", "assets/sprites/houses/perumahan/house_perumahan_dekat_pelana_sejajar_bukan.png.import", "assets/sprites/houses/perumahan/house_perumahan_dekat_pelana_sejajar_bukan.json",
	"assets/sprites/houses/perumahan/house_perumahan_dekat_pelana_sejajar_pelanggan.png", "assets/sprites/houses/perumahan/house_perumahan_dekat_pelana_sejajar_pelanggan.png.import", "assets/sprites/houses/perumahan/house_perumahan_dekat_pelana_sejajar_pelanggan.json",
	"assets/sprites/props/prop_kotak_surat.png", "assets/sprites/props/prop_kotak_surat.png.import", "assets/sprites/props/prop_kotak_surat.json",
	"assets/sprites/props/prop_kotak_surat_bukan.png", "assets/sprites/props/prop_kotak_surat_bukan.png.import", "assets/sprites/props/prop_kotak_surat_bukan.json",
	"scenes/ui/panel_tip_sisi_dekat.tscn", "scripts/ui/panel_tip_sisi_dekat.gd", "scripts/systems/tip_sisi_dekat.gd", "translations/ui.id.translation", "translations/ui.csv",
	"scripts/systems/zona_sasaran.gd", "scripts/systems/medan_koran.gd", "scripts/systems/bantu_lempar.gd", "scripts/systems/radar_rute.gd", "scripts/systems/progres_rute.gd",
	"scripts/systems/sprite_rumah.gd", "scripts/systems/penutup_pemain.gd", "scripts/entities/rute_main.gd", "scripts/entities/hari_main.gd",
]
## Kunci teks tip hari 3 dan labelnya di `translations/ui.csv` (literal; dijaga juga `TesSisiDekatScene`).
const KUNCI_TIP_5D: Array[String] = ["RUTE_TIP_LABEL", "RUTE_TIP_SISI_DEKAT"]
## Jumlah rumah dekat `pelanggan_boleh` di sembilan segmen nyata (literal; dihitung dari berkas JSON, bukan dari kode).
const JUMLAH_DEKAT_BOLEH_5D: int = 34
## Aset yang TIDAK dipasang (D-1, D-4 run fase5b-tembok-dekor): tidak boleh ada di repo sehingga tidak ikut paket. Nama disambung supaya pemindai rujukan 5A tidak menandai berkas ini.
const JALUR_TIDAK_ADA_5B: Array[String] = [
	"assets/sprites/tiles/perumahan/tile_perumahan_" + "aspal_1.png", "assets/sprites/tiles/perumahan/tile_perumahan_" + "aspal_2.png", "assets/sprites/tiles/perumahan/tile_perumahan_" + "aspal_3.png",
	"assets/sprites/tiles/perumahan/tile_perumahan_" + "trotoar_dekat_masuk.png", "assets/sprites/tiles/perumahan/tile_perumahan_" + "rumput_dekat_masuk.png",
	"assets/sprites/props/prop_tong_sampah_" + "biru.png", "assets/sprites/props/prop_" + "pohon_beringin.png", "assets/sprites/props/prop_lampu_lengan_" + "seberang_nyala.png",
	"assets/sprites/props/prop_lampu_lengan_" + "dekat_nyala.png", "assets/sprites/tiles/perumahan/tile_perumahan_polisi_" + "tidur.png", "assets/sprites/tiles/perumahan/tile_perumahan_" + "zebra.png",
	# Run fase5d-sisi-dekat (P-1): lima sprite tembok sisi dekat dan dua skripnya dilepas.
	"assets/sprites/houses/perumahan/house_" + "tembok_polos.png", "assets/sprites/houses/perumahan/house_" + "tembok_bata.png", "assets/sprites/houses/perumahan/house_" + "tembok_besi.png",
	"assets/sprites/houses/perumahan/house_" + "tembok_pot.png", "assets/sprites/houses/perumahan/house_" + "tembok_tiang.png", "scripts/systems/varian_" + "tembok.gd", "scripts/systems/" + "tembok_dekat.gd",
]
## Berkas probe render (QA-004 run fase1b-umpan-balik, D-4 run fase1c-perapian): tidak ikut APK normal; build probe dibuat
## `tools/ekspor_cek_render.py` yang melepas pola ini sementara (`POLA_PROBE` di skrip itu harus sama persis).
const FILTER_PROBE: Array[String] = ["scenes/dev/cek_render.tscn", "scripts/dev/cek_render.gd", "assets/shaders/warna_bayangan.gdshader"]
const BERKAS_EKSPOR_PROBE: String = "res://tools/ekspor_cek_render.py"
## Spike rumah sisi dekat (run fase3c-hud-hasil AC-14): scene, skrip, dan aset graybox dev tidak ikut paket game. Berbeda dari probe render,
## tidak ada build khusus yang melepasnya (spike hanya dijalankan di editor/desktop).
const FILTER_SPIKE: Array[String] = ["scenes/dev/spike_sisi_dekat.tscn", "scripts/dev/spike_sisi_dekat.gd", "assets/sprites/_spike/*"]
## Potongan teks yang menandakan rujukan ke berkas spike dari berkas game.
const RUJUKAN_SPIKE: Array[String] = ["spike_sisi_dekat", "sprites/_spike/", "SpikeSisiDekat"]
## Folder yang dipindai: tidak ada berkas game yang boleh memuat berkas probe (kalau ada, mengecualikannya merusak game).
const FOLDER_GAME: Array[String] = ["res://scripts", "res://scenes", "res://assets"]
## Potongan nama kunci yang nilainya wajib kosong di preset (rahasia tidak boleh masuk repo).
const KUNCI_RAHASIA: Array[String] = ["password", "secret", "token", "encryption_key", "salt"]
## Potongan nilai yang menandakan jalur lokal atau berkas keystore di dalam preset.
const POLA_JALUR_LOKAL: Array[String] = ["/Users/", "/home/", "C:\\", ".keystore", ".jks", ".p12"]
## Pola `.gitignore` wajib: AC-19 (builds, apk, aab, .godot) ditambah keystore dan kredensial export (AC-23).
const POLA_GITIGNORE: Array[String] = [".godot/", "build/", "builds/", "*.apk", "*.aab", "*.keystore", "*.jks", "*.p12", "export_credentials.cfg"]
## Jalur contoh yang harus diabaikan git (cek dengan `git check-ignore`).
const CONTOH_DIABAIKAN: Array[String] = [
	"builds/kring-kring-debug.apk", "build/tests.log", "uji.apk", "rilis.aab", ".godot/export_credentials.cfg",
	".godot/imported/x.ctex", "rilis.keystore", "kunci/unggah.jks", "kunci.p12", "export_credentials.cfg",
]
## Jalur sumber yang TIDAK boleh diabaikan (kontrol negatif: pola yang terlalu lebar akan menyembunyikan sumber).
const CONTOH_DILACAK: Array[String] = ["export_presets.cfg", "docs/SETUP_ANDROID.md", "scripts/config.gd", "tests/tes_export.gd", "project.godot"]
## Kata yang tidak boleh ada di panduan setup repo ini (nilai spesifik project lain atau plugin yang belum dipakai, AC-20).
## release-please tidak lagi terlarang sejak CI rilis (docs/SETUP_ANDROID.md bagian 4b).
const KATA_TERLARANG_SETUP: Array[String] = ["brainydungeon", "startlights", "quicksplit", "firebase", "admob", "godot-share", "shareplugin"]
## Isi minimum panduan setup (AC-20): perintah dan istilah yang dipakai tes lain dan orchestrator.
const KATA_WAJIB_SETUP: Array[String] = [
	"com.rmh.kring", "--export-debug", "--export-pack", "java_sdk_path", "adb install -r", "pm list packages", "pm clear",
	"aapt2 dump badging", "aapt2 dump permissions", "apksigner verify", "targetSdkVersion", "cek_blok_piksel.py", "builds/",
]

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_preset_asli()
	_test_preset_contoh_buruk()
	_test_aset_5b_ikut_paket()
	_test_aset_5c_ikut_paket()
	_test_aset_5d_ikut_paket()
	_test_rujukan_5d_tak_dipasang()
	_test_dokumen_5d()
	_test_probe_tidak_ikut()
	_test_spike_tidak_ikut()
	_test_ikon_sementara()
	_test_gitignore()
	_test_berkas_dilacak()
	_test_panduan_setup()


# --- AC-19: isi export_presets.cfg ---

func _test_preset_asli() -> void:
	_judul.call("Preset export Android")
	check(FileAccess.file_exists(BERKAS_PRESET), "export_presets.cfg ada di root repo (di-commit)")
	var teks: String = FileAccess.get_file_as_string(BERKAS_PRESET)
	var pelanggaran: Array[String] = _pelanggaran_preset(teks)
	check(pelanggaran.is_empty(), "export_presets.cfg memenuhi AC-19 (satu preset Android, package, landscape, arm64, tanpa Gradle, tanpa izin, tanpa keystore): %s" % "; ".join(pelanggaran))
	# Pemindai tidak boleh lolos kosong: pastikan ia benar-benar melihat daftar izin dan kunci keystore.
	var cfg: ConfigFile = ConfigFile.new()
	check(cfg.parse(teks) == OK, "export_presets.cfg bisa diurai sebagai ConfigFile")
	check(cfg.has_section("preset.0") and cfg.has_section("preset.0.options"), "ada bagian [preset.0] dan [preset.0.options]")
	var jumlah_izin: int = 0
	var jumlah_keystore: int = 0
	var kunci_opsi: PackedStringArray = PackedStringArray()
	if cfg.has_section("preset.0.options"):
		kunci_opsi = cfg.get_section_keys("preset.0.options")
	for kunci: String in kunci_opsi:
		if kunci.begins_with("permissions/") and kunci != "permissions/custom_permissions":
			jumlah_izin += 1
		if kunci.begins_with("keystore/"):
			jumlah_keystore += 1
	check(jumlah_izin >= 100, "preset mendaftar semua izin Godot secara eksplisit (permissions/*=false), dapat %d" % jumlah_izin)
	check(jumlah_keystore == 6, "preset memuat enam kolom keystore (debug/release x jalur/user/sandi), semuanya kosong, dapat %d" % jumlah_keystore)
	# Orientasi diatur di project.godot (preset Godot 4 tidak punya opsi orientasi sendiri): landscape terkunci.
	check(int(ProjectSettings.get_setting("display/window/handheld/orientation")) == DisplayServer.SCREEN_LANDSCAPE, "orientasi landscape terkunci di project.godot (display/window/handheld/orientation = 0), dipakai preset export")
	check(not ProjectSettings.has_setting("display/window/handheld/orientation_override"), "preset tidak menimpa orientasi lewat pengaturan lain")
	# Godot menolak ekspor mobile tanpa Import ETC2 ASTC, walau semua tekstur repo ini Lossless (SETUP_ANDROID bagian 3).
	check(bool(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false)), "Import ETC2 ASTC menyala di project.godot (syarat ekspor Android, SETUP_ANDROID bagian 3)")


func _test_preset_contoh_buruk() -> void:
	_judul.call("Preset export: contoh buruk sintetis ditolak")
	var asli: String = FileAccess.get_file_as_string(BERKAS_PRESET)
	# Tiap mutan: [teks lama, teks baru, potongan pesan pelanggaran yang diharapkan, label].
	var mutan: Array = [
		['package/unique_name="com.rmh.kring"', 'package/unique_name="com.rmh.loperkoran"', "package", "package diganti ke com.rmh.loperkoran"],
		['package/unique_name="com.rmh.kring"', 'package/unique_name=""', "package", "package kosong"],
		['architectures/armeabi-v7a=false', 'architectures/armeabi-v7a=true', "armeabi-v7a", "arsitektur ekstra armeabi-v7a menyala"],
		['architectures/x86_64=false', 'architectures/x86_64=true', "x86_64", "arsitektur ekstra x86_64 menyala"],
		['architectures/arm64-v8a=true', 'architectures/arm64-v8a=false', "arm64-v8a", "arm64-v8a mati"],
		['gradle_build/use_gradle_build=false', 'gradle_build/use_gradle_build=true', "gradle", "Gradle build menyala"],
		['permissions/internet=false', 'permissions/internet=true', "permissions/internet", "izin INTERNET menyala"],
		['permissions/camera=false', 'permissions/camera=true', "permissions/camera", "izin CAMERA menyala"],
		['permissions/custom_permissions=PackedStringArray()', 'permissions/custom_permissions=PackedStringArray("android.permission.CAMERA")', "custom_permissions", "izin kustom terisi"],
		['keystore/release_password=""', 'keystore/release_password="rahasia"', "keystore/release_password", "kata sandi keystore rilis terisi"],
		['keystore/debug_password=""', 'keystore/debug_password="android"', "keystore/debug_password", "kata sandi keystore debug terisi"],
		['keystore/release=""', 'keystore/release="/Users/dev/kunci/rilis.keystore"', "keystore/release", "jalur keystore rilis terisi"],
		['keystore/release_user=""', 'keystore/release_user="unggah"', "keystore/release_user", "nama kunci rilis terisi"],
		['exclude_filter="docs/*, ', 'exclude_filter="assets/data/*, docs/*, ', "assets/data/missions/perumahan.json", "data misi dikecualikan dari paket"],
		['exclude_filter="docs/*, ', 'exclude_filter="translations/*, docs/*, ', "translations/konten.id.translation", "terjemahan dikecualikan dari paket"],
		['exclude_filter="docs/*, ', 'exclude_filter="scenes/hari/*, docs/*, ', "scenes/hari/hari.tscn", "scene hari dikecualikan dari paket"],
		['exclude_filter="docs/*, ', 'exclude_filter="assets/sprites/npc/*, docs/*, ', "assets/sprites/npc/mission_kucing_sheet.png", "sheet kucing dikecualikan dari paket"],
		['exclude_filter="docs/*, ', 'exclude_filter="assets/audio/sfx/mission/*, docs/*, ', "assets/audio/sfx/mission/sfx_mis_meong_01.wav", "bunyi misi dikecualikan dari paket"],
		['exclude_filter="docs/*, ', 'exclude_filter="scenes/ui/tutorial.tscn, docs/*, ', "scenes/ui/tutorial.tscn", "scene tutorial dikecualikan dari paket"],
		['exclude_filter="docs/*, ', 'exclude_filter="assets/sprites/loper/*, docs/*, ', "assets/sprites/loper/loper_agen_frames.tres", "sheet pemain dan SpriteFrames 68 animasi dikecualikan dari paket (AC-22 run 5C)"],
		['exclude_filter="docs/*, ', 'exclude_filter="scripts/systems/pose_kucing.gd, docs/*, ', "scripts/systems/pose_kucing.gd", "skrip pose kucing ditangkap dikecualikan dari paket (AC-22 run 5C)"],
		['name="Android"', 'name="Android uji"', "nama", "nama preset bukan Android"],
		['runnable=true', 'runnable=false', "runnable", "runnable mati"],
		['package/signed=true', 'package/signed=false', "package/signed", "APK tidak ditandatangani (tidak bisa dipasang)"],
		['version/code=1', 'version/code=2', "version/code", "version/code bukan 1"],
		['version/name="0.1.0"', 'version/name="1.0.0"', "version/name", "version/name bukan 0.1.0"],
		['screen/immersive_mode=true', 'screen/immersive_mode=false', "imersif", "mode imersif mati"],
		['user_data_backup/allow=false', 'user_data_backup/allow=true', "user_data_backup", "cadangan data pengguna menyala"],
		['tests/*, ', '', "tests/*", "tests/ tidak dikecualikan dari APK"],
		['exclude_filter="docs/*, tests/*, tools/*, build/*, builds/*, scenes/dev/cek_render.tscn, scripts/dev/cek_render.gd, assets/shaders/warna_bayangan.gdshader, scenes/dev/spike_sisi_dekat.tscn, scripts/dev/spike_sisi_dekat.gd, assets/sprites/_spike/*"', 'exclude_filter=""', "exclude_filter", "filter pengecualian kosong"],
		[', scenes/dev/spike_sisi_dekat.tscn', '', "scenes/dev/spike_sisi_dekat.tscn", "scene spike sisi dekat ikut paket game (AC-14 run 3C)"],
		[', scripts/dev/spike_sisi_dekat.gd', '', "scripts/dev/spike_sisi_dekat.gd", "skrip spike sisi dekat ikut paket game"],
		[', assets/sprites/_spike/*', '', "assets/sprites/_spike/*", "aset graybox spike ikut paket game"],
		[', scenes/dev/cek_render.tscn', '', "scenes/dev/cek_render.tscn", "scene probe render ikut APK normal (QA-004)"],
		[', scripts/dev/cek_render.gd', '', "scripts/dev/cek_render.gd", "skrip probe render ikut APK normal (QA-004)"],
		[', assets/shaders/warna_bayangan.gdshader', '', "warna_bayangan.gdshader", "shader probe render ikut APK normal (QA-004)"],
		['export_path=""', 'export_path="/Users/dev/builds/kring.apk"', "export_path", "jalur ekspor lokal"],
		['custom_template/debug=""', 'custom_template/debug="/Users/dev/templat/android_debug.apk"', "custom_template", "template kustom lokal"],
		['seed=0', 'seed=0\nscript_encryption_key="0123456789abcdef"', "encryption_key", "kunci enkripsi skrip terisi"],
	]
	var ditolak: int = 0
	for baris: Array in mutan:
		var dari: String = baris[0]
		var ke: String = baris[1]
		var potongan: String = baris[2]
		var label: String = baris[3]
		check(asli.contains(dari), "contoh buruk '%s': teks asal ditemukan di export_presets.cfg (mutan nyata, bukan no-op)" % label)
		var pelanggaran: Array[String] = _pelanggaran_preset(asli.replace(dari, ke))
		var cocok: bool = false
		for p: String in pelanggaran:
			if p.contains(potongan):
				cocok = true
		check(cocok, "contoh buruk ditolak: %s (pelanggaran memuat '%s'), dapat %s" % [label, potongan, pelanggaran])
		if cocok:
			ditolak += 1
	check(ditolak == mutan.size(), "semua %d contoh buruk ditolak, %d ditolak" % [mutan.size(), ditolak])
	# Struktur: nol preset, preset ganda. (Berkas yang tidak bisa diurai tidak dites: ConfigFile mencetak ERROR: ke keluaran,
	# yang memang ditolak pemeriksa keluaran tes.)
	check(not _pelanggaran_preset("").is_empty(), "berkas tanpa preset ditolak")
	var ganda: String = asli + '\n[preset.1]\n\nname="Web"\nplatform="Web"\nrunnable=false\n\n[preset.1.options]\n\n'
	var p_ganda: Array[String] = _pelanggaran_preset(ganda)
	check(not p_ganda.is_empty() and "; ".join(p_ganda).contains("satu preset"), "dua preset ditolak (harus tepat satu), dapat %s" % [p_ganda])
	# Bagian opsi hilang sama sekali.
	var tanpa_opsi: String = '[preset.0]\n\nname="Android"\nplatform="Android"\nrunnable=true\n'
	check(not _pelanggaran_preset(tanpa_opsi).is_empty(), "preset tanpa [preset.0.options] ditolak")
	# Kontrol positif: berkas asli tidak dimutasi tetap bersih (pemindai tidak menolak semuanya).
	check(_pelanggaran_preset(asli).is_empty(), "berkas asli tanpa mutasi tetap diterima (kontrol positif)")


## Semua pelanggaran AC-19 pada isi sebuah `export_presets.cfg`. Daftar kosong = bersih.
## True bila `jalur` cocok dengan salah satu pola `kecuali` (pola `folder/*` = awalan folder, selain itu sama persis).
func _dikecualikan(jalur: String, kecuali: Array[String]) -> bool:
	for pola: String in kecuali:
		if pola.ends_with("/*") and jalur.begins_with(pola.trim_suffix("*")):
			return true
		if pola == jalur:
			return true
	return false


func _pelanggaran_preset(teks: String) -> Array[String]:
	var hasil: Array[String] = []
	var cfg: ConfigFile = ConfigFile.new()
	var galat: int = cfg.parse(teks)
	if galat != OK:
		hasil.append("berkas tidak bisa diurai (kode galat %d)" % galat)
		return hasil
	var induk: Array[String] = []
	for bagian: String in cfg.get_sections():
		if bagian.begins_with("preset.") and not bagian.ends_with(".options"):
			induk.append(bagian)
	if induk.size() != 1:
		hasil.append("harus tepat satu preset, dapat %d" % induk.size())
		return hasil
	var kepala: String = induk[0]
	var opsi: String = kepala + ".options"
	if not cfg.has_section(opsi):
		hasil.append("bagian %s tidak ada" % opsi)
		return hasil
	# Kepala preset.
	if cfg.get_value(kepala, "name", null) != NAMA_PRESET:
		hasil.append("nama preset harus '%s'" % NAMA_PRESET)
	if cfg.get_value(kepala, "platform", null) != "Android":
		hasil.append("platform preset harus Android")
	if cfg.get_value(kepala, "runnable", null) != true:
		hasil.append("runnable harus true")
	var kecuali: Array[String] = []
	for bagian_filter: String in str(cfg.get_value(kepala, "exclude_filter", "")).split(","):
		kecuali.append(bagian_filter.strip_edges())
	for wajib: String in FILTER_DIKECUALIKAN:
		if not kecuali.has(wajib):
			hasil.append("exclude_filter harus memuat %s (tidak ikut APK)" % wajib)
	for probe: String in FILTER_PROBE:
		if not kecuali.has(probe):
			hasil.append("exclude_filter harus memuat %s (probe render tidak ikut APK normal, QA-004)" % probe)
	for spike: String in FILTER_SPIKE:
		if not kecuali.has(spike):
			hasil.append("exclude_filter harus memuat %s (spike sisi dekat tidak ikut paket game, AC-14 run 3C)" % spike)
	for wajib_ikut: String in JALUR_WAJIB_IKUT + JALUR_WAJIB_IKUT_5C + JALUR_WAJIB_IKUT_5D:
		if _dikecualikan(wajib_ikut, kecuali):
			hasil.append("%s harus ikut paket tetapi cocok dengan exclude_filter (konten dan scene alur hari, run fase4a-koran-hari)" % wajib_ikut)
		if not FileAccess.file_exists("res://" + wajib_ikut):
			hasil.append("%s harus ada di repo (ikut paket)" % wajib_ikut)
	if str(cfg.get_value(kepala, "export_path", "")) != "":
		hasil.append("export_path harus kosong (jalur ekspor lokal tidak di-commit)")
	# Opsi Android.
	if cfg.get_value(opsi, "package/unique_name", null) != PACKAGE_FINAL:
		hasil.append("package/unique_name harus %s" % PACKAGE_FINAL)
	if cfg.get_value(opsi, "screen/immersive_mode", null) != true:
		hasil.append("screen/immersive_mode harus true (imersif)")
	if cfg.get_value(opsi, "gradle_build/use_gradle_build", null) != false:
		hasil.append("gradle_build/use_gradle_build harus false (tanpa Gradle, SPEC D-8)")
	if cfg.get_value(opsi, ARSITEKTUR_AKTIF, null) != true:
		hasil.append("%s harus true" % ARSITEKTUR_AKTIF)
	for arsitektur: String in ARSITEKTUR_MATI:
		if cfg.get_value(opsi, arsitektur, null) != false:
			hasil.append("%s harus ada dan false (arm64-v8a saja)" % arsitektur)
	if cfg.get_value(opsi, "package/signed", null) != true:
		hasil.append("package/signed harus true (APK debug tak bertanda tangan tidak bisa dipasang)")
	if cfg.get_value(opsi, "version/code", null) != VERSI_KODE:
		hasil.append("version/code harus %d" % VERSI_KODE)
	if cfg.get_value(opsi, "version/name", null) != VERSI_NAMA:
		hasil.append("version/name harus %s" % VERSI_NAMA)
	# allowBackup: usulan awal mati, karena belum ada save yang layak dicadangkan (SETUP_ANDROID bagian preset).
	if cfg.get_value(opsi, "user_data_backup/allow", null) != false:
		hasil.append("user_data_backup/allow harus false (usulan awal, SETUP_ANDROID)")
	for template_kunci: String in ["custom_template/debug", "custom_template/release"]:
		if str(cfg.get_value(opsi, template_kunci, "")) != "":
			hasil.append("%s harus kosong (jalur template lokal tidak di-commit)" % template_kunci)
	# Izin: tidak ada yang menyala, tidak ada izin kustom.
	var izin_kustom: Variant = cfg.get_value(opsi, "permissions/custom_permissions", null)
	var izin_kustom_kosong: bool = false
	if izin_kustom is PackedStringArray:
		var daftar_izin: PackedStringArray = izin_kustom
		izin_kustom_kosong = daftar_izin.is_empty()
	if not izin_kustom_kosong:
		hasil.append("permissions/custom_permissions harus PackedStringArray() kosong")
	for kunci: String in cfg.get_section_keys(opsi):
		if kunci.begins_with("permissions/") and kunci != "permissions/custom_permissions":
			if cfg.get_value(opsi, kunci) != false:
				hasil.append("izin menyala: %s" % kunci)
		if kunci.begins_with("architectures/") and kunci != ARSITEKTUR_AKTIF and cfg.get_value(opsi, kunci) != false:
			hasil.append("arsitektur ekstra menyala: %s" % kunci)
		# Keystore: jalur, nama kunci, dan kata sandi semuanya kosong (keystore rilis di luar folder project).
		if kunci.begins_with("keystore/") and str(cfg.get_value(opsi, kunci)) != "":
			hasil.append("keystore terisi: %s" % kunci)
	# Rahasia dan jalur lokal di bagian mana pun.
	for bagian: String in cfg.get_sections():
		for kunci: String in cfg.get_section_keys(bagian):
			var nilai: Variant = cfg.get_value(bagian, kunci)
			if not (nilai is String):
				continue
			var isi: String = nilai
			if isi == "":
				continue
			for potongan: String in KUNCI_RAHASIA:
				if kunci.to_lower().contains(potongan):
					hasil.append("kolom rahasia terisi: %s/%s" % [bagian, kunci])
			for pola: String in POLA_JALUR_LOKAL:
				if isi.contains(pola):
					hasil.append("jalur lokal atau keystore di %s/%s" % [bagian, kunci])
	return hasil


# --- AC-17 run fase5b-tembok-dekor: aset 5B ikut paket (PNG + remap .import Lossless), aset tak dipasang tidak ada, dan tidak dikecualikan filter preset ---

func _test_aset_5b_ikut_paket() -> void:
	_judul.call("Aset 5B ikut paket dengan remap .import Lossless dan aset tak dipasang tidak ada (AC-17 run 5B)")
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(BERKAS_PRESET)
	var kecuali: Array[String] = []
	for bagian_filter: String in str(cfg.get_value("preset.0", "exclude_filter", "")).split(","):
		kecuali.append(bagian_filter.strip_edges())
	var png: int = 0
	for jalur: String in JALUR_WAJIB_IKUT:
		if not (jalur.begins_with("assets/sprites/") and jalur.ends_with(".png")):
			continue
		if not (jalur.contains("tong_sampah") or jalur.contains("pohon") or jalur.contains("lampu") or jalur.contains("_masuk") or jalur.contains("_simbol") or jalur.contains("rumput_2") or jalur.contains("rumput_3")):
			continue
		png += 1
		var teks_import: String = _baca_jika_ada("res://" + jalur + ".import")
		check(FileAccess.file_exists("res://" + jalur) and not teks_import.is_empty(), "%s dan remap .import ada (ikut paket)" % jalur)
		check(teks_import.contains("compress/mode=0") and teks_import.contains("mipmaps/generate=false"), "%s: impor Lossless tanpa mipmap" % jalur)
		check(not _dikecualikan(jalur, kecuali) and not _dikecualikan(jalur + ".import", kecuali), "%s tidak dikecualikan filter preset" % jalur)
	check(png == 12, "12 PNG 5B dicek (tong sampah, 3 pohon, 2 lampu, 6 ubin; lima tembok dilepas run 5D), dapat %d" % png)
	for jalur: String in JALUR_TIDAK_ADA_5B:
		check(not FileAccess.file_exists("res://" + jalur), "aset tak dipasang tidak ada di repo (tidak ikut paket): %s" % jalur)
	for nama: String in DirAccess.get_files_at("res://assets/sprites/tiles/perumahan"):
		check(not nama.contains("aspal_1") and not nama.contains("aspal_2") and not nama.contains("aspal_3") and not nama.contains("_dekat_masuk"), "tiles/perumahan tanpa aspal_N dan *_dekat_masuk: %s" % nama)


# --- AC-22 run fase5c-animasi-simpang: animasi pemain, sheet kucing 9 kolom, ubin ujung kerb dan simpang ikut paket; ubin tak dipasang tidak ada ---

func _test_aset_5c_ikut_paket() -> void:
	_judul.call("Aset 5C ikut paket dengan remap .import Lossless dan ubin tak dipasang tidak ada (AC-22 run 5C)")
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(BERKAS_PRESET)
	var kecuali: Array[String] = []
	for bagian_filter: String in str(cfg.get_value("preset.0", "exclude_filter", "")).split(","):
		kecuali.append(bagian_filter.strip_edges())
	var png_5c: Array[String] = []
	png_5c.append_array(PNG_5C_NON_UBIN)
	for nama: String in TesUbin.UBIN_5C:
		png_5c.append("assets/sprites/tiles/perumahan/" + nama)
	check(png_5c.size() == 40, "40 PNG 5C dicek (3 sheet pemain, sheet kucing, 2 ujung kerb, 18 simpang dekat, 16 simpang seberang), dapat %d" % png_5c.size())
	for jalur: String in png_5c:
		var teks_import: String = _baca_jika_ada("res://" + jalur + ".import")
		check(FileAccess.file_exists("res://" + jalur) and not teks_import.is_empty(), "%s dan remap .import ada (ikut paket)" % jalur)
		check(teks_import.contains("compress/mode=0") and teks_import.contains("mipmaps/generate=false"), "%s: impor Lossless tanpa mipmap" % jalur)
		check(not _dikecualikan(jalur, kecuali) and not _dikecualikan(jalur + ".import", kecuali), "%s tidak dikecualikan filter preset" % jalur)
	for jalur: String in JALUR_WAJIB_IKUT_5C:
		check(FileAccess.file_exists("res://" + jalur) and not _dikecualikan(jalur, kecuali), "%s ada dan tidak dikecualikan filter preset" % jalur)
	# Isi yang dibawa paket: SpriteFrames gabungan 68 animasi (termasuk jatuh, terjerembab, bangkit, berhenti lima arah) dan sheet kucing 9 kolom.
	var frames: SpriteFrames = load("res://assets/sprites/loper/loper_agen_frames.tres") as SpriteFrames
	var nama_anim: PackedStringArray = frames.get_animation_names() if frames != null else PackedStringArray()
	check(nama_anim.size() == JUMLAH_ANIMASI_5C, "loper_agen_frames.tres memuat %d animasi, dapat %d" % [JUMLAH_ANIMASI_5C, nama_anim.size()])
	for arah: String in ["kiri", "serong_kiri", "normal", "serong_kanan", "kanan"]:
		for awalan: String in ["jatuh_", "terjerembab_", "bangkit_", "berhenti_"]:
			check(nama_anim.has(awalan + arah), "SpriteFrames paket punya animasi %s%s" % [awalan, arah])
	var json_kucing: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/npc/mission_kucing_sheet.json"))
	var kolom: int = int((json_kucing as Dictionary).get("columns", 0)) if json_kucing is Dictionary else 0
	var tekstur_kucing: Texture2D = load("res://assets/sprites/npc/mission_kucing_sheet.png") as Texture2D
	var lebar_sel: int = int(((json_kucing as Dictionary).get("cell", [0, 0]) as Array)[0]) if json_kucing is Dictionary else 0
	check(kolom == KOLOM_KUCING_5C and tekstur_kucing != null and tekstur_kucing.get_width() == KOLOM_KUCING_5C * lebar_sel, "sheet kucing 9 kolom: JSON columns %d, lebar tekstur %d = 9 x sel %d" % [kolom, tekstur_kucing.get_width() if tekstur_kucing != null else -1, lebar_sel])
	# Ubin tak dipasang (D-2) tidak ada di repo, dan folder ubin hanya berisi ubin ujung/simpang yang terdaftar.
	for jalur: String in JALUR_TIDAK_ADA_5C:
		check(not FileAccess.file_exists("res://" + jalur), "ubin tak dipasang tidak ada di repo (tidak ikut paket): %s" % jalur)
	var ubin_5c_folder: int = 0
	for nama: String in DirAccess.get_files_at("res://assets/sprites/tiles/perumahan"):
		if nama.ends_with(".png") and (nama.contains("simpang_") or nama.contains("_ujung")):
			ubin_5c_folder += 1
			check(TesUbin.UBIN_5C.has(nama), "ubin simpang/ujung di folder terdaftar sebagai dipasang: %s" % nama)
	check(ubin_5c_folder == TesUbin.UBIN_5C.size(), "folder tiles/perumahan memuat tepat %d ubin simpang/ujung, dapat %d" % [TesUbin.UBIN_5C.size(), ubin_5c_folder])


# --- AC-14 run fase5d-sisi-dekat: rumah dekat baru, kotak surat, data segmen, dan kunci tip ikut paket; aset tembok tidak ada ---

func _test_aset_5d_ikut_paket() -> void:
	_judul.call("Aset 5D ikut paket (rumah dekat baru, kotak surat, data segmen, tip) dan aset tembok tidak ada (AC-14 run 5D)")
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(BERKAS_PRESET)
	var kecuali: Array[String] = []
	for bagian_filter: String in str(cfg.get_value("preset.0", "exclude_filter", "")).split(","):
		kecuali.append(bagian_filter.strip_edges())
	for jalur: String in JALUR_WAJIB_IKUT_5D:
		check(FileAccess.file_exists("res://" + jalur) and not _dikecualikan(jalur, kecuali), "%s ada dan tidak dikecualikan filter preset" % jalur)
	# Rumah dekat: PNG + JSON (ukuran = PNG, titik pijak, teras, penutup) dan impor Lossless tanpa mipmap.
	for nama: String in RUMAH_DEKAT_5D:
		var jalur_png: String = "res://" + FOLDER_RUMAH_5D + nama + ".png"
		var teks_import: String = _baca_jika_ada(jalur_png + ".import")
		check(teks_import.contains("compress/mode=0") and teks_import.contains("mipmaps/generate=false"), "%s: impor Lossless tanpa mipmap" % nama)
		var json: Variant = JSON.parse_string(_baca_jika_ada("res://" + FOLDER_RUMAH_5D + nama + ".json"))
		check(json is Dictionary, "%s.json bisa diurai" % nama)
		if not (json is Dictionary):
			continue
		var d: Dictionary = json
		var tekstur: Texture2D = load(jalur_png) as Texture2D
		var ukuran: Array = d.get("size", []) as Array
		check(tekstur != null and ukuran.size() == 2 and int(ukuran[0]) == tekstur.get_width() and int(ukuran[1]) == tekstur.get_height(), "%s: size JSON = ukuran PNG" % nama)
		check((d.get("ground_anchor", []) as Array).size() == 2 and (d.get("teras_ubin", []) as Array).size() == 4 and (d.get("penutup_ubin", []) as Array).size() == 4 and float(d.get("penutup_tinggi_ubin", 0.0)) > 0.0, "%s: titik pijak, teras_ubin, penutup_ubin, dan penutup_tinggi_ubin ada di JSON" % nama)
	for nama: String in PROP_KOTAK_SURAT_5D:
		var teks_import: String = _baca_jika_ada("res://assets/sprites/props/" + nama + ".png.import")
		check(teks_import.contains("compress/mode=0") and teks_import.contains("mipmaps/generate=false"), "%s: impor Lossless tanpa mipmap" % nama)
	# Folder rumah memuat tepat 12 PNG (6 dekat, 6 seberang) dan tidak ada nama dengan kata tembok di seluruh assets/ (aset yang tak dipasang tidak ikut paket).
	var png_rumah: Array[String] = []
	for nama: String in DirAccess.get_files_at("res://" + FOLDER_RUMAH_5D):
		if nama.ends_with(".png"):
			png_rumah.append(nama.trim_suffix(".png"))
	png_rumah.sort()
	var harapan_rumah: Array[String] = []
	harapan_rumah.append_array(RUMAH_DEKAT_5D)
	harapan_rumah.append_array(RUMAH_SEBERANG_5D)
	harapan_rumah.sort()
	check(png_rumah == harapan_rumah, "folder houses/perumahan hanya berisi 12 rumah yang dipasang: %s" % [png_rumah])
	var semua_aset: Array[String] = []
	_daftar_berkas_rekursif("res://assets", semua_aset)
	var kata_tak_ada: String = "tem" + "bok"
	var bernama_terlarang: Array[String] = []
	for jalur: String in semua_aset:
		# Graybox spike (`assets/sprites/_spike/`) dikecualikan dari paket oleh preset dan bukan aset game; sengaja punya tembok graybox.
		if jalur.to_lower().contains(kata_tak_ada) and not _dikecualikan(jalur.trim_prefix("res://"), kecuali):
			bernama_terlarang.append(jalur)
	check(semua_aset.size() > 300 and bernama_terlarang.is_empty(), "%d berkas di assets/ diperiksa, tidak ada nama berkas tembok (tidak ikut paket): %s" % [semua_aset.size(), bernama_terlarang])
	# Kunci tip hari 3 di ui.csv (kolom keys,id; teks tidak kosong, kunci tidak ganda) dan terjemahan hasil impor ada.
	var baris_csv: PackedStringArray = _baca_jika_ada("res://translations/ui.csv").split("\n")
	for kunci: String in KUNCI_TIP_5D:
		var jumlah: int = 0
		var isi_kunci: String = ""
		for baris: String in baris_csv:
			if baris.begins_with(kunci + ","):
				jumlah += 1
				isi_kunci = baris.trim_prefix(kunci + ",").strip_edges()
		check(jumlah == 1 and not isi_kunci.is_empty(), "kunci %s tepat satu di ui.csv dan teksnya tidak kosong" % kunci)
	# Data segmen: sembilan berkas, semuanya dua_sisi, dan jumlah rumah dekat pelanggan_boleh = literal (dihitung dari JSON, bukan dari kode).
	var dekat_boleh: int = 0
	var segmen: int = 0
	for nama: String in DirAccess.get_files_at("res://assets/data/routes/perumahan"):
		if not nama.ends_with(".json"):
			continue
		segmen += 1
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/routes/perumahan/" + nama))
		var tag: Variant = (data as Dictionary).get("tag", {}) if data is Dictionary else {}
		check(tag is Dictionary and str((tag as Dictionary).get("sisi_pelanggan", "")) == "dua_sisi", "%s: tag sisi_pelanggan dua_sisi" % nama)
		if not (data is Dictionary):
			continue
		for rumah: Variant in (data as Dictionary).get("rumah", []) as Array:
			if rumah is Dictionary and str((rumah as Dictionary).get("sisi", "")) == "dekat" and bool((rumah as Dictionary).get("pelanggan_boleh", false)):
				dekat_boleh += 1
	check(segmen == 9 and dekat_boleh == JUMLAH_DEKAT_BOLEH_5D, "9 segmen, %d rumah dekat pelanggan_boleh di JSON (dapat %d segmen, %d rumah)" % [JUMLAH_DEKAT_BOLEH_5D, segmen, dekat_boleh])


func _daftar_berkas_rekursif(folder: String, hasil: Array[String]) -> void:
	for nama: String in DirAccess.get_files_at(folder):
		hasil.append(folder + "/" + nama)
	for sub: String in DirAccess.get_directories_at(folder):
		_daftar_berkas_rekursif(folder + "/" + sub, hasil)


# --- AC-14 run fase5d-sisi-dekat: pemindai "tidak ada rujukan ke aset rumah atau kotak surat yang belum dipasang" ---

## Rujukan di `teks` ke sprite rumah atau kotak surat yang tidak dipasang: nama dengan kata tembok, `house_perumahan_*` yang bukan salah satu dari 12 rumah (atau awalannya), dan
## `prop_kotak_surat_*` selain varian bukan pelanggan. Awalan nama (dipakai untuk menyusun nama di kode) tidak ditandai.
func _rujukan_rumah_tak_dipasang(teks: String) -> Array[String]:
	var hasil: Array[String] = []
	var dipasang: Array[String] = []
	dipasang.append_array(RUMAH_DEKAT_5D)
	dipasang.append_array(RUMAH_SEBERANG_5D)
	var regex_rumah: RegEx = RegEx.new()
	regex_rumah.compile("house_[a-z_]*[a-z]_?")
	for cocok: RegExMatch in regex_rumah.search_all(teks):
		var nama: String = cocok.get_string()
		var inti: String = nama.trim_suffix("_")
		if inti.contains("tem" + "bok"):
			hasil.append(nama)
			continue
		if not inti.begins_with("house_perumahan"):
			continue
		var awalan_sah: bool = false
		for rumah: String in dipasang:
			if rumah == inti or rumah.begins_with(nama):
				awalan_sah = true
		if not awalan_sah:
			hasil.append(nama)
	var regex_kotak: RegEx = RegEx.new()
	regex_kotak.compile("prop_kotak_surat(_[a-z]+)*")
	for cocok: RegExMatch in regex_kotak.search_all(teks):
		if not PROP_KOTAK_SURAT_5D.has(cocok.get_string()):
			hasil.append(cocok.get_string())
	return hasil


func _test_rujukan_5d_tak_dipasang() -> void:
	_judul.call("Pemindai rujukan: tidak ada rujukan ke rumah atau kotak surat yang belum dipasang (AC-14 run 5D)")
	var berkas: Array[String] = ["res://project.godot", "res://export_presets.cfg"]
	for akar: String in ["res://scripts", "res://scenes", "res://assets/data", "res://translations"]:
		_kumpulkan_sumber(akar, berkas)
	for nama: String in DirAccess.get_files_at("res://tests"):
		if nama.ends_with(".gd") and not nama.begins_with("probe_") and nama != "tes_export.gd":
			berkas.append("res://tests/" + nama)
	var temuan: Array[String] = []
	for jalur: String in berkas:
		for nama: String in _rujukan_rumah_tak_dipasang(FileAccess.get_file_as_string(jalur)):
			temuan.append("%s memuat %s" % [jalur, nama])
	check(berkas.size() > 100, "pemindai membaca banyak berkas sumber (%d)" % berkas.size())
	check(temuan.is_empty(), "tidak ada rujukan ke rumah atau kotak surat yang belum dipasang: %s" % [temuan])
	# Contoh buruk sintetis harus tertangkap (nama disambung supaya berkas ini sendiri tidak memuatnya).
	var buruk: Array[String] = [
		"house_" + "tembok_polos", "house_perumahan_dekat_" + "pelana_lintang_rusak", "house_perumahan_" + "gudang_bukan", "prop_kotak_surat_" + "dekat", "prop_kotak_surat_" + "pelanggan",
	]
	for nama: String in buruk:
		var dapat: Array[String] = _rujukan_rumah_tak_dipasang("var t = \"res://assets/x/" + nama + ".png\"")
		check(dapat.size() == 1 and dapat[0] == nama, "pemindai menandai %s, dapat %s" % [nama, dapat])
	# Nama yang dipasang dan awalannya tidak ditandai.
	var sah: String = "house_perumahan_dekat_ house_perumahan_ house_ prop_kotak_surat prop_kotak_surat_bukan prop_koran_kotak_surat\n"
	for nama: String in RUMAH_DEKAT_5D + RUMAH_SEBERANG_5D:
		sah += "res://assets/sprites/houses/perumahan/" + nama + ".png\n"
	check(_rujukan_rumah_tak_dipasang(sah).is_empty(), "pemindai tidak menandai 12 rumah dan 2 kotak surat yang dipasang: %s" % [_rujukan_rumah_tak_dipasang(sah)])


## Dokumen run 5D (AC-17): checklist HP 8.16 lengkap (sebelas butir bernomor dan lembar hasil), 8.13 menandai tembok tidak berlaku, dan dokumen lain tidak lagi menyebut tembok sebagai tampilan sisi dekat yang berlaku.
func _test_dokumen_5d() -> void:
	_judul.call("Dokumen run 5D: SETUP_ANDROID 8.16, rujukan silang, dan AGENTS.md tanpa kelas tembok yang sudah dihapus (AC-17 run 5D)")
	var setup: String = _baca_jika_ada(BERKAS_SETUP)
	var awal: int = setup.find("### 8.16 ")
	check(awal >= 0, "SETUP_ANDROID.md punya bagian 8.16 (uji pelanggan sisi dekat)")
	var bagian: String = setup.substr(awal) if awal >= 0 else ""
	var nomor: int = 0
	for baris: String in bagian.split("\n"):
		if baris.begins_with("%d. [ ] **" % (nomor + 1)):
			nomor += 1
	check(nomor == 11, "8.16 punya 11 butir bernomor bercentang kosong, dapat %d" % nomor)
	check(bagian.contains("**Lembar hasil 8.16") and bagian.contains("11. Save lama utuh"), "8.16 punya lembar hasil dengan 11 baris")
	for kata: String in ["hari 3", "teras", "kotak surat dekat", "panel HUD bawah", "Anjing dekat", "60 fps"]:
		check(bagian.contains(kata), "8.16 menyebut '%s'" % kata)
	check(setup.contains("Catatan Run 5D") and setup.contains("tidak berlaku lagi"), "8.13 menandai butir tembok tidak berlaku sejak run 5D")
	var readme: String = _baca_jika_ada(BERKAS_README_DOCS)
	check(readme.contains("8.16") and readme.contains("20261022-fase5d-sisi-dekat"), "docs/README.md menyebut run 5D dan checklist 8.16")
	var agents: String = _baca_jika_ada("res://AGENTS.md")
	check(agents.contains("uji_aset_fase3.py") and agents.contains("tes_sisi_dekat_scene") and agents.contains("TipSisiDekat"), "AGENTS.md memuat uji dan kelas run 5D")
	check(not agents.contains("`Tembok" + "Dekat`, `Varian" + "Tembok`") and not agents.contains("varian_" + "tembok (") and not agents.contains("tembok_dekat (`"), "AGENTS.md tidak lagi mendaftar kelas tembok sebagai ada")
	var gdd: String = _baca_jika_ada("res://docs/GDD.md")
	check(gdd.contains("mulai hari 3") and gdd.contains("8 atau 9 dari 25"), "GDD memuat pelanggan sisi dekat mulai hari 3 (8 atau 9 dari 25)")
	var roadmap: String = _baca_jika_ada("res://docs/ROADMAP.md")
	check(roadmap.contains("menggantikan") and roadmap.contains("Riwayat (diganti, tetap dicatat)") and roadmap.contains("0,5 ubin"), "ROADMAP 4b menandai tembok diganti halaman terbuka mundur 0,5 dengan riwayat tetap")


func _kumpulkan_sumber(folder: String, hasil: Array[String]) -> void:
	for nama: String in DirAccess.get_files_at(folder):
		if nama.ends_with(".gd") or nama.ends_with(".tscn") or nama.ends_with(".tres") or nama.ends_with(".json") or nama.ends_with(".csv") or nama.ends_with(".cfg"):
			hasil.append(folder + "/" + nama)
	for sub: String in DirAccess.get_directories_at(folder):
		_kumpulkan_sumber(folder + "/" + sub, hasil)


# --- QA-004: probe render tidak ikut APK normal, pola sama dengan tools/ekspor_cek_render.py ---

func _test_probe_tidak_ikut() -> void:
	_judul.call("Probe render tidak ikut APK normal; pola preset = pola skrip ekspor probe (QA-004, D-4)")
	for pola: String in FILTER_PROBE:
		check(FileAccess.file_exists("res://" + pola), "pola probe %s menunjuk berkas yang ada (probe dipindah atau diganti nama = pola harus ikut)" % pola)
	var skrip: String = FileAccess.get_file_as_string(BERKAS_EKSPOR_PROBE)
	var pola_skrip: Array[String] = _pola_probe_skrip(skrip)
	check(_sama_tanpa_urutan(pola_skrip, FILTER_PROBE), "POLA_PROBE di tools/ekspor_cek_render.py = pola probe di exclude_filter preset, dapat %s" % [pola_skrip])
	check(skrip.contains("export_presets.cfg") and skrip.contains("finally:") and skrip.contains("pulih_preset"), "tools/ekspor_cek_render.py memulihkan export_presets.cfg (finally) dan memeriksa pemulihannya")
	# Penjaga kecocokan harus menangkap skrip yang berpisah dari preset.
	var kurang: String = skrip.replace(", 'assets/shaders/warna_bayangan.gdshader'", "")
	check(kurang != skrip and not _sama_tanpa_urutan(_pola_probe_skrip(kurang), FILTER_PROBE), "contoh buruk: skrip tanpa pola shader dikenali berbeda dari preset")
	var lebih: String = skrip.replace("POLA_PROBE = [", "POLA_PROBE = ['scenes/dev/jalan_uji.tscn', ")
	check(lebih != skrip and not _sama_tanpa_urutan(_pola_probe_skrip(lebih), FILTER_PROBE), "contoh buruk: skrip yang melepas pola tambahan dikenali berbeda dari preset")
	check(_pola_probe_skrip("tanpa daftar").is_empty(), "contoh buruk: skrip tanpa POLA_PROBE menghasilkan daftar kosong")
	# Berkas game tidak boleh memakai berkas probe: mengecualikannya dari APK akan merusak game.
	var pemakai: Array[String] = _pemakai_probe()
	check(pemakai.is_empty(), "tidak ada scene, skrip, atau resource game yang memuat berkas probe (res://... atau uid://...): %s" % [pemakai])
	_test_pemakai_uid()


# --- AC-14 run fase3c-hud-hasil: spike sisi dekat tidak ikut paket game dan tidak dirujuk berkas game ---

func _test_spike_tidak_ikut() -> void:
	_judul.call("Spike rumah sisi dekat tidak ikut paket game dan tidak dirujuk berkas game (AC-14 run 3C)")
	check(FileAccess.file_exists("res://" + FILTER_SPIKE[0]) and FileAccess.file_exists("res://" + FILTER_SPIKE[1]), "pola spike menunjuk scene dan skrip yang ada")
	var aset: PackedStringArray = DirAccess.get_files_at("res://assets/sprites/_spike/sisi_dekat")
	check(aset.size() >= 22, "aset graybox spike (PNG + JSON) ada di assets/sprites/_spike/sisi_dekat, dapat %d berkas" % aset.size())
	var uid_skrip: String = FileAccess.get_file_as_string("res://scripts/dev/spike_sisi_dekat.gd.uid").strip_edges()
	check(uid_skrip.begins_with("uid://"), "uid skrip spike terbaca: %s" % uid_skrip)
	var teks: Dictionary = {}
	for folder: String in FOLDER_GAME:
		for berkas: String in _daftar_berkas(folder):
			teks[berkas] = FileAccess.get_file_as_string(berkas)
	var pemakai: Array[String] = _pemakai_spike(teks, uid_skrip)
	check(teks.size() >= 50 and pemakai.is_empty(), "tidak ada scene, skrip, atau resource game (%d berkas) yang merujuk berkas spike: %s" % [teks.size(), pemakai])
	var buruk: Dictionary = {
		"res://scenes/rute/rute.tscn": "[ext_resource type=\"Texture2D\" path=\"res://assets/sprites/_spike/sisi_dekat/spike_dekat_tembok_bukan.png\" id=\"9\"]\n",
		"res://scripts/entities/rute_main.gd": "var s: SpikeSisiDekat = null\n",
		"res://scenes/ui/hud_rute.tscn": "[ext_resource type=\"Script\" uid=\"%s\" id=\"1\"]\n" % uid_skrip,
	}
	check(_pemakai_spike(buruk, uid_skrip).size() == 3, "contoh buruk: rujukan aset spike, kelas spike, dan uid skrip spike tertangkap: %s" % [_pemakai_spike(buruk, uid_skrip)])


## Berkas game (selain berkas spike sendiri) yang merujuk berkas spike lewat jalur, nama kelas, atau uid skripnya.
func _pemakai_spike(teks_per_berkas: Dictionary, uid_skrip: String) -> Array[String]:
	var hasil: Array[String] = []
	for berkas: String in teks_per_berkas:
		var relatif: String = berkas.trim_prefix("res://")
		if relatif.begins_with("assets/sprites/_spike/") or relatif.begins_with(FILTER_SPIKE[0]) or relatif.begins_with(FILTER_SPIKE[1]):
			continue
		var isi: String = teks_per_berkas[berkas]
		for potongan: String in RUJUKAN_SPIKE:
			if isi.contains(potongan):
				hasil.append("%s -> %s" % [berkas, potongan])
				break
		if uid_skrip != "" and _memuat_uid(isi, uid_skrip):
			hasil.append("%s -> %s" % [berkas, uid_skrip])
	return hasil


## Isi daftar `POLA_PROBE = [...]` di teks skrip Python (string bertanda petik tunggal), atau kosong bila tidak ada.
func _pola_probe_skrip(teks: String) -> Array[String]:
	var hasil: Array[String] = []
	var re_daftar: RegEx = RegEx.create_from_string("(?m)^POLA_PROBE = \\[([^\\]]*)\\]")
	var cocok: RegExMatch = re_daftar.search(teks)
	if cocok == null:
		return hasil
	var re_isi: RegEx = RegEx.create_from_string("'([^']+)'")
	for isi: RegExMatch in re_isi.search_all(cocok.get_string(1)):
		hasil.append(isi.get_string(1))
	return hasil


func _sama_tanpa_urutan(a: Array[String], b: Array[String]) -> bool:
	var x: Array[String] = a.duplicate()
	var y: Array[String] = b.duplicate()
	x.sort()
	y.sort()
	return x == y


## Berkas `.gd`, `.tscn`, `.tres`, `.gdshader` di folder game (selain berkas probe sendiri) yang memuat `res://<pola probe>` atau
## `uid://` milik berkas probe (QA-005 run fase1c-perapian, P-3 run fase2a-lemparan: Godot boleh menulis rujukan hanya lewat uid).
func _pemakai_probe() -> Array[String]:
	var teks: Dictionary = {}
	for folder: String in FOLDER_GAME:
		for berkas: String in _daftar_berkas(folder):
			teks[berkas] = FileAccess.get_file_as_string(berkas)
	return _pemakai_dari(teks, _uid_probe())


## Pemakai probe dari isi berkas (`{jalur: teks}`) dan uid tiap pola probe (`{pola: Array[String]}`); berkas probe sendiri dilewati.
func _pemakai_dari(teks_per_berkas: Dictionary, uid_per_pola: Dictionary) -> Array[String]:
	var hasil: Array[String] = []
	for berkas: String in teks_per_berkas:
		if FILTER_PROBE.has(berkas.trim_prefix("res://")):
			continue
		var teks: String = teks_per_berkas[berkas]
		for pola: String in FILTER_PROBE:
			if teks.contains("res://" + pola):
				hasil.append("%s -> %s" % [berkas, pola])
				continue
			var daftar_uid: Array = uid_per_pola.get(pola, [])
			for uid: String in daftar_uid:
				if _memuat_uid(teks, uid):
					hasil.append("%s -> %s (%s)" % [berkas, pola, uid])
					break
	return hasil


## True bila `teks` memuat `uid` sebagai satu rujukan utuh (bukan awalan uid lain yang lebih panjang).
func _memuat_uid(teks: String, uid: String) -> bool:
	var re: RegEx = RegEx.create_from_string(uid.replace(":", "\\:").replace("/", "\\/") + "(?![A-Za-z0-9_])")
	return re.search(teks) != null


## uid tiap berkas probe: `<berkas>.uid` (skrip, shader), `uid="..."` di `<berkas>.import`, `uid="..."` di header `[gd_scene ...]` /
## `[gd_resource ...]`, dan uid yang dikenal `ResourceLoader`. Berkas tanpa uid (mis. scene tanpa uid di header) = daftar kosong:
## berkas itu hanya bisa dirujuk lewat `res://`.
func _uid_probe() -> Dictionary:
	var hasil: Dictionary = {}
	for pola: String in FILTER_PROBE:
		var jalur: String = "res://" + pola
		var daftar: Array[String] = _uid_dari_teks(_baca_jika_ada(jalur + ".uid"), _baca_jika_ada(jalur + ".import"), _baca_jika_ada(jalur))
		var id: int = ResourceLoader.get_resource_uid(jalur)
		if id != ResourceUID.INVALID_ID:
			var teks_id: String = ResourceUID.id_to_text(id)
			if not daftar.has(teks_id):
				daftar.append(teks_id)
		hasil[pola] = daftar
	return hasil


## uid dari isi berkas `.uid`, `.import`, dan berkas sumber (header scene/resource), tanpa duplikat.
func _uid_dari_teks(teks_uid: String, teks_import: String, teks_sumber: String) -> Array[String]:
	var hasil: Array[String] = []
	var baris_uid: String = teks_uid.strip_edges()
	if baris_uid.begins_with("uid://"):
		hasil.append(baris_uid)
	var re_import: RegEx = RegEx.create_from_string("(?m)^uid=\"(uid://[A-Za-z0-9_]+)\"")
	var re_header: RegEx = RegEx.create_from_string("^\\[gd_(?:scene|resource)[^\\]]*\\buid=\"(uid://[A-Za-z0-9_]+)\"")
	for cocok: RegExMatch in [re_import.search(teks_import), re_header.search(teks_sumber)]:
		if cocok != null and not hasil.has(cocok.get_string(1)):
			hasil.append(cocok.get_string(1))
	return hasil


func _teks(isi: Array) -> Array[String]:
	var hasil: Array[String] = []
	hasil.assign(isi)
	return hasil


func _baca_jika_ada(jalur: String) -> String:
	return FileAccess.get_file_as_string(jalur) if FileAccess.file_exists(jalur) else ""


## P-3 (QA-005 run fase1c-perapian): penjaga menangkap rujukan `uid://` ke berkas probe walau tanpa `res://`, dengan contoh buruk.
func _test_pemakai_uid() -> void:
	var uid: Dictionary = _uid_probe()
	var semua: Array[String] = []
	for pola: String in uid:
		var daftar: Array = uid[pola]
		for u: String in daftar:
			semua.append(u)
	check(semua.size() >= 2 and (uid["scripts/dev/cek_render.gd"] as Array).has(FileAccess.get_file_as_string("res://scripts/dev/cek_render.gd.uid").strip_edges()), "uid berkas probe terbaca (skrip dan shader lewat .uid): %s" % [uid])
	check(_uid_dari_teks("uid://abc12\n", "", "") == _teks(["uid://abc12"]), "uid dari berkas .uid")
	check(_uid_dari_teks("", "[remap]\n\nimporter=\"texture\"\ntype=\"CompressedTexture2D\"\nuid=\"uid://imp34\"\n", "") == _teks(["uid://imp34"]), "uid dari berkas .import")
	check(_uid_dari_teks("", "", "[gd_scene load_steps=2 format=3 uid=\"uid://sce56\"]\n") == _teks(["uid://sce56"]), "uid dari header [gd_scene ... uid=...]")
	check(_uid_dari_teks("", "", "[gd_scene load_steps=2 format=3]\n[ext_resource uid=\"uid://lain\" path=\"res://x.gd\"]\n").is_empty(), "scene tanpa uid di header: uid ext_resource di bawahnya bukan uid scene itu")
	var uid_skrip: String = (uid["scripts/dev/cek_render.gd"] as Array)[0]
	var uid_shader: String = (uid["assets/shaders/warna_bayangan.gdshader"] as Array)[0]
	var buruk: Dictionary = {
		"res://scenes/dev/jalan_uji.tscn": "[gd_scene format=3]\n\n[ext_resource type=\"Script\" uid=\"%s\" id=\"1_cek\"]\n" % uid_skrip,
		"res://scripts/ui/hud_dev.gd": "const BAYANGAN := preload(\"%s\")\n" % uid_shader,
	}
	var tangkap: Array[String] = _pemakai_dari(buruk, uid)
	check(tangkap.size() == 2, "contoh buruk: ext_resource dan preload yang hanya memakai uid:// probe (tanpa res://) tertangkap: %s" % [tangkap])
	var baik: Dictionary = {
		"res://scenes/dev/jalan_uji.tscn": "[ext_resource type=\"Script\" uid=\"%sx\" path=\"res://scripts/entities/jalan_uji.gd\" id=\"1\"]\n" % uid_skrip,
		"res://scripts/dev/cek_render.gd": "# berkas probe sendiri boleh memuat %s\n" % uid_skrip,
	}
	check(_pemakai_dari(baik, uid).is_empty(), "contoh baik: uid lain yang berawalan sama dan berkas probe sendiri tidak dianggap pemakai")


func _daftar_berkas(folder: String) -> Array[String]:
	var hasil: Array[String] = []
	var dir: DirAccess = DirAccess.open(folder)
	if dir == null:
		return hasil
	for nama: String in dir.get_files():
		if [".gd", ".tscn", ".tres", ".gdshader"].has("." + nama.get_extension()):
			hasil.append(folder.path_join(nama))
	for sub: String in dir.get_directories():
		hasil.append_array(_daftar_berkas(folder.path_join(sub)))
	return hasil


# --- Ikon aplikasi sementara (Godot mencetak ERROR: tanpa application/config/icon saat ekspor Android) ---

func _test_ikon_sementara() -> void:
	_judul.call("Ikon aplikasi sementara")
	check(str(ProjectSettings.get_setting("application/config/icon", "")) == BERKAS_IKON, "application/config/icon = res://icon.svg (tanpa ikon, ekspor Android mencetak ERROR: No project icon specified)")
	check(FileAccess.file_exists(BERKAS_IKON) and FileAccess.file_exists(BERKAS_IKON + ".import"), "icon.svg dan icon.svg.import ada (ter-commit)")
	var teks: String = FileAccess.get_file_as_string(BERKAS_IKON)
	check(teks.contains("<svg") and teks.contains("viewBox=\"0 0 128 128\""), "icon.svg berupa SVG persegi 128x128")
	var sah: Array[String] = _warna_palet()
	check(sah.size() >= 10, "daftar warna sah diambil dari Palette (%d warna)" % sah.size())
	var asing: Array[String] = _warna_di_luar_palet(teks, sah)
	check(asing.is_empty(), "icon.svg hanya memakai warna Palette; di luar palet: %s" % [asing])
	var pakai: Array[String] = _warna_di_luar_palet(teks, [])
	check(pakai.size() >= 3, "pemindai warna melihat warna di icon.svg (%d) sehingga tidak lolos kosong" % pakai.size())
	check(_warna_di_luar_palet("<rect fill=\"#123456\"/>", sah) == ["#123456"], "warna di luar Palette (#123456) ditolak (contoh buruk)")
	check(_warna_di_luar_palet("<rect fill=\"#ffb22e\"/>", sah).is_empty(), "warna Palette huruf kecil (#ffb22e) diterima")


## Semua warna `#RRGGBB` konstanta `Color` di `scripts/ui/palette.gd`, huruf besar.
func _warna_palet() -> Array[String]:
	var hasil: Array[String] = []
	var skrip: Script = load(BERKAS_PALET)
	var konstanta: Dictionary = skrip.get_script_constant_map()
	for nama: String in konstanta:
		var nilai: Variant = konstanta[nama]
		if nilai is Color:
			var warna: Color = nilai
			hasil.append("#" + warna.to_html(false).to_upper())
	return hasil


## Warna `#RRGGBB` pada `teks` yang tidak ada di daftar `sah` (huruf besar).
func _warna_di_luar_palet(teks: String, sah: Array[String]) -> Array[String]:
	var hasil: Array[String] = []
	var re: RegEx = RegEx.create_from_string("#[0-9A-Fa-f]{6}(?![0-9A-Za-z])")
	for cocok: RegExMatch in re.search_all(teks):
		var kode: String = cocok.get_string().to_upper()
		if not sah.has(kode) and not hasil.has(cocok.get_string()):
			hasil.append(cocok.get_string())
	return hasil


# --- AC-19, AC-23: .gitignore ---

func _test_gitignore() -> void:
	_judul.call("Kebersihan repo: .gitignore")
	var teks: String = FileAccess.get_file_as_string(BERKAS_GITIGNORE)
	var hilang: Array[String] = _pola_hilang(teks)
	check(hilang.is_empty(), ".gitignore menutup builds/, build/, *.apk, *.aab, .godot/, *.keystore, *.jks, *.p12, export_credentials.cfg; hilang: %s" % [hilang])
	# Penjaga harus menangkap .gitignore yang bolong.
	check(_pola_hilang("build/\n*.apk\n").size() == POLA_GITIGNORE.size() - 2, ".gitignore tanpa builds/, *.aab, .godot/, keystore, dst. dikenali bolong")
	check(_pola_hilang(teks.replace("builds/\n", "")).has("builds/"), ".gitignore tanpa baris builds/ ditolak (mutan)")
	check(_pola_hilang(teks.replace("*.aab\n", "")).has("*.aab"), ".gitignore tanpa baris *.aab ditolak (mutan)")
	# Bukti sesungguhnya: git sendiri yang bilang jalur itu diabaikan, dan sumber tetap dilacak.
	var akar: String = ProjectSettings.globalize_path("res://")
	for jalur: String in CONTOH_DIABAIKAN:
		var kode: int = _git_ignore(akar, jalur)
		check(kode == 0, "git check-ignore: %s diabaikan (kode %d; 0 = diabaikan, 1 = tidak, -1 = git tidak jalan)" % [jalur, kode])
	for jalur: String in CONTOH_DILACAK:
		var kode: int = _git_ignore(akar, jalur)
		check(kode == 1, "git check-ignore: %s TIDAK diabaikan (kontrol negatif, kode %d)" % [jalur, kode])


## Pola wajib yang tidak ada sebagai baris utuh di isi `.gitignore`.
func _pola_hilang(teks: String) -> Array[String]:
	var hasil: Array[String] = []
	var baris: PackedStringArray = teks.split("\n")
	for pola: String in POLA_GITIGNORE:
		if not baris.has(pola):
			hasil.append(pola)
	return hasil


## Kode keluar `git check-ignore -q`: 0 diabaikan, 1 tidak diabaikan, 128 galat git, -1 git tidak bisa dijalankan.
func _git_ignore(akar: String, jalur: String) -> int:
	var keluaran: Array = []
	return OS.execute("git", ["-C", akar, "check-ignore", "-q", "--", jalur], keluaran, true)


# --- AC-23: berkas yang dilacak git ---

func _test_berkas_dilacak() -> void:
	_judul.call("Kebersihan repo: berkas yang dilacak git")
	var akar: String = ProjectSettings.globalize_path("res://")
	var keluaran: Array = []
	var kode: int = OS.execute("git", ["-C", akar, "ls-files"], keluaran, true)
	check(kode == 0 and keluaran.size() == 1, "git ls-files berjalan (kode %d)" % kode)
	if kode == 0 and keluaran.size() == 1:
		var dilacak: PackedStringArray = str(keluaran[0]).split("\n", false)
		check(dilacak.size() > 100, "git ls-files mengembalikan daftar berkas repo (%d berkas)" % dilacak.size())
		var terlarang: Array[String] = _berkas_terlarang(dilacak)
		check(terlarang.is_empty(), "tidak ada keystore, kredensial export, APK/AAB, .godot/, build/, builds/ yang dilacak git: %s" % [terlarang])
		check(dilacak.has("export_presets.cfg"), "export_presets.cfg dilacak git (preset di-commit, tanpa rahasia)")
	# Penjaga harus menangkap tiap jenis berkas terlarang.
	var buruk: PackedStringArray = PackedStringArray([
		"builds/kring.apk", "uji.apk", "rilis.aab", "kunci/rilis.keystore", "unggah.jks", "x/kunci.p12",
		"export_credentials.cfg", ".godot/export_credentials.cfg", ".godot/imported/a.ctex", "build/tests.log", "builds/a.txt",
	])
	for jalur: String in buruk:
		check(not _berkas_terlarang(PackedStringArray([jalur])).is_empty(), "berkas terlarang ditolak: %s" % jalur)
	var baik: PackedStringArray = PackedStringArray(["export_presets.cfg", "docs/SETUP_ANDROID.md", "scripts/config.gd", "assets/sprites/loper/loper_agen.png.import", "tools/build_helper.py", "docs/builds.md"])
	check(_berkas_terlarang(baik).is_empty(), "berkas sumber biasa (termasuk nama yang mirip, tools/build_helper.py) diterima")


## Jalur dari `git ls-files` yang tidak boleh pernah dilacak (git-workflow, privacy-ads).
func _berkas_terlarang(daftar: PackedStringArray) -> Array[String]:
	var hasil: Array[String] = []
	for jalur: String in daftar:
		var nama: String = jalur.get_file()
		var ekstensi: String = jalur.get_extension().to_lower()
		if ["keystore", "jks", "p12", "apk", "aab"].has(ekstensi):
			hasil.append(jalur)
		elif nama == "export_credentials.cfg":
			hasil.append(jalur)
		elif jalur.begins_with(".godot/") or jalur.begins_with("build/") or jalur.begins_with("builds/"):
			hasil.append(jalur)
	return hasil


# --- AC-20: panduan setup ---

func _test_panduan_setup() -> void:
	_judul.call("Panduan setup Android")
	check(FileAccess.file_exists(BERKAS_SETUP), "docs/SETUP_ANDROID.md ada")
	var teks: String = FileAccess.get_file_as_string(BERKAS_SETUP)
	var terlarang: Array[String] = _kata_terlarang(teks)
	check(terlarang.is_empty(), "SETUP_ANDROID.md tidak memuat nilai project lain (package, plugin, keystore): %s" % [terlarang])
	var hilang: Array[String] = _kata_hilang(teks)
	check(hilang.is_empty(), "SETUP_ANDROID.md memuat perintah dan istilah wajib (AC-20); hilang: %s" % [hilang])
	check(FileAccess.get_file_as_string(BERKAS_README_DOCS).contains("SETUP_ANDROID.md"), "docs/README.md mendaftarkan SETUP_ANDROID.md di tabel dokumen")
	# Penjaga harus menangkap contoh buruk.
	check(_kata_terlarang("package com.rmh.brainydungeon di HP").has("brainydungeon"), "package project lain (brainydungeon) ditolak")
	check(_kata_terlarang("Plugin AdMob dan Firebase").size() == 2, "plugin iklan dan analytics yang belum dipakai ditolak (huruf besar tetap dikenali)")
	check(_kata_terlarang("diadaptasi dari panduan Brainy Dungeon").is_empty(), "menyebut nama Brainy Dungeon sebagai sumber adaptasi (dengan spasi) diizinkan")
	check(_kata_hilang("dokumen kosong").size() == KATA_WAJIB_SETUP.size(), "dokumen kosong kehilangan semua istilah wajib")
	check(not _kata_hilang(teks.replace("pm clear", "")).is_empty(), "panduan tanpa peringatan pm clear ditolak (mutan)")


## Kata terlarang (tanpa memandang huruf besar-kecil) yang ada di `teks`.
func _kata_terlarang(teks: String) -> Array[String]:
	var hasil: Array[String] = []
	var kecil: String = teks.to_lower()
	for kata: String in KATA_TERLARANG_SETUP:
		if kecil.contains(kata):
			hasil.append(kata)
	return hasil


## Istilah wajib yang tidak ada di `teks`.
func _kata_hilang(teks: String) -> Array[String]:
	var hasil: Array[String] = []
	for kata: String in KATA_WAJIB_SETUP:
		if not teks.contains(kata):
			hasil.append(kata)
	return hasil
