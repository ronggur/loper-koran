class_name DekorRute
extends RefCounted
## Dekor pinggir jalan (tong sampah, pohon, lampu jalan): jenis, varian, letak, tapak kaki, sprite, dan aturan tempatnya, logika murni
## (run fase5b-tembok-dekor bagian B2, D-5 dan D-6, AC-9 sampai AC-12; usulan).
##
## Dekor hanya hiasan di halaman dan tepi trotoar: tidak penghalang gerak, tidak masuk `Tabrakan`, `RintanganRute`, `MedanKoran`, zona, skor, atau
## penilaian lemparan. Satu-satunya hubungannya dengan permainan adalah kotak penutup dekor sisi `dekat` (pohon, lampu, tong sampah) (`PenutupPemain.dari_dekor`, semi-transparan bila
## menutupi pemain). Lateral, tapak kaki, dan sprite tiap jenis dari tabel `Config.RUTE_DEKOR_*` (sejajar `Config.RUTE_DEKOR_JENIS`); tinggi dan tapak kotak penutup per sprite
## (sejajar `Config.RUTE_DEKOR_SPRITE`): tinggi = tinggi sprite nyata, tapak lebih lebar dari tapak kaki supaya tajuk dan lengan lampu tercakup (run fase5b iterasi 2, P-6).
## Aturan tempat (dipakai `SegmenRute.parse`): di luar lajur sepeda, tidak menimpa zona teras atau kotak surat rumah mana pun, tapak rumah, atau tapak
## rintangan diam, dan dua dekor sesisi tidak lebih dekat dari `RUTE_DEKOR_JARAK_MIN_UBIN`. Koordinat jalan: x = lateral (negatif = `seberang`), y = maju.

## Folder sprite dekor (satu folder dengan properti lain).
const FOLDER: String = "res://assets/sprites/props"


## Indeks `jenis` di `Config.RUTE_DEKOR_JENIS`; -1 bila tidak dikenal.
static func indeks_jenis(jenis: String) -> int:
	return Config.RUTE_DEKOR_JENIS.find(jenis)


## Varian sah untuk `jenis` (kosong bila jenis tidak dikenal).
static func varian_sah(jenis: String) -> Array[String]:
	match jenis:
		"tong_sampah":
			return Config.RUTE_DEKOR_VARIAN_TONG_SAMPAH
		"pohon":
			return Config.RUTE_DEKOR_VARIAN_POHON
		"lampu_jalan":
			return Config.RUTE_DEKOR_VARIAN_LAMPU_JALAN
	var kosong: Array[String] = []
	return kosong


## Lateral pusat dekor `jenis` di `sisi` (negatif = `seberang`): `Config.RUTE_DEKOR_LATERAL_SEBERANG_UBIN` di seberang, `Config.RUTE_DEKOR_LATERAL_UBIN` di dekat; 0 bila jenis atau sisi tidak dikenal.
static func lateral(jenis: String, sisi: LoperAnim.Sisi) -> float:
	var i: int = indeks_jenis(jenis)
	if i < 0 or sisi == LoperAnim.Sisi.TIDAK_ADA:
		return 0.0
	if sisi == LoperAnim.Sisi.SEBERANG:
		return -Config.RUTE_DEKOR_LATERAL_SEBERANG_UBIN[i]
	return Config.RUTE_DEKOR_LATERAL_UBIN[i]


## Tapak kaki dekor `jenis` di `sisi` pada jarak maju `maju_ubin` (koordinat jalan, ubin); persegi kosong bila jenis atau sisi tidak dikenal.
static func tapak(jenis: String, sisi: LoperAnim.Sisi, maju_ubin: float) -> Rect2:
	var i: int = indeks_jenis(jenis)
	if i < 0 or sisi == LoperAnim.Sisi.TIDAK_ADA:
		return Rect2()
	var setengah: float = Config.RUTE_DEKOR_SETENGAH_UBIN[i]
	return Rect2(lateral(jenis, sisi) - setengah, maju_ubin - setengah, setengah + setengah, setengah + setengah)


## Indeks sprite dekor (jenis, varian, sisi) di `Config.RUTE_DEKOR_SPRITE`; -1 bila tidak dikenal. Tabel kotak penutup sejajar dengan daftar itu.
static func indeks_sprite(jenis: String, varian: String, sisi: LoperAnim.Sisi) -> int:
	return Config.RUTE_DEKOR_SPRITE.find(nama_sprite(jenis, varian, sisi))


