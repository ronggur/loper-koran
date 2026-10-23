class_name MilestoneTracker
extends RefCounted
## Milestone dasar, logika murni (GDD 8 dan 13, O-9 dan AC-12 run fase6a2-reputasi-pelanggan bagian C, usulan). Empat milestone (`Config.MILESTONE_ID`) masing-masing tiga tingkat
## (perunggu, perak, emas; target di `Config.MILESTONE_TARGET_*`). Progres DITURUNKAN dari state save, tanpa field save baru dan tanpa hadiah kosmetik:
## - `pelanggan_tetap`: jumlah pelanggan berstatus `setia` di `state["pelanggan"]`.
## - `koin_total`: `state["koin_total"]` (seumur hidup, hanya naik).
## - `misi_selesai`: jumlah entri `state["misi_hasil"]` dengan `hasil` = "selesai".
## - `sepeda`: `servis_total` + jumlah `level` upgrade ketiga komponen di `state["sepeda"]`.
## Masukan tidak pernah diubah; nilai asing (hilang, bukan angka, negatif, bentuk salah) dihitung 0. Tanpa node, `Time`, atau RNG.
##
## "Paling dekat tercapai" (`paling_dekat`): di antara milestone yang belum emas, pecahan terbesar `nilai / target tingkat berikutnya` (dibandingkan dengan perkalian silang bilangan bulat, tanpa
## galat pecahan), seri dipecah oleh sisa angka terkecil (`target - nilai`), lalu oleh urutan `Config.MILESTONE_ID`. Deterministik. Semua emas = null.
## "Baru tercapai" (`baru_tercapai`): milestone yang tingkatnya naik antara dua state (sebelum dan sesudah hari), satu entri per milestone dengan tingkat tertinggi yang kini tercapai.

## Status satu milestone.
class Status extends RefCounted:
	var id: String = ""
	var nilai: int = 0
	## 0 = belum ada, 1 = perunggu, 2 = perak, 3 = emas.
	var tingkat: int = 0
	## Target tingkat berikutnya; -1 bila sudah emas.
	var target: int = -1

	## True bila tingkat tertinggi sudah tercapai.
	func tamat() -> bool:
		return target < 0

	## Pecahan menuju tingkat berikutnya, 0..1 (1,0 bila sudah emas), untuk bilah.
	func pecahan() -> float:
		if target <= 0:
			return 1.0
		return clampf(float(nilai) / float(target), 0.0, 1.0)

	## Sisa angka menuju tingkat berikutnya (0 bila sudah emas).
	func sisa() -> int:
		return 0 if target < 0 else maxi(target - nilai, 0)


## Tingkat yang baru tercapai (naik dari `tingkat_sebelum` ke `tingkat`).
class Capaian extends RefCounted:
	var id: String = ""
	var tingkat: int = 0
	var tingkat_sebelum: int = 0


## Ringkasan untuk layar hasil: status semua milestone sesudah hari, yang paling dekat tercapai (null bila semua emas), dan tingkat yang baru tercapai.
class Ringkasan extends RefCounted:
	var daftar: Array[Status] = []
	var terdekat: Status = null
	var baru: Array[Capaian] = []


## Daftar target milestone `id` (menaik); kosong bila id tidak dikenal.
static func daftar_target(id: String) -> Array[int]:
	match id:
		"pelanggan_tetap":
			return Config.MILESTONE_TARGET_PELANGGAN_TETAP
		"koin_total":
			return Config.MILESTONE_TARGET_KOIN_TOTAL
		"misi_selesai":
			return Config.MILESTONE_TARGET_MISI_SELESAI
		"sepeda":
			return Config.MILESTONE_TARGET_SEPEDA
	var kosong: Array[int] = []
	return kosong


## Nilai progres milestone `id` dari `state` (0 bila id tidak dikenal atau data tidak sah).
static func nilai(state: Dictionary, id: String) -> int:
	match id:
		"pelanggan_tetap":
			return _hitung_setia(state)
		"koin_total":
			return _bulat(state.get("koin_total"))
		"misi_selesai":
			return _hitung_misi_selesai(state)
		"sepeda":
			return _hitung_sepeda(state)
	return 0


## Tingkat (0..3) untuk nilai `n` pada milestone `id`: banyaknya target yang sudah dicapai atau dilewati (tepat di target = tercapai).
static func tingkat(id: String, n: int) -> int:
	var t: int = 0
	for target: int in daftar_target(id):
		if n >= target:
			t += 1
	return t


## Status milestone `id` dari `state`.
static func status(state: Dictionary, id: String) -> Status:
	var s: Status = Status.new()
	s.id = id
	s.nilai = nilai(state, id)
	s.tingkat = tingkat(id, s.nilai)
	var daftar: Array[int] = daftar_target(id)
	s.target = daftar[s.tingkat] if s.tingkat < daftar.size() else -1
	return s


