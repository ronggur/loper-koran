class_name JalanUji
extends AdeganJalan
## Scene uji (Fase 0 AC-11, Fase 1 run 1A): jalan lurus tanpa ujung, sepeda digerakkan stick, HUD sementara. Scene dev; scene utama
## game sejak run fase3a-rute adalah `RuteMain` (`scenes/rute/rute.tscn`).
##
## Seluruh perilaku gerak, kamera, jeda, lemparan koran, mode bantu, bunyi, dan HUD ada di `AdeganJalan` (dasar bersama dengan scene
## rute; semua tes lama tetap menjalankannya lewat scene ini). Kelas ini hanya mengisi kaitnya untuk jalan tanpa ujung: rumah dan
## kotak surat graybox berkala (`ObjekDaur`), zona placeholder berkala (`ZonaGambar`, `ZonaSasaran.zona_jalan_uji_*`), dan isi ulang
## koran khusus jalan uji (`SisaKoran.isi_ulang_jalan_uji`, alat uji karena jalan uji tidak punya akhir rute). `_medan` null = penilaian
## koran memakai zona jalan uji.

@onready var _objek: ObjekDaur = %Objek
@onready var _zona: ZonaGambar = %Zona


func _perbarui_dunia(jarak_ubin: float) -> void:
	_zona.perbarui(jarak_ubin)
	_objek.perbarui(jarak_ubin)


func _zona_bantu(maju_awal_ubin: float, maju_akhir_ubin: float) -> Array[ZonaSasaran.Zona]:
	return ZonaSasaran.zona_jalan_uji_rentang(maju_awal_ubin, maju_akhir_ubin)


func _langkah_koran(keadaan: SisaKoran.Keadaan) -> SisaKoran.Keadaan:
	return SisaKoran.isi_ulang_jalan_uji(keadaan, _sepeda.jarak_ubin)
