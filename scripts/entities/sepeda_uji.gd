class_name SepedaUji
extends Node2D
## Pengendali sepeda uji: menghubungkan `BikeMotion` ke `LoperSprite` (run 0B, Fase 1 run 1A).
##
## Node hanya menyimpan keadaan dan menampilkannya: seluruh perhitungan (kecepatan, rem, stamina, lateral, pose, tingkat, arah,
## laju kayuh) ada di `BikeMotion` dan `LoperAnim` (logika murni). Keadaan gerak = `BikeMotion.Keadaan` ditambah jarak yang sudah
## ditempuh sepanjang jalan (ubin). Posisi dunia = (lateral, -jarak) lalu diproyeksikan oleh `Iso` dan dibulatkan ke piksel; origin
## node = titik pijak sprite (Y-sort benar). `lempar` hanya animasi pemain; koran terbang diurus `JalanUji` + `KoranLempar` (run
## fase2a-lemparan), yang membaca keadaan sepeda di sini: posisi dunia, kecepatan maju, kecepatan lateral efektif langkah terakhir
## (`lateral_ud`, D-4), dan jeda lepas animasi (`jeda_lepas`). Umpan balik kecepatan (debu roda, garis kecepatan; `UmpanBalikSepeda`,
## run fase1b-umpan-balik) diisi tiap langkah dari kecepatan sebenarnya dan status rem.
## Tabrakan = jatuh (keputusan pemilik 2026-10-17, menggantikan oleng run fase3b-rintangan-skor): `gerak` meneruskan `beku_detik` (sisa jatuh,
## `Tabrakan.Keadaan.jatuh_detik`) ke `BikeMotion.langkah`; `tabrak` menerapkan `Tabrakan.terapkan_ke_sepeda` (kecepatan 0). Umpan balik
## visual tabrakan (AC-8): sprite pemain memutar jatuh lalu terjerembab selama jatuh (`LoperSprite.atur_jatuh` dengan
## `Tabrakan.lewat_jatuh_detik`), berkedip selama kebal sesudah bangun (`Tabrakan.alfa_kebal`), ikon kilatan di atas kepala selama jatuh
## (`EfekSepeda`). Efek bel (AC-16): garis getar `GetarBel` (di bawah sprite pemain) di titik bel dan teks "KRING!" (`EfekSepeda`, di atas).

## Keadaan gerak saat ini (kecepatan, lateral, stamina, rem, lelah). Diganti objek baru tiap langkah, tidak diubah di tempat.
var keadaan: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
## Jarak yang sudah ditempuh sepanjang jalan, ubin.
var jarak_ubin: float = 0.0
## Kecepatan lateral efektif langkah terakhir (`BikeMotion.Hasil.lateral_ud`), u/d, positif = ke sisi dekat; 0 bila terhalang tepi
## jalan atau langkah ber-`dt` 0. Dipakai titik lepas koran (D-4) untuk garis bidik dan lemparan.
var lateral_ud: float = 0.0

@onready var _sprite: LoperSprite = %LoperAgen
@onready var _umpan: UmpanBalikSepeda = %UmpanBalik
@onready var _getar: Sprite2D = %GetarBel
@onready var _efek: EfekSepeda = %Efek

## Kecepatan maju saat ini, u/d.
var kecepatan_ud: float:
	get:
		return keadaan.kecepatan_ud
	set(nilai):
		var baru: BikeMotion.Keadaan = keadaan.salin()
		baru.kecepatan_ud = nilai
		keadaan = baru
## Posisi lateral, ubin dari garis tengah jalan (positif = sisi dekat).
var lateral_ubin: float:
	get:
		return keadaan.lateral_ubin
	set(nilai):
		var baru: BikeMotion.Keadaan = keadaan.salin()
		baru.lateral_ubin = nilai
		keadaan = baru


func _ready() -> void:
	position = Iso.posisi_gambar(posisi_dunia())


## Posisi dunia sepeda dalam ubin (x = lateral, y = -jarak maju, D-6 run 0B).
func posisi_dunia() -> Vector2:
	return Vector2(keadaan.lateral_ubin, -jarak_ubin)


## Satu langkah gerak dari vektor stick (x: datar, y: atas) selama `dt` detik, lalu memperbarui sprite dan posisi. `beku_detik` = sisa jatuh
## sesudah tabrakan: selama itu sepeda diam dan stick diabaikan (`BikeMotion.langkah`).
func gerak(stick: Vector2, dt: float, beku_detik: float = 0.0) -> void:
	var hasil: BikeMotion.Hasil = BikeMotion.langkah(keadaan, stick, dt, beku_detik)
	keadaan = hasil.keadaan
	jarak_ubin += hasil.maju_ubin
	lateral_ud = hasil.lateral_ud
	_sprite.pose = hasil.pose
	_sprite.speed_level = hasil.tingkat_sprite
	_sprite.steer = hasil.arah_sprite
	_sprite.pedal_rate = hasil.pedal_rate
	_umpan.perbarui(keadaan.kecepatan_ud, keadaan.rem_aktif)
	position = Iso.posisi_gambar(posisi_dunia())


