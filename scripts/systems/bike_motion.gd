class_name BikeMotion
extends RefCounted
## Gerak sepeda Fase 1: kecepatan, rem tanpa tombol, meluncur, stamina, dan lateral dengan batas tepi jalan resmi.
## Logika murni dan deterministik (BALANCING 2-3, GDD 5.2 dan 6, TECH_PLAN Fase 1); menggantikan `BikeDrive` run 0B (D-1).
##
## Tanpa node, `Time`, atau RNG: keadaan, vektor stick, dan `dt` semuanya parameter. `langkah` tidak mengubah keadaan
## masukannya; hasilnya membawa keadaan BARU. Satuan: kecepatan u/d, jarak dan lateral ubin, `dt` detik, stamina 0..100.
## Vektor stick = keluaran `StickMap` (sesudah zona mati): x positif = ke sisi `dekat`, y positif = maju/atas.
##
## Aturan (usulan, angka di `Config`):
## - Kecepatan tujuan dari komponen maju stick: netral 3,0, atas penuh 6,0, bawah penuh 1,5, linear di antaranya. Naik 3,0 u/d2,
##   turun 2,0 u/d2, tidak melewati tujuan. Selama `lelah` tujuan dijepit ke cepat (4,5).
## - Rem (D-2): komponen bawah stick (`-y`) >= `REM_AMBANG_STICK` (inklusif) menambah lama tahan; syarat tidak terpenuhi
##   (naik, ke samping, dilepas) mengembalikan lama tahan ke 0 dan mematikan rem. Rem aktif saat lama tahan >= `REM_TAHAN_DETIK`;
##   selama aktif kecepatan turun 5,0 u/d2 sampai 0 dan tetap 0. Langkah yang melewati batas tahan dibagi dua: sebelum batas
##   gerak biasa (meluncur), sesudahnya pengereman, jadi hasilnya tidak bergantung pada pembagian `dt`.
## - Stamina (D-5): stick ke bawah atau rem aktif +15/d; selain itu dari kecepatan SEBENARNYA, linear per potong +2 (<= 3,0),
##   -4 (4,5), -12 (>= 6,0). Dijepit 0..100. Mencapai 0 menyalakan `lelah`; `lelah` padam saat stamina >= 30.
## - Lateral (D-4): komponen datar stick x 3,0 u/d, dijepit ke tepi trotoar (+-(`JALAN_LEBAR_UBIN` / 2 + `JALAN_TROTOAR_UBIN`)) sebagai
##   batas tepi jalan resmi (sebelum 2026-10-16: tepi aspal; sepeda boleh naik trotoar, rumput halaman tetap di luar); positif =
##   sisi `dekat`, negatif = sisi `seberang`. Tanpa kunci atau snap jalur (keputusan pemilik 2026-10-13).
## Jarak maju dan stamina dihitung tepat per bagian (rampa linear lalu tetap, rampa dipotong di titik patah laju stamina), jadi
## hasil tidak bergantung pada pembagian `dt` (dites dengan langkah tunggal lawan 1/240).


## Keadaan sepeda. Dibuat baru oleh `langkah`; pemanggil hanya menyimpannya.
class Keadaan extends RefCounted:
	## Kecepatan maju, u/d (0 sampai ngebut; di bawah melambat hanya lewat rem).
	var kecepatan_ud: float = Config.KECEPATAN_SANTAI_UD
	## Posisi lateral, ubin dari garis tengah jalan (positif = sisi dekat).
	var lateral_ubin: float = 0.0
	## Stamina 0..`Config.STAMINA_MAKS`.
	var stamina: float = Config.STAMINA_MAKS
	## Lama stick ditahan di ujung bawah tanpa terputus, detik.
	var tahan_rem_detik: float = 0.0
	## True selama rem aktif (lama tahan sudah mencapai `REM_TAHAN_DETIK` dan syarat masih terpenuhi).
	var rem_aktif: bool = false
	## True sejak stamina habis sampai stamina kembali ke `STAMINA_PULIH_AMBANG`.
	var lelah: bool = false

	## Salinan bebas (mengubah salinan tidak mengubah aslinya).
	func salin() -> Keadaan:
		var baru: Keadaan = Keadaan.new()
		baru.kecepatan_ud = kecepatan_ud
		baru.lateral_ubin = lateral_ubin
		baru.stamina = stamina
		baru.tahan_rem_detik = tahan_rem_detik
		baru.rem_aktif = rem_aktif
		baru.lelah = lelah
		return baru


