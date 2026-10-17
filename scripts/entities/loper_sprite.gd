class_name LoperSprite
extends AnimatedSprite2D
## Sprite pemain (Kemeja Agen) yang memilih animasi dari pose, tingkat kecepatan, dan arah, dan memainkan lempar koran (ART_DIRECTION 3.2).
##
## Node hanya menampilkan: pemilihan nama animasi ada di `LoperAnim` dan garis waktu lempar di `LemparWaktu` (logika murni).
## - `pose`: `KAYUH` (bawaan) memakai `speed_level`; `MELUNCUR` dan `REM` memakai `meluncur_<arah>` dan `rem_<arah>` (D-7 run
##   fase1a-gerak); pemilihan pose dari keadaan gerak ada di `LoperAnim.pose_dari_gerak`, bukan di node ini;
## - `speed_level`: -1 = melambat (kayuh 4 fps), 0 = santai, 1 = cepat, 2 = ngebut (dijepit ke -1 sampai 2);
## - `steer`: -2 = 90 derajat ke sisi seberang, -1 = serong seberang, 0 = lurus, 1 = serong dekat,
##   2 = 90 derajat ke sisi dekat (dijepit ke -2 sampai 2). Nama animasi memakai `kiri` / `kanan`
##   karena berasal dari sprite aset yang dikunci; kiri = sisi seberang, kanan = sisi dekat
##   (mengikuti arah pelempar, GDD 4.2);
## - `pedal_rate`: pengali laju kayuh, 1.0 = laju bawaan animasi. Nilai negatif dianggap 0.
## Asal nilai (stick, gerak sebenarnya) diurus pemanggil, bukan node ini.
##
## Lempar (`lempar`): animasi `lempar_<sisi>_<kecepatan>_<arah>` dimainkan SEKALI dari frame 0 lalu sprite kembali ke animasi kayuh
## sesuai `speed_level` dan `steer` pada saat itu (bukan saat mulai), dengan indeks frame dan progres dilanjutkan seperti pergantian
## animasi biasa. Selama melempar `speed_level` dan `steer` tetap tersimpan tetapi tidak mengganti gambar. Waktu lempar dimajukan node
## sendiri lewat `maju(dt)` (dipanggil `_process`, `dt` dijepit ke `Config.LANGKAH_WAKTU_MAKS_DETIK`), bukan oleh pemutar bawaan, supaya
## tes bisa memajukannya dengan `dt` tetap.
## Sejak run fase2a-lemparan (D-9) node ini TIDAK lagi menolak lempar sendiri: yang memutuskan lemparan diterima adalah jeda antar lempar
## 0,35 detik dan sisa koran (`SisaKoran`, di `JalanUji`). Jeda 0,35 lebih panjang dari animasi (4 frame di 12 fps = 0,333), jadi
## biasanya animasi lama sudah selesai; bila belum (waktu sprite tertinggal), `lempar` menutup lempar lama lebih dulu: `koran_lepas`
## yang belum terjadi dipancarkan, lalu `lempar_selesai`, baru lempar baru dimulai dari frame 0. Jadi tiap lempar yang dimulai tetap
## memancarkan `koran_lepas` dan `lempar_selesai` tepat sekali, kecuali lempar yang ditutup `batalkan_lempar` (jeda game, D-11: hanya
## animasinya yang ditutup; koran yang sudah diterima tetap terbang lewat `KoranLempar`).
##
## Jatuh (`atur_jatuh`, keputusan pemilik 2026-10-17: tabrakan = jatuh): selama jatuh gambar diambil dari `LoperAnim.frame_jatuh` dengan lama
## sejak tabrakan dari pemanggil (`Tabrakan.lewat_jatuh_detik`), sprite dijeda (bukan pemutar bawaan), jadi jeda game membekukannya dan tes
## bisa memajukannya dengan `dt` tetap. Masuk jatuh menutup lempar yang berjalan (tanpa sinyal, seperti `batalkan_lempar`), lempar baru
## ditolak, dan `pose`/`speed_level`/`steer` tetap tersimpan tanpa mengganti gambar. Bangun = langsung kembali ke animasi pose saat itu dan
## diputar lagi (belum ada animasi bangkit; kedip kebal menutupinya, aset bangkit Fase 5).

