class_name Economy
extends RefCounted
## Ekonomi bengkel, logika murni (GDD 12.3, 14; BALANCING 7 dan 8; run fase6a1-bengkel-kondisi, AC-13 sampai AC-16, M-9 dan M-10, K-1 dan K-4; usulan).
## Bekerja pada state save (`DataSave`): `koin` adalah SALDO yang boleh turun hanya karena belanja yang disengaja (servis, upgrade), `koin_total` dan `tip_total` tidak pernah berubah
## karena belanja, `sepeda.<komponen>.kondisi` dan `.level`, dan `sepeda.servis_total`. Setiap transaksi ATOMIK: ditolak = state keluaran identik dengan masukan (alasan enum, tanpa
## efek samping); diterima = tepat satu komponen berubah dan saldo berkurang tepat harga. Masukan tidak pernah diubah. Tanpa node, `Time`, atau RNG. Harga dan angka di `Config`
## (`SERVIS_*`); upgrade dari `PemuatToko`/`DataToko`. Tidak ada cabang mode bantu (K-2) dan tidak ada iklan (rule `privacy-ads`, AC-16).

## Alasan hasil transaksi.
enum Alasan { DITERIMA, KOIN_KURANG, KOMPONEN_PENUH, KOMPONEN_TIDAK_DIKENAL, UPGRADE_TIDAK_DIKENAL, SUDAH_DIMILIKI, LEVEL_TIDAK_BERURUTAN }


## Hasil satu transaksi: state sesudahnya (salinan baru; sama dengan masukan bila ditolak), apakah diterima, alasannya, dan harga yang dibayar (0 bila ditolak).
class Hasil extends RefCounted:
	var state: Dictionary = {}
	var diterima: bool = false
	var alasan: Economy.Alasan = Economy.Alasan.KOMPONEN_TIDAK_DIKENAL
	var harga: int = 0


## Pengali ongkos servis bila `jumlah` komponen PERLU_BENGKEL (M-9, GDD 12.3): 1 + `SERVIS_KENAIKAN_PER_RUSAK` x (jumlah - 1) untuk jumlah >= 2, selain itu 1,0.
static func pengali_ongkos(jumlah: int) -> float:
	if jumlah < 2:
		return 1.0
	return 1.0 + Config.SERVIS_KENAIKAN_PER_RUSAK * float(jumlah - 1)


## Harga servis `komponen` berkondisi `kondisi` bila `jumlah_perlu_bengkel` komponen PERLU_BENGKEL: harga penuh x (1 - kondisi) x pengali ongkos, dibulatkan ke koin terdekat
## (setengah menjauhi nol = ke atas, `roundi`), paling murah `SERVIS_HARGA_MIN`. Kondisi 1,0 (atau lebih) atau komponen asing = 0 (tidak bisa diservis).
static func harga_servis(komponen: String, kondisi: float, jumlah_perlu_bengkel: int) -> int:
	var indeks: int = Config.KONDISI_KOMPONEN.find(komponen)
	if indeks < 0 or _penuh(kondisi):
		return 0
	var dasar: float = float(Config.SERVIS_HARGA_PENUH[indeks]) * (1.0 - BikeCondition.jepit(kondisi)) * pengali_ongkos(jumlah_perlu_bengkel)
	return maxi(Config.SERVIS_HARGA_MIN, roundi(dasar))


## Harga servis `komponen` pada `state` sekarang (jumlah komponen PERLU_BENGKEL dihitung dari state). 0 bila tidak bisa diservis.
static func harga_servis_state(state: Dictionary, komponen: String) -> int:
	var kondisi: Dictionary = kondisi_dari(state)
	if not kondisi.has(komponen):
		return 0
	return harga_servis(komponen, float(kondisi[komponen]), BikeCondition.perlu_bengkel(kondisi).size())


## Servis `komponen`: kondisi kembali 1,0, `servis_total` + 1, saldo berkurang harga servis. Ditolak: komponen asing, komponen sudah 1,0, saldo kurang (`koin` < harga).
static func servis(state: Dictionary, komponen: String) -> Hasil:
	var hasil: Hasil = _tolak(state, Alasan.KOMPONEN_TIDAK_DIKENAL)
	if not Config.KONDISI_KOMPONEN.has(komponen):
		return hasil
	var kondisi: Dictionary = kondisi_dari(state)
	if _penuh(float(kondisi[komponen])):
		return _tolak(state, Alasan.KOMPONEN_PENUH)
	var harga: int = harga_servis_state(state, komponen)
	if saldo(state) < harga:
		return _tolak(state, Alasan.KOIN_KURANG)
	var baru: Dictionary = _salin_sepeda(state)
	var sepeda: Dictionary = baru["sepeda"]
	var entri: Dictionary = sepeda[komponen]
	entri["kondisi"] = 1.0
	sepeda["servis_total"] = _bulat(sepeda.get("servis_total", 0)) + 1
	baru["koin"] = saldo(state) - harga
	return _terima(baru, harga)


