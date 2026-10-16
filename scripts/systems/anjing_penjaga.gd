class_name AnjingPenjaga
extends RefCounted
## Anjing penjaga perumahan, mesin keadaan murni (GDD 5.1 dan 9.3, ROUTE_DESIGN 4; AC-1, AC-3, AC-14 run fase3b-rintangan-skor, usulan).
##
## Tanpa node, `Time`, atau RNG: keadaan, posisi dan kecepatan sepeda, dan `dt` adalah parameter, jadi anjing yang sama di posisi yang sama
## dengan masukan yang sama selalu berperilaku sama (ROUTE_DESIGN 4 aturan 3). `langkah` tidak mengubah masukannya. Koordinat jalan:
## lateral dari garis tengah (negatif = `seberang`), maju dari awal rute, ubin.
##
## Pola (angka di `Config.ANJING_*`):
## - `DIAM`: duduk di halaman, pusat di lateral +-`ANJING_RUMAH_LATERAL_UBIN` (sisi jalurnya), maju = titik rumah (`pos` objek segmen).
## - `WASPADA` (tanda: berdiri dan menggeram): sepeda masuk `tanda_ubin` (data segmen, paling sedikit 9 ubin = 1,5 detik pada ngebut) di
##   belakang titik rumah. Anjing tetap di halaman.
## - `MENGEJAR` (menggonggong dan lari): sepeda sudah sampai `ANJING_KEJAR_JARAK_UBIN` di belakang titik rumah atau lebih maju. Anjing lari
##   searah jalan menuju maju sepeda (tidak pernah mendahuluinya) dengan laju = kecepatan sepeda x `ANJING_KEJAR_PENGALI`, dijepit
##   `ANJING_LAJU_MIN_UD`..`ANJING_LAJU_MAKS_UD`, dan menyamping ke arah lateral sepeda dengan `ANJING_LATERAL_UD`, tetapi hanya di
##   separuh jalan sisinya: tepi bentuknya tidak pernah melewati garis tengah (K-1). Maju dijepit titik rumah sampai batas halaman
##   (`ANJING_BATAS_MAJU_UBIN`).
## - `BERHENTI`: sampai di batas halaman, atau sesudah menabrak sepeda (`kena_tabrak`). Diam `ANJING_BERHENTI_DETIK`, lalu `PULANG`.
## - `PULANG`: kembali ke titik rumah dengan `ANJING_PULANG_UD` per sumbu, lalu `DIAM` dengan `selesai` menyala.
## - `MUNDUR` (bel, K-3): anjing `WASPADA` atau `MENGEJAR` yang mendengar bel (`dengar_bel`) diam `ANJING_KAGET_DETIK` (ikon "!") lalu
##   mundur ke titik rumah dengan `ANJING_MUNDUR_UD`, lalu `DIAM` dengan `selesai`.
## `selesai` = anjing sudah beraksi untuk lintasan sepeda ini (tidak waspada atau mengejar lagi sampai rute disusun ulang).
## Berbahaya (bisa menabrak) hanya di `MENGEJAR` dan `BERHENTI`; di halaman bentuknya di luar jangkauan sepeda, dan anjing yang pulang atau
## mundur tidak menggigit. Transisi diperiksa dengan posisi sepeda langkah ini, lalu anjing bergerak selama `dt`; `dt` 0 (jeda) = tidak
## ada yang berubah.

enum Status { DIAM, WASPADA, MENGEJAR, BERHENTI, PULANG, MUNDUR }

## Nama animasi di `assets/sprites/obstacles/obs_anjing_sheet.json` (`anim`) per status.
const ANIMASI: Dictionary = {
	Status.DIAM: "diam",
	Status.WASPADA: "tanda",
	Status.MENGEJAR: "lari",
	Status.BERHENTI: "berhenti",
	Status.PULANG: "lari",
	Status.MUNDUR: "lari",
}


## Keadaan satu anjing. Dibuat `baru`, diganti objek baru oleh `langkah` dan fungsi lain.
class Keadaan extends RefCounted:
	var status: Status = Status.DIAM
	## Sisi jalur anjing (`SEBERANG` atau `DEKAT`).
	var sisi: LoperAnim.Sisi = LoperAnim.Sisi.SEBERANG
	## Titik rumah: maju dari awal rute, ubin.
	var rumah_maju_ubin: float = 0.0
	## Jarak tanda dari data segmen, ubin.
	var tanda_ubin: float = 0.0
	## Posisi pusat sekarang, koordinat jalan, ubin.
	var maju_ubin: float = 0.0
	var lateral_ubin: float = 0.0
	## Lama di status sekarang, detik.
	var detik_status: float = 0.0
	## Sisa diam kaget (ikon "!") sesudah mendengar bel, detik.
	var kaget_detik: float = 0.0
	## True sesudah anjing beraksi untuk lintasan sepeda ini.
	var selesai: bool = false

	func salin() -> Keadaan:
		var baru: Keadaan = Keadaan.new()
		baru.status = status
		baru.sisi = sisi
		baru.rumah_maju_ubin = rumah_maju_ubin
		baru.tanda_ubin = tanda_ubin
		baru.maju_ubin = maju_ubin
		baru.lateral_ubin = lateral_ubin
		baru.detik_status = detik_status
		baru.kaget_detik = kaget_detik
		baru.selesai = selesai
		return baru


