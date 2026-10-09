class_name LemparWaktu
extends RefCounted
## Garis waktu animasi lempar koran: satu kali putar, tidak berulang. Logika murni tanpa node (README sprite lempar).
##
## Animasi lempar punya `jumlah_frame` frame berdurasi sama, `1 / fps` detik per frame (4 frame, 12 fps, sekitar 0,33 detik).
## Waktu dan `dt` selalu parameter (rule `gdscript`): node `LoperSprite` hanya menyimpan waktu yang sudah berjalan dan memanggil
## `langkah` tiap frame, jadi tes bisa memajukan animasi dengan `dt` tetap tanpa menunggu waktu nyata.
## Frame ke-`frame_lepas` (indeks 2, `Config.LEMPAR_FRAME_LEPAS`) adalah saat koran lepas: `lepas` bernilai true tepat sekali, pada
## langkah yang pertama kali menampilkannya, walau satu `dt` besar melompati beberapa frame. Frame 0 sudah tampil saat lempar
## dimulai, jadi `frame_lepas` yang berlaku paling kecil 1.


## Hasil satu langkah.
class Langkah extends RefCounted:
	## Waktu sejak lempar dimulai sesudah langkah ini, detik, dijepit ke durasi total.
	var waktu: float = 0.0
	## Indeks frame yang tampil sesudah langkah ini (0 sampai jumlah_frame - 1).
	var frame: int = 0
	## Bagian frame yang sudah lewat (0 sampai 1); 1 bila animasi selesai.
	var progres: float = 0.0
	## True bila frame lepas baru pertama kali tampil pada langkah ini.
	var lepas: bool = false
	## True bila seluruh frame sudah habis pada langkah ini.
	var selesai: bool = false


## Durasi total animasi, detik. `fps` atau `jumlah_frame` tidak sah (nol, negatif, NaN) = 0.
static func durasi(fps: float, jumlah_frame: int) -> float:
	if not _sah(fps, jumlah_frame):
		return 0.0
	return float(jumlah_frame) / fps


## Indeks frame yang tampil pada `waktu` detik sejak mulai, dijepit ke frame pertama dan terakhir.
## Waktu negatif atau bukan bilangan hingga dianggap 0.
static func frame_di(waktu: float, fps: float, jumlah_frame: int) -> int:
	if not _sah(fps, jumlah_frame):
		return 0
	return _indeks(_posisi_frame(waktu, fps), jumlah_frame)


## Satu langkah selama `dt` detik dari keadaan `waktu` (detik sejak mulai).
## `dt` negatif, nol, NaN, atau tak hingga tidak memajukan waktu. `fps` atau `jumlah_frame` yang tidak sah dianggap animasi
## tanpa isi: langsung `selesai` tanpa `lepas`, supaya node tidak menggantung selamanya.
static func langkah(waktu: float, dt: float, fps: float, jumlah_frame: int, frame_lepas: int) -> Langkah:
	var hasil: Langkah = Langkah.new()
	if not _sah(fps, jumlah_frame):
		hasil.selesai = true
		hasil.progres = 1.0
		return hasil
	var lama: float = _bersih(waktu)
	var baru: float = lama + _bersih(dt)
	var total: float = durasi(fps, jumlah_frame)
	var batas_lepas: int = maxi(frame_lepas, 1)
	var frame_lama: int = frame_di(lama, fps, jumlah_frame)
	var posisi_baru: float = _posisi_frame(baru, fps)
	hasil.selesai = posisi_baru >= float(jumlah_frame)
	hasil.waktu = minf(baru, total) if hasil.selesai else baru
	hasil.frame = _indeks(posisi_baru, jumlah_frame)
	hasil.progres = 1.0 if hasil.selesai else clampf(posisi_baru - floorf(posisi_baru), 0.0, 1.0)
	hasil.lepas = frame_lama < batas_lepas and hasil.frame >= batas_lepas
	return hasil


## Posisi dalam satuan frame (frame ke-n mulai di n.0), dengan toleransi derau float.
static func _posisi_frame(waktu: float, fps: float) -> float:
	return (_bersih(waktu) + Config.LEMPAR_TOLERANSI_DETIK) * fps


## Indeks frame dari posisi dalam satuan frame, dijepit SEBELUM diubah ke int (waktu sangat besar tidak membalik hasil).
static func _indeks(posisi: float, jumlah_frame: int) -> int:
	return int(clampf(floorf(posisi), 0.0, float(jumlah_frame - 1)))


static func _bersih(nilai: float) -> float:
	return nilai if is_finite(nilai) and nilai > 0.0 else 0.0


static func _sah(fps: float, jumlah_frame: int) -> bool:
	return is_finite(fps) and fps > 0.0 and jumlah_frame > 0