## Status semua milestone, urut `Config.MILESTONE_ID`.
static func semua(state: Dictionary) -> Array[Status]:
	var hasil: Array[Status] = []
	for id: String in Config.MILESTONE_ID:
		hasil.append(status(state, id))
	return hasil


## Milestone yang paling dekat tercapai (lihat atas), null bila semua sudah emas.
static func paling_dekat(state: Dictionary) -> Status:
	var terbaik: Status = null
	for s: Status in semua(state):
		if s.tamat():
			continue
		if terbaik == null or _lebih_dekat(s, terbaik):
			terbaik = s
	return terbaik


## Tingkat yang naik dari state `sebelum` ke `sesudah`, urut tingkat tertinggi dulu lalu urutan `Config.MILESTONE_ID`. Tingkat tidak pernah turun: penurunan (state mundur) diabaikan.
static func baru_tercapai(sebelum: Dictionary, sesudah: Dictionary) -> Array[Capaian]:
	var hasil: Array[Capaian] = []
	for id: String in Config.MILESTONE_ID:
		var lama: int = tingkat(id, nilai(sebelum, id))
		var baru: int = tingkat(id, nilai(sesudah, id))
		if baru > lama:
			var c: Capaian = Capaian.new()
			c.id = id
			c.tingkat = baru
			c.tingkat_sebelum = lama
			hasil.append(c)
	# Urut stabil: tingkat tertinggi dulu; seri mempertahankan urutan id (penyisipan).
	for i: int in range(1, hasil.size()):
		var kunci: Capaian = hasil[i]
		var j: int = i - 1
		while j >= 0 and hasil[j].tingkat < kunci.tingkat:
			hasil[j + 1] = hasil[j]
			j -= 1
		hasil[j + 1] = kunci
	return hasil


## Ringkasan hari: status sesudah, yang paling dekat tercapai (dihitung dari state sesudah), dan yang baru tercapai.
static func ringkas(sebelum: Dictionary, sesudah: Dictionary) -> Ringkasan:
	var r: Ringkasan = Ringkasan.new()
	r.daftar = semua(sesudah)
	r.terdekat = paling_dekat(sesudah)
	r.baru = baru_tercapai(sebelum, sesudah)
	return r


## Nama tingkat `tingkat` (1..3) sebagai id ("perunggu", "perak", "emas"); "" untuk 0 atau di luar rentang.
static func nama_tingkat(tingkat_ke: int) -> String:
	if tingkat_ke < 1 or tingkat_ke > Config.MILESTONE_TINGKAT.size():
		return ""
	return Config.MILESTONE_TINGKAT[tingkat_ke - 1]


# --- Pembantu ---

## True bila `a` lebih dekat tercapai dari `b` (pecahan lebih besar, lalu sisa lebih kecil; seri terakhir ditentukan urutan id oleh pemanggil yang menjaga yang lebih awal).
static func _lebih_dekat(a: Status, b: Status) -> bool:
	var kiri: int = a.nilai * b.target
	var kanan: int = b.nilai * a.target
	if kiri != kanan:
		return kiri > kanan
	return a.sisa() < b.sisa()


static func _bulat(v: Variant) -> int:
	if not ParseData.angka(v):
		return 0
	return clampi(int(v), 0, Config.SAVE_ANGKA_MAKS)


static func _hitung_setia(state: Dictionary) -> int:
	var peta: Variant = state.get("pelanggan")
	if typeof(peta) != TYPE_DICTIONARY:
		return 0
	var n: int = 0
	for id: Variant in (peta as Dictionary):
		var entri: Variant = (peta as Dictionary)[id]
		if typeof(entri) == TYPE_DICTIONARY and str((entri as Dictionary).get("status", "")) == "setia":
			n += 1
	return n


static func _hitung_misi_selesai(state: Dictionary) -> int:
	var peta: Variant = state.get("misi_hasil")
	if typeof(peta) != TYPE_DICTIONARY:
		return 0
	var n: int = 0
	for id: Variant in (peta as Dictionary):
		var entri: Variant = (peta as Dictionary)[id]
		if typeof(entri) == TYPE_DICTIONARY and str((entri as Dictionary).get("hasil", "")) == "selesai":
			n += 1
	return n


static func _hitung_sepeda(state: Dictionary) -> int:
	var sepeda: Variant = state.get("sepeda")
	if typeof(sepeda) != TYPE_DICTIONARY:
		return 0
	var s: Dictionary = sepeda
	var n: int = _bulat(s.get("servis_total"))
	for komponen: String in Config.KONDISI_KOMPONEN:
		var entri: Variant = s.get(komponen)
		if typeof(entri) == TYPE_DICTIONARY:
			n += _bulat((entri as Dictionary).get("level"))
	return n