## Anjing baru di titik rumah `rumah_maju_ubin`, jalur `sisi`, dengan jarak tanda `tanda_ubin`, duduk di halamannya.
static func baru(rumah_maju_ubin: float, sisi: LoperAnim.Sisi, tanda_ubin: float) -> Keadaan:
	var k: Keadaan = Keadaan.new()
	k.sisi = sisi
	k.rumah_maju_ubin = rumah_maju_ubin
	k.tanda_ubin = tanda_ubin
	k.maju_ubin = rumah_maju_ubin
	k.lateral_ubin = rumah_lateral(sisi)
	return k


## Pusat lateral anjing di halamannya untuk `sisi` (negatif = `seberang`).
static func rumah_lateral(sisi: LoperAnim.Sisi) -> float:
	return _arah(sisi) * Config.ANJING_RUMAH_LATERAL_UBIN


## Rentang pusat lateral anjing (min, maks) di sisinya: dari halaman sampai tepi bentuknya tepat di garis tengah (separuh jalan, K-1).
static func rentang_lateral(sisi: LoperAnim.Sisi) -> Vector2:
	var a: float = rumah_lateral(sisi)
	var b: float = _arah(sisi) * Config.ANJING_SETENGAH_UBIN
	return Vector2(minf(a, b), maxf(a, b))


## Laju maju anjing saat mengejar sepeda berkecepatan `kecepatan_ud`: x pengali, dijepit batas bawah dan atas.
static func laju_kejar_ud(kecepatan_ud: float) -> float:
	var v: float = kecepatan_ud if is_finite(kecepatan_ud) and kecepatan_ud > 0.0 else 0.0
	return clampf(v * Config.ANJING_KEJAR_PENGALI, Config.ANJING_LAJU_MIN_UD, Config.ANJING_LAJU_MAKS_UD)


## Satu langkah `dt` detik dengan sepeda di (`sepeda_lateral`, `sepeda_maju`) berkecepatan `sepeda_kecepatan_ud`. `dt` nol, negatif, atau
## tidak hingga = keadaan tidak berubah (jeda membekukan). Masukan tidak diubah.
static func langkah(k: Keadaan, sepeda_maju: float, sepeda_lateral: float, sepeda_kecepatan_ud: float, dt: float) -> Keadaan:
	var s: Keadaan = k.salin()
	if not is_finite(dt) or dt <= 0.0 or not is_finite(sepeda_maju):
		return s
	_transisi(s, sepeda_maju)
	s.detik_status += dt
	match s.status:
		Status.MENGEJAR:
			var batas: Vector2 = rentang_lateral(s.sisi)
			var lateral_sasaran: float = clampf(sepeda_lateral if is_finite(sepeda_lateral) else s.lateral_ubin, batas.x, batas.y)
			var maju_sasaran: float = clampf(sepeda_maju, s.rumah_maju_ubin, s.rumah_maju_ubin + Config.ANJING_BATAS_MAJU_UBIN)
			s.maju_ubin = move_toward(s.maju_ubin, maju_sasaran, laju_kejar_ud(sepeda_kecepatan_ud) * dt)
			s.lateral_ubin = move_toward(s.lateral_ubin, lateral_sasaran, Config.ANJING_LATERAL_UD * dt)
			if s.maju_ubin >= s.rumah_maju_ubin + Config.ANJING_BATAS_MAJU_UBIN:
				_ganti(s, Status.BERHENTI)
		Status.BERHENTI:
			if s.detik_status + Config.TABRAKAN_TOLERANSI_DETIK >= Config.ANJING_BERHENTI_DETIK:
				_ganti(s, Status.PULANG)
		Status.PULANG:
			_dekati_rumah(s, Config.ANJING_PULANG_UD * dt)
		Status.MUNDUR:
			var sisa: float = dt
			if s.kaget_detik > 0.0:
				var pakai: float = minf(s.kaget_detik, sisa)
				s.kaget_detik -= pakai
				sisa -= pakai
				if s.kaget_detik <= Config.TABRAKAN_TOLERANSI_DETIK:
					s.kaget_detik = 0.0
			if sisa > 0.0:
				_dekati_rumah(s, Config.ANJING_MUNDUR_UD * sisa)
	return s