## Koran lepas dari tangan: dipancarkan tepat sekali per lempar, saat frame `Config.LEMPAR_FRAME_LEPAS` (indeks 2) tampil (atau saat lempar
## yang belum sampai frame lepas disela lempar berikutnya). Koran terbang tidak bergantung pada sinyal ini (`KoranLempar` memakai jeda
## lepas yang sama, `LemparWaktu.waktu_lepas`), supaya jeda game di antara jari dilepas dan frame lepas tidak menghilangkan koran (D-11).
signal koran_lepas(sisi: LoperAnim.Sisi)
## Animasi lempar berakhir: habis dan sprite sudah kembali ke animasi kayuh, atau disela lempar berikutnya. Tepat sekali per lempar.
signal lempar_selesai

@export_range(-1, 2) var speed_level: int = 0:
	set(nilai):
		speed_level = LoperAnim.jepit_tingkat(nilai)
		_terapkan_animasi()
@export_range(-2, 2) var steer: int = 0:
	set(nilai):
		steer = LoperAnim.jepit_arah(nilai)
		_terapkan_animasi()
@export var pose: LoperAnim.Pose = LoperAnim.Pose.KAYUH:
	set(nilai):
		pose = nilai
		_terapkan_animasi()
@export var pedal_rate: float = 1.0:
	set(nilai):
		pedal_rate = nilai
		speed_scale = LoperAnim.skala_kayuh(nilai)

var _sedang_melempar: bool = false
var _sisi_lempar: LoperAnim.Sisi = LoperAnim.Sisi.TIDAK_ADA
var _waktu_lempar: float = 0.0
var _sudah_lepas: bool = false
var _jatuh: bool = false


func _init() -> void:
	sprite_frames_changed.connect(_saat_frames_berganti)


func _ready() -> void:
	set_process(_sedang_melempar)
	_terapkan_animasi()
	_mainkan_bila_siap()


func _process(delta: float) -> void:
	maju(minf(delta, Config.LANGKAH_WAKTU_MAKS_DETIK))


## True selama animasi lempar berjalan.
func sedang_melempar() -> bool:
	return _sedang_melempar


## Mulai animasi lempar ke `sisi`. Mengembalikan true bila dimulai. Tidak melakukan apa pun (false) bila `sisi` adalah `TIDAK_ADA` atau
## `sprite_frames` kosong. Animasi dipilih dari `pose`, `speed_level`, dan `steer` saat ini (`LoperAnim.nama_lempar`; dari meluncur dan
## rem memakai santai, `LoperAnim.tingkat_lempar`). Bila masih melempar, lempar lama ditutup dulu dengan sinyalnya (D-9, lihat atas).
func lempar(sisi: LoperAnim.Sisi) -> bool:
	if sprite_frames == null or _jatuh:
		return false
	var nama: StringName = _nama_lempar(sisi)
	if nama == &"":
		return false
	if not sprite_frames.has_animation(nama):
		push_warning("LoperSprite: animasi lempar '%s' tidak ada di SpriteFrames" % nama)
		return false
	if _sedang_melempar:
		var sisi_lama: LoperAnim.Sisi = _sisi_lempar
		var lepas_tertunda: bool = not _sudah_lepas
		_akhiri_lempar()
		if lepas_tertunda:
			koran_lepas.emit(sisi_lama)
		lempar_selesai.emit()
	_sedang_melempar = true
	_sudah_lepas = false
	_sisi_lempar = sisi
	_waktu_lempar = 0.0
	animation = nama
	set_frame_and_progress(0, 0.0)
	pause()
	set_process(true)
	return true


## Memajukan animasi lempar selama `dt` detik (tidak berpengaruh bila tidak sedang melempar). Memancarkan `koran_lepas` pada
## langkah yang pertama kali menampilkan frame lepas, lalu `lempar_selesai` saat frame habis dan sprite kembali ke kayuh.
func maju(dt: float) -> void:
	if not _sedang_melempar:
		return
	if sprite_frames == null or not sprite_frames.has_animation(animation):
		batalkan_lempar()
		return
	var langkah: LemparWaktu.Langkah = LemparWaktu.langkah(_waktu_lempar, dt, sprite_frames.get_animation_speed(animation), sprite_frames.get_frame_count(animation), Config.LEMPAR_FRAME_LEPAS)
	_waktu_lempar = langkah.waktu
	set_frame_and_progress(langkah.frame, langkah.progres)
	if langkah.lepas:
		_sudah_lepas = true
		koran_lepas.emit(_sisi_lempar)
	if langkah.selesai and _sedang_melempar:
		_akhiri_lempar()
		lempar_selesai.emit()


