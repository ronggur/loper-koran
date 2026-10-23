class_name KotakKondisiBesar
extends Control
## Kotak kondisi BESAR satu komponen sepeda (kartu servis bengkel; AC-5 run ui1-komponen-bengkel bagian A, usulan): tiga kotak 8x8 berjarak 2 dan tanda "!" 3x9 untuk PERLU_BENGKEL
## (`TampilKondisiBesar`). Terisi = kotak terang bergaris gelap, berongga (AUS atau hilang) = lubang gelap bergaris terang, terisi `WARN` saat PERLU_BENGKEL atau peringatan. Ikon komponen TIDAK
## digambar di sini (bengkel memakai ikon 24 sendiri). Hanya menggambar; tidak menerima sentuhan. `KotakKondisi` 14 px untuk HUD rute tidak diubah.

var _kondisi: float = 1.0
var _kedip: bool = false
## Kunci gambar terakhir: gambar ulang hanya bila berubah (tanpa alokasi per frame).
var _kunci: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(TampilKondisiBesar.ukuran())


## Menampilkan kondisi `kondisi` (0..1); `kedip` true selama peringatan (kotak terisi berwarna WARN). Gambar ulang hanya bila tampilannya berubah.
func tampilkan(kondisi: float, kedip: bool = false) -> void:
	_kondisi = BikeCondition.jepit(kondisi)
	_kedip = kedip
	var kunci: Array = [TampilKondisi.kotak(_kondisi, _kedip), TampilKondisi.tanda_seru(_kondisi)]
	if kunci == _kunci:
		return
	_kunci = kunci
	queue_redraw()


## Isi tiga kotak yang tampil (untuk tes).
func kotak_tampil() -> Array[TampilKondisi.Kotak]:
	return TampilKondisi.kotak(_kondisi, _kedip)


## True bila tanda "!" tampil (untuk tes).
func seru_tampil() -> bool:
	return TampilKondisi.tanda_seru(_kondisi)


func _draw() -> void:
	for b: TampilKondisiBesar.BidangKotak in TampilKondisiBesar.bidang(_kondisi, _kedip):
		draw_rect(Rect2(b.rect), b.garis)
		draw_rect(Rect2(b.rect).grow(-1), b.isi)
	if seru_tampil():
		var posisi: Vector2i = TampilKondisiBesar.posisi_seru()
		GambarPiksel.pola(self, PolaPiksel.TANDA_SERU_KONDISI, Vector2(posisi), Palette.WARN)