## True bila anjing bereaksi pada bel sekarang: hanya saat `WASPADA` atau `MENGEJAR` (anjing `DIAM` dan yang sudah pulang tidak).
static func bisa_dengar_bel(k: Keadaan) -> bool:
	return k.status == Status.WASPADA or k.status == Status.MENGEJAR


## Anjing mendengar bel (K-3, AC-14): bila `bisa_dengar_bel`, kaget (ikon "!") lalu mundur ke halamannya dan tidak mengejar lagi untuk
## lintasan sepeda ini. Selain itu tidak berubah. Masukan tidak diubah.
static func dengar_bel(k: Keadaan) -> Keadaan:
	var s: Keadaan = k.salin()
	if not bisa_dengar_bel(s):
		return s
	_ganti(s, Status.MUNDUR)
	s.kaget_detik = Config.ANJING_KAGET_DETIK
	s.selesai = true
	return s


## Anjing yang menabrak sepeda berhenti mengejar (`BERHENTI`, lalu pulang). Status lain tidak berubah. Masukan tidak diubah.
static func kena_tabrak(k: Keadaan) -> Keadaan:
	var s: Keadaan = k.salin()
	if s.status == Status.MENGEJAR:
		_ganti(s, Status.BERHENTI)
	return s


## True bila anjing bisa menabrak sepeda sekarang (`MENGEJAR` atau `BERHENTI`).
static func berbahaya(k: Keadaan) -> bool:
	return k.status == Status.MENGEJAR or k.status == Status.BERHENTI


## True selama ikon "!" tampil (kaget sesudah bel).
static func ikon_seru(k: Keadaan) -> bool:
	return k.status == Status.MUNDUR and k.kaget_detik > 0.0


## Bentuk tabrakan di bidang tanah, koordinat jalan (x = lateral, y = maju), ubin.
static func kotak(k: Keadaan) -> Rect2:
	var setengah: Vector2 = Vector2(Config.ANJING_SETENGAH_UBIN, Config.ANJING_SETENGAH_UBIN)
	var pusat: Vector2 = Vector2(k.lateral_ubin, k.maju_ubin)
	return Rect2(pusat - setengah, setengah + setengah)


## Nama animasi sprite untuk status sekarang (`ANIMASI`). Selama kaget sesudah bel (ikon "!", `ikon_seru`) anjing diam berdiri:
## animasi `berhenti`, baru `lari` saat mundur (bagian B, tangkapan probe: anjing kaget yang "berlari" di tempat tidak terbaca kaget).
static func animasi(k: Keadaan) -> String:
	if ikon_seru(k):
		return ANIMASI[Status.BERHENTI]
	return ANIMASI[k.status]


## Transisi yang dipicu posisi sepeda (bisa berantai dalam satu langkah, mis. DIAM -> WASPADA -> MENGEJAR bila sepeda sudah lewat).
static func _transisi(s: Keadaan, sepeda_maju: float) -> void:
	if s.status == Status.DIAM and not s.selesai and sepeda_maju >= s.rumah_maju_ubin - s.tanda_ubin:
		_ganti(s, Status.WASPADA)
	if s.status == Status.WASPADA and sepeda_maju >= s.rumah_maju_ubin - Config.ANJING_KEJAR_JARAK_UBIN:
		_ganti(s, Status.MENGEJAR)


static func _ganti(s: Keadaan, status: Status) -> void:
	s.status = status
	s.detik_status = 0.0


## Bergerak ke titik rumah sejauh `jarak` per sumbu; sampai = `DIAM` dan `selesai`.
static func _dekati_rumah(s: Keadaan, jarak: float) -> void:
	var lateral_rumah: float = rumah_lateral(s.sisi)
	s.maju_ubin = move_toward(s.maju_ubin, s.rumah_maju_ubin, jarak)
	s.lateral_ubin = move_toward(s.lateral_ubin, lateral_rumah, jarak)
	if is_equal_approx(s.maju_ubin, s.rumah_maju_ubin) and is_equal_approx(s.lateral_ubin, lateral_rumah):
		s.maju_ubin = s.rumah_maju_ubin
		s.lateral_ubin = lateral_rumah
		_ganti(s, Status.DIAM)
		s.selesai = true


## Tanda arah lateral sisi: -1 untuk `seberang`, 1 untuk `dekat` (`Iso.ARAH_SEBERANG` / `Iso.ARAH_DEKAT`).
static func _arah(sisi: LoperAnim.Sisi) -> float:
	return Iso.ARAH_SEBERANG.x if sisi == LoperAnim.Sisi.SEBERANG else Iso.ARAH_DEKAT.x