## App di-background atau kehilangan fokus (D-6): lama tahan rem kembali 0 dan rem padam (`BikeMotion.jeda`), lempar ditutup.
## Sprite dipasang ulang dari keadaan baru tanpa memajukan waktu.
func jeda() -> void:
	keadaan = BikeMotion.jeda(keadaan)
	batalkan_lempar()
	gerak(Vector2.ZERO, 0.0)


## Mengembalikan sepeda ke keadaan awal rute ("Main lagi", run fase3a-rute): jarak 0, lateral 0, kecepatan santai, stamina penuh, rem
## padam, lempar ditutup. Sprite dipasang ulang dari keadaan baru tanpa memajukan waktu.
func atur_ulang() -> void:
	keadaan = BikeMotion.Keadaan.new()
	jarak_ubin = 0.0
	lateral_ud = 0.0
	batalkan_lempar()
	gerak(Vector2.ZERO, 0.0)


## Tabrakan = jatuh: kecepatan langsung 0 dan rem padam (`Tabrakan.terapkan_ke_sepeda`); lateral, stamina, dan jarak tetap.
func tabrak() -> void:
	keadaan = Tabrakan.terapkan_ke_sepeda(keadaan)


## Umpan balik visual keadaan tabrakan `t`: sprite jatuh/terjerembab selama jatuh, kedip kebal sesudah bangun, ikon kilatan selama jatuh.
func tampilkan_tabrakan(t: Tabrakan.Keadaan) -> void:
	_sprite.atur_jatuh(Tabrakan.jatuh(t), Tabrakan.lewat_jatuh_detik(t))
	_sprite.modulate.a = Tabrakan.alfa_kebal(t)
	_efek.tampilkan_tabrakan(Tabrakan.jatuh(t))


## Efek bel dari keadaan `b`: garis getar (frame `Bel.frame_getar`, jangkar = titik bel) dan teks "KRING!" / "KRING KRING!".
func tampilkan_bel(b: Bel.Keadaan) -> void:
	var frame: int = Bel.frame_getar(b)
	_getar.visible = frame >= 0
	if frame >= 0:
		_getar.frame = frame
		_getar.position = EfekSepeda.titik_bel() - Vector2(Config.BEL_GETAR_JANGKAR_PX[0], Config.BEL_GETAR_JANGKAR_PX[1])
	_efek.tampilkan_bel(b)


## Node efek di atas pemain (ikon tabrakan, teks bel; untuk tes dan probe).
func efek() -> EfekSepeda:
	return _efek


## Sprite garis getar bel (untuk tes dan probe).
func getar_bel() -> Sprite2D:
	return _getar


## True selama sprite pemain menampilkan jatuh atau terjerembab (untuk tes dan probe).
func sedang_jatuh() -> bool:
	return _sprite.sedang_jatuh()


## Indeks frame sprite pemain saat ini (untuk tes).
func frame_sprite() -> int:
	return _sprite.frame


## Alpha sprite pemain saat ini (kedip kebal; untuk tes).
func alfa_sprite() -> float:
	return _sprite.modulate.a


## Pose sprite pemain dari langkah terakhir (`LoperAnim.Pose`: kayuh/melambat, meluncur, rem); dipakai bunyi sepeda (`Audio`).
func pose() -> LoperAnim.Pose:
	return _sprite.pose


## True selama rem aktif (cincin rem di stick, DESIGN_SPEC 3.7).
func rem_aktif() -> bool:
	return keadaan.rem_aktif


## Stamina saat ini, 0..`Config.STAMINA_MAKS`.
func stamina() -> float:
	return keadaan.stamina


## True selama lelah (stamina habis dan belum kembali ke `Config.STAMINA_PULIH_AMBANG`).
func lelah() -> bool:
	return keadaan.lelah


## Node umpan balik kecepatan (debu roda dan garis kecepatan; untuk tes dan probe).
func umpan_balik() -> UmpanBalikSepeda:
	return _umpan


## Animasi yang sedang dipilih sprite (untuk tes dan HUD uji).
func nama_animasi() -> StringName:
	return _sprite.animation


## Animasi lempar koran ke `sisi` (D-3 run sprite). Koran, sisa koran, dan jeda antar lempar diurus `JalanUji` (run fase2a-lemparan);
## node ini tidak menolak lempar sendiri (D-9, `LoperSprite.lempar`). Gerak sepeda tidak terganggu. True bila animasi dimulai; false bila
## sisi kosong.
func lempar(sisi: LoperAnim.Sisi) -> bool:
	return _sprite.lempar(sisi)


## Jeda dari jari dilepas sampai koran lepas dari tangan untuk lempar ke `sisi` sekarang, detik (`LoperSprite.jeda_lepas`, D-4).
func jeda_lepas(sisi: LoperAnim.Sisi) -> float:
	return _sprite.jeda_lepas(sisi)


## True selama animasi lempar berjalan.
func sedang_melempar() -> bool:
	return _sprite.sedang_melempar()


## Menutup lempar yang sedang berjalan tanpa sinyal (app di-background atau kehilangan fokus).
func batalkan_lempar() -> void:
	_sprite.batalkan_lempar()