## Tinggi kotak penutup dekor, ubin: tinggi sprite nyata (`Config.RUTE_DEKOR_TINGGI_PENUTUP_UBIN`, dari piksel opak di atas pijak). 0 bila tidak menutupi: sisi `seberang`
## (kamera melihat dari sisi dekat, dekor seberang tidak didaftarkan sebagai penutup) atau jenis/varian/sisi tidak dikenal. Tong sampah sisi `dekat` menutupi seperti pohon dan lampu (P-7).
static func tinggi_penutup(jenis: String, varian: String, sisi: LoperAnim.Sisi) -> float:
	var i: int = indeks_sprite(jenis, varian, sisi)
	if sisi != LoperAnim.Sisi.DEKAT or i < 0:
		return 0.0
	return Config.RUTE_DEKOR_TINGGI_PENUTUP_UBIN[i]


## Setengah sisi tapak kotak penutup dekor, ubin (`Config.RUTE_DEKOR_SETENGAH_PENUTUP_UBIN`); 0 bila tidak menutupi (lihat `tinggi_penutup`).
static func setengah_penutup(jenis: String, varian: String, sisi: LoperAnim.Sisi) -> float:
	var i: int = indeks_sprite(jenis, varian, sisi)
	if sisi != LoperAnim.Sisi.DEKAT or i < 0:
		return 0.0
	return Config.RUTE_DEKOR_SETENGAH_PENUTUP_UBIN[i]


## Tapak kotak penutup dekor di maju `maju_ubin` (koordinat jalan, ubin): persegi di sekitar pusat tapak kaki, lateral sama dengan `lateral`, setengah sisi `setengah_penutup`.
## Persegi kosong bila dekor tidak menutupi.
static func tapak_penutup(jenis: String, varian: String, sisi: LoperAnim.Sisi, maju_ubin: float) -> Rect2:
	var setengah: float = setengah_penutup(jenis, varian, sisi)
	if setengah <= 0.0:
		return Rect2()
	return Rect2(lateral(jenis, sisi) - setengah, maju_ubin - setengah, setengah + setengah, setengah + setengah)


## True bila dekor didaftarkan ke penerap penutup pemain (tingginya lebih dari nol): semua dekor (pohon, lampu, tong sampah) di sisi `dekat`, bukan sisi `seberang`.
static func menutupi(jenis: String, varian: String, sisi: LoperAnim.Sisi) -> bool:
	return tinggi_penutup(jenis, varian, sisi) > 0.0


## Nama sprite dekor: tong `prop_tong_sampah_<varian>`, pohon `prop_pohon_<varian>`, lampu `prop_lampu_<varian>_<seberang|dekat>` (lengan menghadap jalan).
## Kosong bila jenis atau sisi tidak dikenal.
static func nama_sprite(jenis: String, varian: String, sisi: LoperAnim.Sisi) -> String:
	match jenis:
		"tong_sampah":
			return "prop_tong_sampah_" + varian
		"pohon":
			return "prop_pohon_" + varian
		"lampu_jalan":
			if sisi == LoperAnim.Sisi.SEBERANG:
				return "prop_lampu_%s_seberang" % varian
			if sisi == LoperAnim.Sisi.DEKAT:
				return "prop_lampu_%s_dekat" % varian
	return ""


## Jalur PNG sprite dekor bernama `nama`.
static func jalur_png(nama: String) -> String:
	return "%s/%s.png" % [FOLDER, nama]


## Larik `[lebar sel, tinggi sel, frame, pijak x, pijak y]` sprite `nama`; kosong bila tidak dikenal.
static func data_sprite(nama: String) -> Array[int]:
	var hasil: Array[int] = []
	var i: int = Config.RUTE_DEKOR_SPRITE.find(nama)
	if i < 0:
		return hasil
	for k: int in range(Config.SPRITE_PANJANG):
		hasil.append(Config.RUTE_DEKOR_SPRITE_DATA[i * Config.SPRITE_PANJANG + k])
	return hasil


## Ukuran sel sprite `nama`, piksel; nol bila tidak dikenal.
static func sel(nama: String) -> Vector2i:
	var d: Array[int] = data_sprite(nama)
	return Vector2i(d[Config.SPRITE_INDEKS_LEBAR], d[Config.SPRITE_INDEKS_TINGGI]) if d.size() == Config.SPRITE_PANJANG else Vector2i.ZERO


## Titik pijak sprite `nama` di dalam sel, piksel; nol bila tidak dikenal.
static func pijak(nama: String) -> Vector2i:
	var d: Array[int] = data_sprite(nama)
	return Vector2i(d[Config.SPRITE_INDEKS_PIJAK_X], d[Config.SPRITE_INDEKS_PIJAK_Y]) if d.size() == Config.SPRITE_PANJANG else Vector2i.ZERO