## Hasil satu langkah.
class Hasil extends RefCounted:
	## Keadaan sesudah langkah (objek baru).
	var keadaan: Keadaan = null
	## Jarak maju yang ditempuh selama langkah, ubin.
	var maju_ubin: float = 0.0
	## Kecepatan lateral efektif (perpindahan nyata per detik), u/d. Nol bila terhalang tepi jalan.
	var lateral_ud: float = 0.0
	## Kecepatan tujuan dari stick (sudah dijepit lelah), u/d. Dipakai pemilih pose (meluncur lawan melambat).
	var tujuan_ud: float = Config.KECEPATAN_SANTAI_UD
	## Komponen maju stick sesudah dibersihkan (-1..1). Negatif = stick ke bawah.
	var stick_maju: float = 0.0
	## Pose sprite (`LoperAnim.pose_dari_gerak`, D-7).
	var pose: LoperAnim.Pose = LoperAnim.Pose.KAYUH
	## Tingkat sprite -1..2 dari stick, dijepit ke cepat selama lelah (`LoperAnim.tingkat_sprite`).
	var tingkat_sprite: int = 0
	## Arah sprite -2..2 dari gerak sebenarnya (`LoperAnim.arah_dari_gerak`).
	var arah_sprite: int = 0
	## Pengali laju kayuh (`LoperAnim.pedal_rate`, D-8).
	var pedal_rate: float = 1.0
	## Kecepatan di awal langkah sesudah `beku_detik` diterapkan, u/d. Telemetri `BikeCondition` (aus rem hanya selama sepeda masih bergerak).
	var kecepatan_awal_ud: float = Config.KECEPATAN_SANTAI_UD
	## True bila rem menjadi aktif di dalam langkah ini (tepi naik rem; telemetri `BikeCondition`, aus per pengereman).
	var rem_mulai: bool = false


## Kecepatan tujuan (u/d) untuk komponen maju stick (-1 sampai 1, dijepit; NaN = netral). Netral = santai, atas penuh =
## ngebut, bawah penuh = melambat; di antaranya linear (BALANCING 2). `lelah` menjepit hasil ke cepat (BALANCING 3).
static func kecepatan_tujuan_ud(maju: float, lelah: bool = false) -> float:
	var a: float = _sumbu_bersih(maju)
	var tujuan: float = 0.0
	if a >= 0.0:
		tujuan = lerpf(Config.KECEPATAN_SANTAI_UD, Config.KECEPATAN_NGEBUT_UD, a)
	else:
		tujuan = lerpf(Config.KECEPATAN_SANTAI_UD, Config.KECEPATAN_MELAMBAT_UD, -a)
	if lelah:
		return minf(tujuan, Config.KECEPATAN_CEPAT_UD)
	return tujuan


## Batas tepi jalan resmi ke tiap sisi dari garis tengah, ubin (setengah lebar aspal ditambah lebar trotoar, D-4; sepeda boleh
## naik trotoar, permintaan pemilik 2026-10-16). Satu-satunya sumber batas: `ThrowSolver.titik_lepas` dan `JalanDaur.sel_tanah` memakainya.
static func batas_lateral_ubin() -> float:
	return Config.JALAN_LEBAR_UBIN / 2 + Config.JALAN_TROTOAR_UBIN


## True bila komponen bawah stick (`-stick.y`, sesudah zona mati) memenuhi syarat rem: >= `REM_AMBANG_STICK`, inklusif,
## dengan toleransi presisi tunggal `REM_AMBANG_TOLERANSI`. Diagonal penuh 45 derajat (0,707) tidak pernah memenuhi (D-2).
static func syarat_rem(stick: Vector2) -> bool:
	return syarat_rem_bawah(-_sumbu_bersih(stick.y))


## Syarat rem untuk komponen bawah `bawah` (0..1). NaN = tidak.
static func syarat_rem_bawah(bawah: float) -> bool:
	if is_nan(bawah):
		return false
	return bawah >= Config.REM_AMBANG_STICK - Config.REM_AMBANG_TOLERANSI


## True bila lama tahan `detik` sudah cukup untuk rem aktif (>= `REM_TAHAN_DETIK`, toleransi derau float).
static func tahan_cukup(detik: float) -> bool:
	return detik >= Config.REM_TAHAN_DETIK - Config.REM_TAHAN_TOLERANSI_DETIK


