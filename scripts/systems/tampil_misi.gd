class_name TampilMisi
extends RefCounted
## Geometri layar kucing misi: kapan kucing "terlihat" di layar dan di mana penanda tepi layarnya (M-2' dan M-3', QA-001 dan QA-002 run
## fase4b-misi-kucing iterasi 2, usulan; prinsip 3: petunjuk misi punya penanda visual minimal 2 detik).
##
## Logika murni. Dari posisi sepeda di layar, jarak maju dan lateral sepeda, letak kucing di dunia (`RencanaMisi.Titik`), dan ukuran area layar -> posisi
## kaki kucing di layar (`Iso`, satu-satunya proyeksi), persegi badan + kilau, dan penanda tepi layar. Aturannya:
## - Kucing "terlihat" di layar bila badannya (sel sheet penuh + kilau di atas kepala, perkiraan terburuk) utuh di `area` (layar dikurangi tepi radar dan
##   strip HUD atas: panel progres, koin, skor, kartu/banner/gelembung misi) ATAU penanda tepi layarnya tampil.
## - Penanda tepi layar tampil bila badan belum utuh di `area`: titik di garis dari sepeda ke kaki kucing yang dijepit ke persegi pusat penanda
##   (`area_penanda`), jadi selalu di dalam layar, di luar radar, bel, jeda, panel atas, dan kartu/banner (dibuktikan tes pada geometri nyata dan pada
##   persegi HUD nyata), menunjuk ke atas bila menyentuh tepi atas, ke kanan bila menyentuh tepi kanan.
## Kamera, dorongan kecepatan, dan lebar viewport masuk lewat posisi sepeda di layar (`sepeda_layar_nominal` untuk tes, `AdeganJalan.posisi_layar_sepeda`
## di game). Tanpa node, `Time`, atau RNG; masukan tidak diubah.

enum Arah { ATAS, KANAN }


## Satu penanda tepi layar.
class Penanda extends RefCounted:
	## Indeks titik kucing di `RencanaMisi`.
	var titik: int = 0
	## Pusat penanda, piksel game.
	var pusat: Vector2 = Vector2.ZERO
	var arah: Arah = Arah.ATAS


## Posisi titik pijak sepeda di layar pada kamera yang mengikutinya: `KAMERA_SEPEDA_*_PECAHAN` dari ukuran viewport ditambah geseran dorongan kecepatan
## `kecepatan_ud` (nilai mantap; sama dengan `AdeganJalan.posisi_kamera` sebelum dibulatkan).
static func sepeda_layar_nominal(lebar: float, tinggi: float, kecepatan_ud: float) -> Vector2:
	return sepeda_layar(Vector2(lebar, tinggi), DoronganKecepatan.geser_target(kecepatan_ud))


## Posisi titik pijak sepeda di layar untuk viewport `ukuran` dan geseran dorongan `geser` (yang dituju kamera, `AdeganJalan.posisi_kamera`): tanpa jeda satu bingkai
## dan tanpa pembulatan piksel kamera.
static func sepeda_layar(ukuran: Vector2, geser: Vector2) -> Vector2:
	return Vector2(ukuran.x * Config.KAMERA_SEPEDA_X_PECAHAN, ukuran.y * Config.KAMERA_SEPEDA_Y_PECAHAN) + geser


## Titik pijak kucing di layar untuk sepeda yang berada di `sepeda_layar` pada (lateral, maju) sepeda dan kucing di (lateral, maju) kucing (ubin, dunia: y = -maju).
static func kaki_kucing(sepeda_layar: Vector2, lateral_sepeda: float, maju_sepeda: float, lateral_kucing: float, maju_kucing: float) -> Vector2:
	return sepeda_layar + Iso.dunia_ke_layar(Vector2(lateral_kucing - lateral_sepeda, -(maju_kucing - maju_sepeda)))


## Area layar tempat badan kucing dan penanda boleh berada: lebar dikurangi `MISI_PENANDA_TEPI_PX` + geseran zona aman di kiri dan kanan, mulai
## `MISI_PENANDA_ATAS_PX` + geseran zona aman dari atas, sampai tepi bawah layar.
static func area(lebar: float, tinggi: float, geser_awal_x: int = 0, geser_atas: int = 0, geser_akhir_x: int = 0) -> Rect2:
	var x_awal: float = float(Config.MISI_PENANDA_TEPI_PX + geser_awal_x)
	var x_akhir: float = lebar - float(Config.MISI_PENANDA_TEPI_PX + geser_akhir_x)
	var atas: float = float(Config.MISI_PENANDA_ATAS_PX + geser_atas)
	return Rect2(x_awal, atas, maxf(x_akhir - x_awal, 0.0), maxf(tinggi - atas, 0.0))


## Persegi tempat PUSAT penanda boleh berada: `area` dipersempit setengah ukuran penanda di tiap sisi dan dipotong `MISI_PENANDA_BAWAH_PX` dari bawah layar
## (di atas bel dan panel bawah).
static func area_penanda(area_layar: Rect2, tinggi: float) -> Rect2:
	var bawah: float = minf(area_layar.end.y, tinggi - float(Config.MISI_PENANDA_BAWAH_PX))
	var ukuran: float = float(Config.MISI_PENANDA_UKURAN_PX)
	return Rect2(area_layar.position + Vector2(_setengah(), _setengah()), Vector2(maxf(area_layar.size.x - ukuran, 0.0), maxf(bawah - area_layar.position.y - ukuran, 0.0)))