## Menghentikan lempar yang sedang berjalan dan kembali ke kayuh tanpa memancarkan `koran_lepas` atau `lempar_selesai`. Dipakai
## saat app di-background atau `sprite_frames` hilang, supaya tidak ada animasi lempar yang menggantung.
func batalkan_lempar() -> void:
	if _sedang_melempar:
		_akhiri_lempar()


## Jeda dari jari dilepas sampai koran lepas dari tangan bila lempar ke `sisi` dimulai sekarang, detik (`LemparWaktu.waktu_lepas` dari fps
## dan jumlah frame animasi lempar yang akan dipakai; D-4). 0 bila sisi kosong atau animasi tidak ada.
func jeda_lepas(sisi: LoperAnim.Sisi) -> float:
	var nama: StringName = _nama_lempar(sisi)
	if sprite_frames == null or nama == &"" or not sprite_frames.has_animation(nama):
		return 0.0
	return LemparWaktu.waktu_lepas(sprite_frames.get_animation_speed(nama), sprite_frames.get_frame_count(nama), Config.LEMPAR_FRAME_LEPAS)


## True selama sprite menampilkan jatuh atau terjerembab.
func sedang_jatuh() -> bool:
	return _jatuh


## Menampilkan jatuh (`aktif`) dengan lama `lewat_detik` sejak tabrakan, atau keluar dari jatuh (bangun). Lihat bagian Jatuh di atas.
## Animasi dan fps dibaca dari `sprite_frames` (`jatuh_<arah>`, `terjerembab_<arah>`, arah dari `steer` tetapi diabaikan `LoperAnim`).
func atur_jatuh(aktif: bool, lewat_detik: float) -> void:
	if not aktif:
		if _jatuh:
			_jatuh = false
			_terapkan_animasi()
			_mainkan_bila_siap()
		return
	if _sedang_melempar:
		_akhiri_lempar()
	_jatuh = true
	if sprite_frames == null:
		return
	var nama_j: StringName = LoperAnim.nama_jatuh(steer)
	var nama_t: StringName = LoperAnim.nama_terjerembab(steer)
	if not sprite_frames.has_animation(nama_j) or not sprite_frames.has_animation(nama_t):
		push_warning("LoperSprite: animasi '%s' atau '%s' tidak ada di SpriteFrames" % [nama_j, nama_t])
		return
	var f: LoperAnim.FrameJatuh = LoperAnim.frame_jatuh(lewat_detik, steer, sprite_frames.get_animation_speed(nama_j), sprite_frames.get_frame_count(nama_j), sprite_frames.get_animation_speed(nama_t), sprite_frames.get_frame_count(nama_t))
	if animation != f.nama:
		animation = f.nama
	set_frame_and_progress(f.frame, f.progres)
	pause()


func _nama_lempar(sisi: LoperAnim.Sisi) -> StringName:
	return LoperAnim.nama_lempar(sisi, LoperAnim.tingkat_lempar(pose, speed_level), steer)


func _akhiri_lempar() -> void:
	_sedang_melempar = false
	_sudah_lepas = false
	_sisi_lempar = LoperAnim.Sisi.TIDAK_ADA
	_waktu_lempar = 0.0
	set_process(false)
	_terapkan_animasi()
	_mainkan_bila_siap()


## Memasang animasi sesuai `pose`, `speed_level`, dan `steer`, menjaga fase (indeks frame) saat berganti. Tidak menyentuh gambar
## selama melempar.
func _terapkan_animasi() -> void:
	if sprite_frames == null or _sedang_melempar or _jatuh:
		return
	var nama: StringName = LoperAnim.nama_animasi_pose(pose, speed_level, steer)
	if not sprite_frames.has_animation(nama):
		push_warning("LoperSprite: animasi '%s' tidak ada di SpriteFrames" % nama)
		return
	if animation == nama:
		return
	var frame_lama: int = frame
	var progres_lama: float = frame_progress
	animation = nama
	set_frame_and_progress(frame_lama, progres_lama)


## Menyalakan putaran animasi bila ada `sprite_frames` yang memuat animasi saat ini. Aman tanpa `sprite_frames` (Q-001).
func _mainkan_bila_siap() -> void:
	if _sedang_melempar or _jatuh or sprite_frames == null or not sprite_frames.has_animation(animation):
		return
	if not is_playing():
		play(animation)


## `sprite_frames` diganti (termasuk dari kosong ke berisi, Q-001): lempar yang berjalan dibatalkan, lalu animasi kayuh dipasang ulang.
func _saat_frames_berganti() -> void:
	if _sedang_melempar:
		_akhiri_lempar()
		return
	_terapkan_animasi()
	_mainkan_bila_siap()