## Laju stamina per detik dari kecepatan sebenarnya, linear per potong di antara santai (+2), cepat (-4), dan ngebut (-12);
## di bawah santai sama dengan santai, di atas ngebut sama dengan ngebut. Tidak termasuk laju meluncur (lihat `laju_stamina`).
static func laju_stamina_kecepatan(kecepatan_ud: float) -> float:
	if is_nan(kecepatan_ud) or kecepatan_ud <= Config.KECEPATAN_SANTAI_UD:
		return Config.STAMINA_LAJU_SANTAI
	if kecepatan_ud <= Config.KECEPATAN_CEPAT_UD:
		var t: float = (kecepatan_ud - Config.KECEPATAN_SANTAI_UD) / (Config.KECEPATAN_CEPAT_UD - Config.KECEPATAN_SANTAI_UD)
		return lerpf(Config.STAMINA_LAJU_SANTAI, Config.STAMINA_LAJU_CEPAT, t)
	if kecepatan_ud < Config.KECEPATAN_NGEBUT_UD:
		var u: float = (kecepatan_ud - Config.KECEPATAN_CEPAT_UD) / (Config.KECEPATAN_NGEBUT_UD - Config.KECEPATAN_CEPAT_UD)
		return lerpf(Config.STAMINA_LAJU_CEPAT, Config.STAMINA_LAJU_NGEBUT, u)
	return Config.STAMINA_LAJU_NGEBUT


## Laju stamina per detik: stick ke bawah (`stick_maju` < 0) atau rem aktif = laju meluncur (+15), selain itu dari kecepatan.
static func laju_stamina(stick_maju: float, rem_aktif: bool, kecepatan_ud: float) -> float:
	if rem_aktif or (not is_nan(stick_maju) and stick_maju < 0.0):
		return Config.STAMINA_LAJU_MELUNCUR
	return laju_stamina_kecepatan(kecepatan_ud)


## Keadaan sesudah app di-background atau kehilangan fokus (D-6): lama tahan rem kembali 0 dan rem padam. Kecepatan, posisi,
## stamina, dan lelah tidak berubah. Tidak mengubah masukan.
static func jeda(keadaan: Keadaan) -> Keadaan:
	var baru: Keadaan = _bersihkan(keadaan)
	baru.tahan_rem_detik = 0.0
	baru.rem_aktif = false
	return baru


