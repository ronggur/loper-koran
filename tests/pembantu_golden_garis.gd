class_name PembantuGoldenGaris
extends RefCounted
## Pembantu golden garis finish (run garis-finish-portal bagian C, G-5, AC-7): satu bot deterministik menjalankan `scenes/rute/rute.tscn` dari awal sampai layar hasil terbuka dan
## mencatat angka akhirnya. Dipakai pembangkit (`ukur_golden_garis.gd`, dijalankan pada checkout `main` = perilaku LAMA: rem di garis akhir) dan `TesGarisFinishScene` (kode cabang ini:
## sepeda melaju keluar viewport), jadi keduanya menjalankan bot yang SAMA dan hanya scene yang berbeda. Bot hanya memakai API yang sudah ada di `main` (`perbarui`, sentuhan sintetis,
## `pilihan_bantu`, `lintasan_swipe`, `ketuk_bel`, penjaga `_lempar_terbuka`), dan berhenti memberi masukan yang tidak mungkin diberi pemain sesudah garis akhir.
##
## Kasus = benih rute, hari, profil bot, misi (bool), dan kondisi awal tiga komponen. Hasil = Dictionary angka (semua int, bool, String; float dicetak 4 desimal) yang bisa disimpan sebagai JSON.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const SKALA: int = 3
const TITIK_STICK: Vector2 = Vector2(100, 260)
const DT: float = 1.0 / 30.0
const DT_REM: float = 0.1
const LANGKAH_MAKS: int = 20000
## Selang antar usaha lempar dan antar ketukan bel, langkah.
const SELANG_LEMPAR: int = 17
const SELANG_BEL: int = 211
## Dekat garis akhir (ubin) bot melempar lebih sering dan tanpa sasaran, supaya ada koran yang masih terbang saat garis dilewati.
const JARAK_PAKSA_UBIN: float = 5.0
const SELANG_PAKSA: int = 4
## Profil stick: 0 santai (tanpa tarikan), 1 ngebut (tarik penuh ke depan), 2 campuran (arah acak berganti), 3 berhenti lama (rem sampai tenggat lewat, lalu ngebut).
const PROFIL_SANTAI: int = 0
const PROFIL_NGEBUT: int = 1
const PROFIL_CAMPURAN: int = 2
const PROFIL_BERHENTI_LAMA: int = 3
const LANGKAH_REM_LAMA: int = 960

## Kasus golden: `benih` (rute), `hari`, `profil`, `misi`, `kondisi` (0..1 untuk ban, rem, rantai).
const KASUS: Array = [
	{"nama": "santai_hari1", "benih": 20261024, "hari": 1, "profil": 0, "misi": false, "kondisi": 1.0},
	{"nama": "ngebut_hari3_misi", "benih": 7, "hari": 3, "profil": 1, "misi": true, "kondisi": 1.0},
	{"nama": "campuran_hari5_misi_aus", "benih": 91, "hari": 5, "profil": 2, "misi": true, "kondisi": 0.6},
	{"nama": "campuran_hari1_hampir_rusak", "benih": 1234, "hari": 1, "profil": 2, "misi": false, "kondisi": 0.3},
	{"nama": "ngebut_hari4", "benih": 555, "hari": 4, "profil": 1, "misi": false, "kondisi": 1.0},
	{"nama": "santai_hari2_misi", "benih": 20261016, "hari": 2, "profil": 0, "misi": true, "kondisi": 0.8},
	{"nama": "campuran_hari8_misi", "benih": 4242, "hari": 8, "profil": 2, "misi": true, "kondisi": 1.0},
	{"nama": "berhenti_lama_hari3", "benih": 31, "hari": 3, "profil": 3, "misi": false, "kondisi": 1.0},
]


## Keadaan simpan sepeda `kondisi` (0..1) untuk `RuteMain.atur_sepeda`.
static func state_sepeda(kondisi: float) -> Dictionary:
	var sepeda: Dictionary = {}
	for id: String in Config.KONDISI_KOMPONEN:
		sepeda[id] = {"kondisi": kondisi, "level": 0}
	return {"sepeda": sepeda}


## Satu sentuhan sintetis seperti jari nyata (koordinat viewport game, dikali skala jendela uji).
static func sentuh(index: int, posisi_viewport: Vector2, tekan: bool) -> void:
	var peristiwa: InputEventScreenTouch = InputEventScreenTouch.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * float(SKALA)
	peristiwa.pressed = tekan
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


## Geseran jari sintetis.
static func geser(index: int, posisi_viewport: Vector2) -> void:
	var peristiwa: InputEventScreenDrag = InputEventScreenDrag.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * float(SKALA)
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


static func _cetak(nilai: float) -> String:
	return "%.4f" % nilai