## Persegi badan kucing yang harus utuh di `area`: sel sheet penuh (perkiraan terburuk, piksel kosong ikut dihitung) disatukan dengan pola kilau di atas kepala.
static func rect_badan(kaki: Vector2) -> Rect2:
	var sel: Rect2 = Rect2(kaki - Vector2(Config.MISI_KUCING_PIJAK_PX[0], Config.MISI_KUCING_PIJAK_PX[1]), Vector2(Config.MISI_KUCING_SEL_PX[0], Config.MISI_KUCING_SEL_PX[1]))
	var kilau: Rect2 = Rect2(kaki + Vector2(Config.MISI_KILAU_POSISI_PX[0], Config.MISI_KILAU_POSISI_PX[1]), Vector2(PolaPiksel.KILAU_KUCING_2[0].length(), PolaPiksel.KILAU_KUCING_2.size()))
	return sel.merge(kilau)


## True bila badan kucing berkaki di `kaki` utuh di `area_layar` (tidak ada penanda tepi layar perlu ditampilkan untuk kucing yang digambar).
static func badan_terlihat(kaki: Vector2, area_layar: Rect2) -> bool:
	return area_layar.encloses(rect_badan(kaki))


## Penanda tepi layar untuk kucing titik `titik` berkaki di `kaki`, sepeda di `sepeda_layar`: titik di garis sepeda -> kaki yang dijepit ke `area_penanda`; bila kaki
## sendiri di dalam persegi itu, penanda `MISI_PENANDA_TURUN_PX` di bawah kaki (menunjuk ke kucing, tidak menutupi badannya).
## Selalu ada penanda (pemanggil memutuskan perlu atau tidaknya dengan `badan_terlihat`).
static func penanda(titik: int, sepeda_layar: Vector2, kaki: Vector2, area_layar: Rect2, tinggi: float) -> Penanda:
	var p: Penanda = Penanda.new()
	p.titik = titik
	var kotak: Rect2 = area_penanda(area_layar, tinggi)
	var awal: Vector2 = Vector2(clampf(sepeda_layar.x, kotak.position.x, kotak.end.x), clampf(sepeda_layar.y, kotak.position.y, kotak.end.y))
	var selisih: Vector2 = kaki - awal
	var t: float = 1.0
	if selisih.x > 0.0:
		t = minf(t, (kotak.end.x - awal.x) / selisih.x)
	elif selisih.x < 0.0:
		t = minf(t, (kotak.position.x - awal.x) / selisih.x)
	if selisih.y > 0.0:
		t = minf(t, (kotak.end.y - awal.y) / selisih.y)
	elif selisih.y < 0.0:
		t = minf(t, (kotak.position.y - awal.y) / selisih.y)
	var tujuan: Vector2 = awal + selisih * clampf(t, 0.0, 1.0)
	if t >= 1.0:
		tujuan = Vector2(clampf(kaki.x, kotak.position.x, kotak.end.x), clampf(kaki.y + float(Config.MISI_PENANDA_TURUN_PX), kotak.position.y, kotak.end.y))
	p.pusat = tujuan.round()
	p.arah = Arah.KANAN if p.pusat.y > kotak.position.y and p.pusat.x >= kotak.end.x else Arah.ATAS
	return p


## Persegi penanda `p` di layar (ukuran `MISI_PENANDA_UKURAN_PX`, piksel tengahnya di `pusat`).
static func rect_penanda(p: Penanda) -> Rect2:
	var ukuran: float = float(Config.MISI_PENANDA_UKURAN_PX)
	return Rect2(p.pusat - Vector2(_setengah(), _setengah()), Vector2(ukuran, ukuran))


## Jarak pusat penanda ke tepi atas dan kiri persegi penanda, piksel bulat (ukuran ganjil: pusat di piksel tengah).
static func _setengah() -> float:
	return float(Config.MISI_PENANDA_UKURAN_PX / 2)


## Pola panah penanda sesuai arah.
static func pola(arah: Arah) -> Array[String]:
	return PolaPiksel.putar_kanan(PolaPiksel.PANAH_KUCING_ATAS) if arah == Arah.KANAN else PolaPiksel.PANAH_KUCING_ATAS


## Penanda tepi layar yang harus tampil untuk keadaan misi `k`: tiap kucing yang ditandai terlihat dan belum selesai (`MissionManager.indeks_terlihat`) yang
## badannya belum utuh di layar, atau yang bukan kucing yang digambar (hanya kucing langkah aktif punya badan). Kucing yang sudah di belakang sepeda tidak
## diberi penanda (penanda hanya menunjuk ke depan). `sepeda_layar` dan jarak/lateral sepeda dari game.
static func penanda_aktif(k: MissionManager.Keadaan, sepeda_layar: Vector2, lateral_sepeda: float, maju_sepeda: float, area_layar: Rect2, tinggi: float) -> Array[Penanda]:
	var hasil: Array[Penanda] = []
	for i: int in MissionManager.indeks_terlihat(k):
		var t: RencanaMisi.Titik = k.rencana.titik[i]
		if t.maju_ubin <= maju_sepeda:
			continue
		var kaki: Vector2 = kaki_kucing(sepeda_layar, lateral_sepeda, maju_sepeda, t.lateral_ubin, t.maju_ubin)
		if i == k.langkah and badan_terlihat(kaki, area_layar):
			continue
		hasil.append(penanda(i, sepeda_layar, kaki, area_layar, tinggi))
	return hasil