## Satu langkah selama `dt` detik dengan vektor `stick`. `dt` nol, negatif, NaN, atau tak hingga = keadaan tidak berubah
## (hanya dibersihkan: nilai NaN atau di luar jangkauan dikembalikan ke jangkauan sah). Stick NaN atau di luar +-1 aman
## (tiap komponen dijepit, NaN = 0). Keadaan masukan tidak pernah diubah.
## `beku_detik` (jatuh sesudah tabrakan, `Tabrakan.Keadaan.jatuh_detik`; keputusan pemilik 2026-10-17): bagian awal langkah selama
## `beku_detik` sepeda diam: kecepatan 0, lama tahan rem 0 dan rem padam, jarak, lateral, dan stamina tidak berubah, stick diabaikan. Bila
## jatuh menutup seluruh langkah (termasuk `dt` 0 saat jeda), stick dianggap netral untuk pose dan tingkat sprite. Sisa langkah sesudah
## bangun = gerak biasa dari kecepatan 0 dengan akselerasi biasa, jadi hasil tidak bergantung pada pembagian `dt`. NaN, negatif, atau 0 =
## tidak jatuh.
## `efek` (run fase6a1-bengkel-kondisi, M-6, AC-9): pengali kondisi sepeda (`EfekKondisi`, dari `BikeCondition.efek`). Kosong (null) atau identitas = keluaran
## identik bit-demi-bit dengan sebelum ada efek. Efek mengubah kecepatan tujuan (pengali dan batas puncak), akselerasi, perlambatan rem, kecepatan lateral, dan
## laju stamina yang menguras; tidak ada angka pengali di berkas ini.
static func langkah(keadaan: Keadaan, stick: Vector2, dt: float, beku_detik: float = 0.0, efek: EfekKondisi = null) -> Hasil:
	var e: EfekKondisi = efek if efek != null else EfekKondisi.new()
	var hasil: Hasil = Hasil.new()
	var waktu: float = dt if is_finite(dt) and dt > 0.0 else 0.0
	var beku: float = beku_detik if is_finite(beku_detik) and beku_detik > 0.0 else 0.0
	var maju: float = _sumbu_bersih(stick.y)
	var datar: float = _sumbu_bersih(stick.x)
	var s: Keadaan = _bersihkan(keadaan)
	var waktu_gerak: float = waktu
	if beku > 0.0:
		s.kecepatan_ud = 0.0
		s.tahan_rem_detik = 0.0
		s.rem_aktif = false
		# Sisa langkah sesudah bangun yang hanya derau float (sisa jatuh = dt dengan toleransi) dihitung nol, sama dengan `Tabrakan`.
		waktu_gerak = waktu - beku if waktu - beku > Config.TABRAKAN_TOLERANSI_DETIK else 0.0
		if waktu_gerak <= 0.0:
			maju = 0.0
			datar = 0.0
	var awal: Keadaan = s.salin()
	hasil.stick_maju = maju
	hasil.kecepatan_awal_ud = awal.kecepatan_ud
	hasil.tujuan_ud = tujuan_dengan_efek(kecepatan_tujuan_ud(maju, s.lelah), e)

	if waktu_gerak > 0.0:
		# Rem: lama tahan dan saat rem mulai di dalam langkah.
		var waktu_biasa: float = waktu_gerak
		if syarat_rem_bawah(-maju):
			var sisa: float = 0.0 if s.rem_aktif else maxf(Config.REM_TAHAN_DETIK - s.tahan_rem_detik, 0.0)
			s.tahan_rem_detik += waktu_gerak
			if s.rem_aktif or tahan_cukup(s.tahan_rem_detik):
				s.rem_aktif = true
				waktu_biasa = minf(sisa, waktu_gerak)
		else:
			s.tahan_rem_detik = 0.0
			s.rem_aktif = false
		var waktu_rem: float = waktu_gerak - waktu_biasa

		# Bagian gerak biasa (termasuk meluncur sebelum rem aktif), lalu bagian pengereman.
		var stamina_baru: float = s.stamina
		if waktu_biasa > 0.0:
			var biasa: Array[float] = _gerak_biasa(s.kecepatan_ud, hasil.tujuan_ud, maju, waktu_biasa, e)
			hasil.maju_ubin += biasa[0]
			s.kecepatan_ud = biasa[1]
			stamina_baru += biasa[2]
		if waktu_rem > 0.0:
			var rem: Array[float] = _gerak_rem(s.kecepatan_ud, waktu_rem, e)
			hasil.maju_ubin += rem[0]
			s.kecepatan_ud = rem[1]
			stamina_baru += Config.STAMINA_LAJU_MELUNCUR * waktu_rem
		s.stamina = clampf(stamina_baru, 0.0, Config.STAMINA_MAKS)
		if s.stamina <= 0.0:
			s.lelah = true
		elif s.stamina >= Config.STAMINA_PULIH_AMBANG:
			s.lelah = false

		# Lateral dengan batas tepi jalan resmi.
		var batas: float = batas_lateral_ubin()
		s.lateral_ubin = clampf(awal.lateral_ubin + datar * (Config.KECEPATAN_LATERAL_UD * e.pengali_lateral) * waktu_gerak, -batas, batas)
		hasil.lateral_ud = (s.lateral_ubin - awal.lateral_ubin) / waktu

	hasil.keadaan = s
	hasil.rem_mulai = s.rem_aktif and not awal.rem_aktif
	hasil.pose = LoperAnim.pose_dari_gerak(s.rem_aktif, maju, s.kecepatan_ud, hasil.tujuan_ud)
	hasil.tingkat_sprite = LoperAnim.tingkat_sprite(maju, s.lelah)
	hasil.arah_sprite = LoperAnim.arah_dari_gerak(s.kecepatan_ud, hasil.lateral_ud)
	hasil.pedal_rate = LoperAnim.pedal_rate(hasil.pose, hasil.tingkat_sprite, s.kecepatan_ud)
	return hasil