## Sidik keadaan skor: semua field angka, dan id rumah terantar urut.
static func sidik_skor(s: SkorRute.Keadaan) -> Dictionary:
	var ids: Array = s.terantar.keys()
	ids.sort()
	return {
		"skor": s.skor, "koin": s.koin, "beruntun": s.beruntun, "jumlah_antar": s.jumlah_antar, "jumlah_tepat": s.jumlah_tepat,
		"jumlah_tip": s.jumlah_tip, "koin_tip": s.koin_tip, "terbuang": s.terbuang, "terantar": ",".join(PackedStringArray(ids)),
	}


## Sidik radar dan progres untuk `jarak` ubin: jumlah penanda per jenis dan status 25 kotak.
static func sidik_radar_progres(akar: RuteMain, jarak: float) -> Dictionary:
	var rute: RouteBuilder.Rute = akar.rute()
	var terantar: Dictionary = akar.skor().terantar
	var penanda: Array[RadarRute.Penanda] = RadarRute.penanda(rute, jarak, terantar, akar.mode_bantu(), TenggatRute.lewat(akar.tenggat()))
	var teks: PackedStringArray = PackedStringArray()
	for p: RadarRute.Penanda in penanda:
		teks.append("%s|%s|%s|%s" % [p.id_rumah, str(p.jenis), str(p.sisi), _cetak(p.vertikal)])
	var status: PackedStringArray = PackedStringArray()
	for st: Variant in ProgresRute.status(rute, jarak, terantar, true):
		status.append(str(st))
	return {"radar": "\n".join(teks), "progres": ",".join(status), "terkirim": ProgresRute.jumlah_terkirim(rute, terantar)}


## Sidik keadaan rute pada saat ini (dipakai di garis akhir dan saat layar hasil terbuka).
static func sidik(akar: RuteMain, jarak_radar: float) -> Dictionary:
	var hasil: Dictionary = sidik_skor(akar.skor())
	hasil["tenggat_waktu"] = _cetak(akar.tenggat().waktu_detik)
	hasil["tenggat_berhenti"] = akar.tenggat().berhenti
	hasil["tenggat_lewat"] = TenggatRute.lewat(akar.tenggat())
	hasil["kondisi"] = akar.kondisi_akhir()
	var misi: MissionManager.Keadaan = akar.keadaan_misi()
	hasil["misi_hasil"] = MissionManager.nama_hasil(misi) if misi != null else "tanpa"
	hasil["misi_koin"] = MissionManager.koin_misi(misi) if misi != null else 0
	hasil["rintangan_jatuh"] = Tabrakan.jatuh(akar.rintangan().tabrakan)
	hasil["radar_progres"] = sidik_radar_progres(akar, jarak_radar)
	return hasil