## Titik pijak gambar dekor di dunia (ubin; y dunia = -maju): pusat tapak kaki.
static func titik_dunia(jenis: String, sisi: LoperAnim.Sisi, maju_ubin: float) -> Vector2:
	return Vector2(lateral(jenis, sisi), -maju_ubin)


# --- Aturan tempat (AC-9) ---

## True bila `tapak` menimpa lajur sepeda: persegi lajur `|lateral| < RUTE_DEKOR_LAJUR_UBIN` sepanjang jalan. Tepi yang hanya bersentuhan = false.
static func menimpa_lajur(tapak_dekor: Rect2) -> bool:
	return tapak_dekor.position.x < Config.RUTE_DEKOR_LAJUR_UBIN and tapak_dekor.end.x > -Config.RUTE_DEKOR_LAJUR_UBIN


## True bila `tapak` menimpa zona teras atau kotak surat rumah sisi `sisi_rumah` di awal kavling `pos_rumah` (relatif ke awal segmen yang sama; `ZonaSasaran.zona_rumah`).
static func menimpa_zona_rumah(tapak_dekor: Rect2, sisi_rumah: LoperAnim.Sisi, pos_rumah: float) -> bool:
	var rumah: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
	rumah.sisi = sisi_rumah
	rumah.maju_ubin = pos_rumah
	for zona: ZonaSasaran.Zona in ZonaSasaran.zona_rumah(rumah):
		if (zona.jenis == ZonaSasaran.Jenis.TERAS or zona.jenis == ZonaSasaran.Jenis.KOTAK_SURAT) and Tabrakan.bertumpuk(tapak_dekor, zona.persegi):
			return true
	return false


## True bila `tapak` menimpa tapak rumah (`PenutupPemain.tapak_rumah`, logika) sisi `sisi_rumah` di `pos_rumah`.
static func menimpa_tapak_rumah(tapak_dekor: Rect2, sisi_rumah: LoperAnim.Sisi, pos_rumah: float) -> bool:
	return Tabrakan.bertumpuk(tapak_dekor, PenutupPemain.tapak_rumah(sisi_rumah, pos_rumah))


## True bila `tapak` menimpa bentuk diam rintangan `jenis_objek` di `pos_objek` jalur `sisi_objek` (`SegmenRute.bentuk_rintangan_diam`: seluruh lintasan mobil, anjing di posisi diamnya).
static func menimpa_rintangan(tapak_dekor: Rect2, jenis_objek: String, pos_objek: float, sisi_objek: LoperAnim.Sisi) -> bool:
	return Tabrakan.bertumpuk(tapak_dekor, SegmenRute.bentuk_rintangan_diam(jenis_objek, pos_objek, sisi_objek))


## Rentang indeks `[awal, akhir)` pada `daftar` (urut maju menaik) untuk dekor yang `maju_ubin`-nya di antara `dari_maju_ubin` dan `sampai_maju_ubin`, kedua ujung inklusif
## (pencarian biner, pola `JendelaRute.rentang`). Masukan tidak hingga atau terbalik = `(0, 0)`.
static func rentang(daftar: Array[RouteBuilder.DekorItem], dari_maju_ubin: float, sampai_maju_ubin: float) -> Vector2i:
	if not is_finite(dari_maju_ubin) or not is_finite(sampai_maju_ubin) or dari_maju_ubin > sampai_maju_ubin:
		return Vector2i.ZERO
	var awal: int = _batas_bawah(daftar, dari_maju_ubin, false)
	var akhir: int = _batas_bawah(daftar, sampai_maju_ubin, true)
	return Vector2i(awal, maxi(akhir, awal))


## Rentang dekor di sekitar sepeda yang sudah menempuh `jarak_ubin`: jendela daur `Config.RUTE_DAUR_*`, sama dengan rumah.
static func rentang_sekitar(daftar: Array[RouteBuilder.DekorItem], jarak_ubin: float) -> Vector2i:
	if not is_finite(jarak_ubin):
		return Vector2i.ZERO
	return rentang(daftar, jarak_ubin - float(Config.RUTE_DAUR_MUNDUR_UBIN), jarak_ubin + float(Config.RUTE_DAUR_MAJU_UBIN))


static func _batas_bawah(daftar: Array[RouteBuilder.DekorItem], nilai: float, lewati_sama: bool) -> int:
	var rendah: int = 0
	var tinggi: int = daftar.size()
	while rendah < tinggi:
		var tengah: int = (rendah + tinggi) / 2
		var maju: float = daftar[tengah].maju_ubin
		var lanjut: bool = maju <= nilai if lewati_sama else maju < nilai
		if lanjut:
			rendah = tengah + 1
		else:
			tinggi = tengah
	return rendah