## Gerak biasa selama `t` detik dari kecepatan `v` menuju `tujuan`: [jarak ubin, kecepatan akhir, perubahan stamina].
## Rampa linear (naik `AKSELERASI_UD2`, turun `PERLAMBATAN_MELAMBAT_UD2`) sampai tujuan, lalu tetap. Jarak tepat. Stamina juga
## tepat: rampa dipotong di titik patah laju stamina (santai dan cepat), dan di tiap potongan laju linear terhadap waktu, jadi
## trapesium = integral.
static func _gerak_biasa(v: float, tujuan: float, maju: float, t: float, e: EfekKondisi) -> Array[float]:
	var laju_rampa: float = Config.AKSELERASI_UD2 * e.pengali_akselerasi if v < tujuan else Config.PERLAMBATAN_MELAMBAT_UD2
	var waktu_rampa: float = absf(tujuan - v) / laju_rampa
	var t_rampa: float = minf(t, waktu_rampa)
	var akhir_rampa: float = tujuan if t >= waktu_rampa else v + signf(tujuan - v) * laju_rampa * t_rampa
	var t_tetap: float = t - t_rampa
	var jarak: float = (v + akhir_rampa) / 2 * t_rampa + akhir_rampa * t_tetap
	var titik: Array[float] = [v]
	var patah: Array[float] = [Config.KECEPATAN_SANTAI_UD, Config.KECEPATAN_CEPAT_UD]
	if akhir_rampa < v:
		patah.reverse()
	for batas: float in patah:
		if (batas - v) * (batas - akhir_rampa) < 0.0:
			titik.append(batas)
	titik.append(akhir_rampa)
	var stamina: float = 0.0
	for i: int in range(titik.size() - 1):
		var lama: float = absf(titik[i + 1] - titik[i]) / laju_rampa
		stamina += (_laju_dengan_efek(laju_stamina(maju, false, titik[i]), e) + _laju_dengan_efek(laju_stamina(maju, false, titik[i + 1]), e)) / 2 * lama
	stamina += _laju_dengan_efek(laju_stamina(maju, false, akhir_rampa), e) * t_tetap
	return [jarak, akhir_rampa, stamina]


## Pengereman selama `t` detik dari kecepatan `v`: [jarak ubin, kecepatan akhir]. Turun `REM_PERLAMBATAN_UD2` sampai 0, lalu diam.
static func _gerak_rem(v: float, t: float, e: EfekKondisi) -> Array[float]:
	var perlambatan: float = Config.REM_PERLAMBATAN_UD2 * e.pengali_rem
	var waktu_henti: float = v / perlambatan
	if t >= waktu_henti:
		return [v / 2 * waktu_henti, 0.0]
	var akhir: float = v - perlambatan * t
	return [(v + akhir) / 2 * t, akhir]


## Kecepatan tujuan `tujuan` (u/d) sesudah efek kondisi: dikali pengali kecepatan lalu dijepit ke batas puncak (`EfekKondisi`). Identitas = `tujuan` itu sendiri.
static func tujuan_dengan_efek(tujuan: float, e: EfekKondisi) -> float:
	return minf(tujuan * e.pengali_kecepatan, e.batas_puncak_ud)


## Laju stamina `laju` per detik sesudah efek: hanya laju yang menguras (negatif) dikali pengali; laju pulih tidak berubah.
static func _laju_dengan_efek(laju: float, e: EfekKondisi) -> float:
	return laju * e.pengali_kuras_stamina if laju < 0.0 else laju


## Salinan keadaan dengan nilai yang dijepit ke jangkauan sah. NaN: kecepatan = santai, lateral = 0, stamina = maksimum,
## lama tahan = 0. Keadaan null = keadaan awal.
static func _bersihkan(keadaan: Keadaan) -> Keadaan:
	if keadaan == null:
		return Keadaan.new()
	var s: Keadaan = keadaan.salin()
	s.kecepatan_ud = Config.KECEPATAN_SANTAI_UD if is_nan(s.kecepatan_ud) else clampf(s.kecepatan_ud, 0.0, Config.KECEPATAN_NGEBUT_UD)
	var batas: float = batas_lateral_ubin()
	s.lateral_ubin = 0.0 if is_nan(s.lateral_ubin) else clampf(s.lateral_ubin, -batas, batas)
	s.stamina = Config.STAMINA_MAKS if is_nan(s.stamina) else clampf(s.stamina, 0.0, Config.STAMINA_MAKS)
	s.tahan_rem_detik = 0.0 if not is_finite(s.tahan_rem_detik) else maxf(s.tahan_rem_detik, 0.0)
	return s


static func _sumbu_bersih(nilai: float) -> float:
	if is_nan(nilai):
		return 0.0
	return clampf(nilai, -1, 1)
