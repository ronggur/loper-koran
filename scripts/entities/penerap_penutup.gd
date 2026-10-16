class_name PenerapPenutup
extends Node
## Satu-satunya penerap aturan penutup pemain di scene (AC-15 run fase3a-rute, usulan): menurunkan alfa gambar yang menutupi pemain.
##
## Aturan ada di `PenutupPemain` (satu tempat, murni); node ini hanya memegang daftar pasangan (gambar, kotak) dan memanggilnya tiap
## langkah dengan posisi dunia pemain. Gambar tidak punya logika penutup sendiri. Gambar yang tidak menutupi dikembalikan ke alfa 1,0
## (`PenutupPemain.alfa`, `Config.RUTE_PENUTUP_ALFA` saat menutupi). Pasangan didaftarkan saat gambar muncul (jendela daur) dan dilepas
## saat gambar dibuang.

## Gambar terdaftar, sejajar dengan `_objek`.
var _gambar: Array[CanvasItem] = []
## Kotak penutup tiap gambar.
var _objek: Array[PenutupPemain.Objek] = []
## Banyaknya gambar yang sedang menutupi pemain pada penerapan terakhir.
var _menutupi: int = 0


## Mendaftarkan `gambar` dengan kotak `objek` (gambar yang sudah terdaftar hanya diganti kotaknya).
func daftarkan(gambar: CanvasItem, objek: PenutupPemain.Objek) -> void:
	var indeks: int = _gambar.find(gambar)
	if indeks >= 0:
		_objek[indeks] = objek
		return
	_gambar.append(gambar)
	_objek.append(objek)


## Melepas `gambar` dan mengembalikan alfanya ke 1,0.
func lepas(gambar: CanvasItem) -> void:
	var indeks: int = _gambar.find(gambar)
	if indeks < 0:
		return
	if is_instance_valid(gambar):
		gambar.modulate.a = PenutupPemain.alfa(false)
	_gambar.remove_at(indeks)
	_objek.remove_at(indeks)


## Melepas semua gambar terdaftar (alfa dikembalikan ke 1,0).
func lepas_semua() -> void:
	for gambar: CanvasItem in _gambar:
		if is_instance_valid(gambar):
			gambar.modulate.a = PenutupPemain.alfa(false)
	_gambar.clear()
	_objek.clear()
	_menutupi = 0


## Menerapkan aturan untuk pemain di `posisi_pemain` (dunia, ubin): tiap gambar terdaftar diberi alfa `PenutupPemain.alfa`.
func terapkan(posisi_pemain: Vector2) -> void:
	_menutupi = 0
	for i: int in range(_gambar.size()):
		var gambar: CanvasItem = _gambar[i]
		if not is_instance_valid(gambar):
			continue
		var tutup: bool = PenutupPemain.menutupi(posisi_pemain, _objek[i])
		gambar.modulate.a = PenutupPemain.alfa(tutup)
		if tutup:
			_menutupi += 1


## Banyaknya gambar terdaftar.
func jumlah() -> int:
	return _gambar.size()


## Banyaknya gambar yang menutupi pemain pada penerapan terakhir.
func jumlah_menutupi() -> int:
	return _menutupi