## Menjalankan satu kasus sampai layar hasil terbuka. Mengembalikan `{"garis": sidik di langkah garis akhir pertama, "hasil": sidik saat layar hasil terbuka + angka hasil, ...}`.
static func jalankan(tree: SceneTree, kasus: Dictionary, jendela: Vector2i = Vector2i(2340, 1080)) -> Dictionary:
	tree.root.size = jendela
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	akar.atur_benih_awal(int(kasus["benih"]))
	akar.atur_hari(int(kasus["hari"]))
	var daftar: Array[DataToko] = []
	akar.atur_sepeda(state_sepeda(float(kasus["kondisi"])), int(kasus["hari"]), daftar)
	if bool(kasus["misi"]):
		akar.atur_misi(PemuatMisi.muat_folder().cari("p1_kucing"))
	tree.root.add_child(akar)
	await tree.process_frame
	await tree.process_frame
	# `_ready` menyalakan `_process` skrip yang punya `_process`: matikan sesudah masuk pohon, lalu susun ulang dari awal (frame nyata tadi sudah menggerakkan sepeda dan jam sedikit, dengan dt tak tentu).
	akar.set_process(false)
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	(akar.find_child("LoperAgen", true, false) as LoperSprite).set_process(false)
	akar.atur_benih_awal(int(kasus["benih"]))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(kasus["benih"]) * 31 + int(kasus["hari"])
	var profil: int = int(kasus["profil"])
	var jumlah_tabrakan: Array[int] = [0, 0]
	akar.tabrakan.connect(func(_jenis: String) -> void: jumlah_tabrakan[1 if akar.rute_sudah_selesai() else 0] += 1)
	var jumlah_lempar: Array[int] = [0]
	akar.koran_dilempar.connect(func(_l: ThrowSolver.Lintasan) -> void: jumlah_lempar[0] += 1)
	var hasil: Dictionary = {"nama": kasus["nama"], "panjang_ubin": _cetak(akar.rute().panjang_ubin), "pelanggan": akar.rute().pelanggan.size()}
	var tarik: Vector2 = Vector2.ZERO
	var jari_turun: bool = false
	var langkah: int = 0
	var langkah_garis: int = -1
	var ada_garis: bool = false
	while langkah < LANGKAH_MAKS and not akar.hasil_tampil():
		var selesai: bool = akar.rute_sudah_selesai()
		if not selesai:
			if profil == PROFIL_NGEBUT:
				tarik = Vector2(0, -60)
			elif profil == PROFIL_CAMPURAN and langkah % 60 == 0:
				tarik = Vector2([-40.0, 0.0, 40.0][rng.randi_range(0, 2)], [-60.0, -30.0, 0.0, 20.0][rng.randi_range(0, 3)])
			elif profil == PROFIL_BERHENTI_LAMA:
				tarik = Vector2(0, 60) if langkah < LANGKAH_REM_LAMA else Vector2(0, -60)
			if tarik != Vector2.ZERO and not jari_turun:
				sentuh(0, TITIK_STICK, true)
				jari_turun = true
			if jari_turun:
				geser(0, TITIK_STICK + tarik)
			var dekat_garis: bool = akar.rute().panjang_ubin - _jarak_sepeda(akar) < JARAK_PAKSA_UBIN
			if langkah % (SELANG_PAKSA if dekat_garis else SELANG_LEMPAR) == 0 and bool(akar.call(&"_lempar_terbuka")):
				_coba_lempar(akar, rng, dekat_garis)
			if langkah % SELANG_BEL == 0:
				akar.ketuk_bel()
		else:
			# Sesudah garis akhir pemain tidak punya apa pun yang bisa diberi: jari tetap menahan stick seperti pemain nyata yang belum sadar (masukan diabaikan scene).
			if jari_turun:
				geser(0, TITIK_STICK + Vector2(-50, 50))
		akar.perbarui(DT_REM if profil == PROFIL_BERHENTI_LAMA and langkah < LANGKAH_REM_LAMA else DT)
		langkah += 1
		if akar.rute_sudah_selesai() and not ada_garis:
			ada_garis = true
			langkah_garis = langkah
			hasil["garis"] = sidik(akar, akar.rute().panjang_ubin)
			hasil["garis_jarak"] = _cetak(akar.rute().panjang_ubin)
	hasil["langkah_garis"] = langkah_garis
	hasil["hasil_terbuka"] = akar.hasil_tampil()
	hasil["hasil"] = sidik(akar, _jarak_sepeda(akar))
	var a: HasilRute.Angka = akar.angka_hasil()
	if a != null:
		hasil["angka"] = {
			"pelanggan": a.pelanggan, "terkirim": a.terkirim, "meleset": a.meleset, "koin": a.koin, "koin_tip": a.koin_tip, "jumlah_tip": a.jumlah_tip, "skor": a.skor,
			"jumlah_tepat": a.jumlah_tepat, "tenggat_lewat": a.tenggat_lewat, "detik_lewat": a.detik_lewat, "misi_id": a.misi_id, "misi_hasil": a.misi_hasil, "koin_misi": a.koin_misi,
			"lempar_terbuang": a.lempar_terbuang, "potongan": a.potongan, "koin_bersih": a.koin_bersih,
		}
	hasil["tabrakan_sebelum_garis"] = jumlah_tabrakan[0]
	hasil["tabrakan_sesudah_garis"] = jumlah_tabrakan[1]
	hasil["jumlah_lempar"] = jumlah_lempar[0]
	if jari_turun:
		sentuh(0, TITIK_STICK, false)
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	tree.root.remove_child(akar)
	akar.free()
	return hasil


static func _jarak_sepeda(akar: RuteMain) -> float:
	return (akar.find_child("Sepeda", true, false) as SepedaUji).jarak_ubin


## Satu usaha lempar bot. Sasaran terjangkau di sisi acak: lintasan mode bantu sebagai lemparan biasa (bisa tepat, setengah kasus), sebagai tap mode bantu, atau swipe acak; tanpa sasaran:
## swipe acak hanya bila `paksa` (dekat garis akhir, supaya ada koran yang masih terbang saat garis dilewati). Koran dibatasi `SisaKoran` (ditolak = tidak terjadi apa pun).
static func _coba_lempar(akar: RuteMain, rng: RandomNumberGenerator, paksa: bool) -> void:
	if not SisaKoran.boleh_lempar(akar.koran):
		return
	var sisi: LoperAnim.Sisi = LoperAnim.Sisi.SEBERANG if rng.randf() < 0.65 else LoperAnim.Sisi.DEKAT
	var pilihan: BantuLempar.Pilihan = akar.pilihan_bantu(sisi)
	var undi: float = rng.randf()
	if pilihan != null and (undi < 0.4 or paksa):
		akar.call(&"_lempar", pilihan.lintasan, rng.randf() < 0.3)
		return
	if pilihan != null or not paksa:
		return
	var awal: Vector2 = Vector2(560, 200)
	var akhir: Vector2 = awal + Vector2(rng.randf_range(-160.0, 160.0), rng.randf_range(-120.0, 120.0))
	var lintasan: ThrowSolver.Lintasan = akar.lintasan_swipe(awal, akhir)
	if lintasan != null:
		akar.call(&"_lempar", lintasan, false)