## Beli upgrade `id` dari `daftar`: level komponen naik 1, saldo berkurang harga. Ditolak: id tak dikenal, sudah dimiliki, level tidak berurutan (level N hanya bila N - 1 dimiliki),
## saldo kurang (`koin` < harga; tepat sama dengan harga sah).
static func beli_upgrade(state: Dictionary, id: String, daftar: Array[DataToko]) -> Hasil:
	var u: DataToko = null
	for kandidat: DataToko in daftar:
		if kandidat.id == id:
			u = kandidat
			break
	if u == null or not Config.KONDISI_KOMPONEN.has(u.komponen):
		return _tolak(state, Alasan.UPGRADE_TIDAK_DIKENAL)
	var level: int = int(level_dari(state)[u.komponen])
	if level >= u.level:
		return _tolak(state, Alasan.SUDAH_DIMILIKI)
	if u.level != level + 1:
		return _tolak(state, Alasan.LEVEL_TIDAK_BERURUTAN)
	if saldo(state) < u.harga:
		return _tolak(state, Alasan.KOIN_KURANG)
	var baru: Dictionary = _salin_sepeda(state)
	var sepeda: Dictionary = baru["sepeda"]
	var entri: Dictionary = sepeda[u.komponen]
	entri["level"] = u.level
	baru["koin"] = saldo(state) - u.harga
	return _terima(baru, u.harga)


## Saldo koin pada `state` (0 bila tidak ada atau negatif).
static func saldo(state: Dictionary) -> int:
	return maxi(_bulat(state.get("koin", 0)), 0)


## Kondisi tiga komponen dari `state.sepeda` (hilang atau tidak sah = 1,0).
static func kondisi_dari(state: Dictionary) -> Dictionary:
	var hasil: Dictionary = BikeCondition.baru()
	var sepeda: Variant = state.get("sepeda")
	if typeof(sepeda) != TYPE_DICTIONARY:
		return hasil
	for k: String in Config.KONDISI_KOMPONEN:
		var entri: Variant = (sepeda as Dictionary).get(k)
		if typeof(entri) == TYPE_DICTIONARY:
			hasil[k] = BikeCondition.jepit((entri as Dictionary).get("kondisi", 1.0))
	return hasil


## Level upgrade tiga komponen dari `state.sepeda` (hilang atau tidak sah = 0).
static func level_dari(state: Dictionary) -> Dictionary:
	var hasil: Dictionary = {}
	for k: String in Config.KONDISI_KOMPONEN:
		hasil[k] = 0
	var sepeda: Variant = state.get("sepeda")
	if typeof(sepeda) != TYPE_DICTIONARY:
		return hasil
	for k: String in Config.KONDISI_KOMPONEN:
		var entri: Variant = (sepeda as Dictionary).get(k)
		if typeof(entri) == TYPE_DICTIONARY:
			hasil[k] = maxi(_bulat((entri as Dictionary).get("level", 0)), 0)
	return hasil


## Jumlah servis seumur hidup pada `state` (`sepeda.servis_total`).
static func servis_total(state: Dictionary) -> int:
	var sepeda: Variant = state.get("sepeda")
	if typeof(sepeda) != TYPE_DICTIONARY:
		return 0
	return maxi(_bulat((sepeda as Dictionary).get("servis_total", 0)), 0)


static func _penuh(kondisi: float) -> bool:
	return BikeCondition.jepit(kondisi) >= 1.0 - Config.KONDISI_TOLERANSI


static func _bulat(nilai: Variant) -> int:
	var tipe: int = typeof(nilai)
	if (tipe != TYPE_INT and tipe != TYPE_FLOAT) or not is_finite(float(nilai)):
		return 0
	return int(clampf(float(nilai), -float(Config.SAVE_ANGKA_MAKS), float(Config.SAVE_ANGKA_MAKS)))


## Salinan dalam `state` yang pasti memuat `sepeda` dengan tiga komponen (kondisi dan level) dan `servis_total`.
static func _salin_sepeda(state: Dictionary) -> Dictionary:
	var baru: Dictionary = state.duplicate(true)
	var sepeda: Dictionary = {}
	var lama: Variant = baru.get("sepeda")
	if typeof(lama) == TYPE_DICTIONARY:
		sepeda = lama
	for k: String in Config.KONDISI_KOMPONEN:
		var entri: Variant = sepeda.get(k)
		if typeof(entri) != TYPE_DICTIONARY:
			sepeda[k] = {"kondisi": 1.0, "level": 0}
	if not sepeda.has("servis_total"):
		sepeda["servis_total"] = 0
	baru["sepeda"] = sepeda
	return baru


static func _tolak(state: Dictionary, alasan: Alasan) -> Hasil:
	var h: Hasil = Hasil.new()
	h.state = state.duplicate(true)
	h.diterima = false
	h.alasan = alasan
	return h


static func _terima(state: Dictionary, harga: int) -> Hasil:
	var h: Hasil = Hasil.new()
	h.state = state
	h.diterima = true
	h.alasan = Alasan.DITERIMA
	h.harga = harga
	return h
