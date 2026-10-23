extends SceneTree
## TES REPRODUKSI QA (run 20261023-ui1-komponen-bengkel, iterasi 1, temuan QA-001) — SENGAJA GAGAL sampai Dev memperbaiki; TIDAK terdaftar di `run_tests.gd`.
## Membuktikan: nama upgrade yang masih SAH menurut `DataToko` (nama <= `Config.TOKO_NAMA_PANJANG_MAKS` 24 huruf) merusak tata letak bengkel di lebar game 640 (1920x1080): `Isi` melebihi lebar
## viewport dan digeser keluar layar (x < 0 atau sisi kanan > 640). Label nama kartu upgrade tidak punya autowrap atau ellipsis, jadi lebar minimum kartu naik dan `Batas` ikut membesar
## (SPEC AC-6: "Teks panjang pakai autowrap/ellipsis"). Kasus ke-3 (deskripsi 48 huruf biasa) adalah kontrol dan harus lolos. Satu layar pemanasan dibuat dulu: pada instansiasi pertama di
## proses headless ukuran viewport awal belum benar (tinggi `Isi` 616), itu artefak skrip dan bukan temuan.
## Jalankan: godot --headless --path . --script res://tests/qa_repro_ui1_teks_panjang.gd   (exit 1 = bug masih ada)

const BERKAS: String = "res://scenes/bengkel/bengkel.tscn"
const KASUS: Array = [
	# [nama, deskripsi, label]
	["Ban Anti-Selip Super", "Belok lebih lincah (+15%)", "nama 20 huruf (sah, <= 24)"],
	["Rem Pakem Racing Edition", "Berhenti lebih cepat (+20%)", "nama 24 huruf (batas)"],
	["Rem Pakem", "Belok lebih lincah dan tahan di jalan licin kota", "kontrol: deskripsi 48 huruf (harus lolos)"],
]
var _gagal: int = 0


func _state() -> Dictionary:
	var s: Dictionary = DataSave.templat()
	s["koin"] = 5000
	s["koin_total"] = 5000
	var sepeda: Dictionary = s["sepeda"]
	var daftar: Array = [0.1, 0.2, 0.3]
	for i: int in range(3):
		(sepeda[Config.KONDISI_KOMPONEN[i]] as Dictionary)["kondisi"] = daftar[i]
	return s


func _initialize() -> void:
	root.size = Vector2i(1920, 1080)
	var pemanasan: LayarBengkel = (load(BERKAS) as PackedScene).instantiate() as LayarBengkel
	root.add_child(pemanasan)
	await process_frame
	pemanasan.isi(_state(), PemuatToko.muat())
	for i: int in range(4):
		await process_frame
	root.remove_child(pemanasan)
	pemanasan.free()
	for kasus: Array in KASUS:
		var toko: PemuatToko.Kumpulan = PemuatToko.muat()
		for u: DataToko in toko.upgrade:
			u.nama = kasus[0]
			u.deskripsi = kasus[1]
		root.size = Vector2i(1920, 1080)
		var layar: LayarBengkel = (load(BERKAS) as PackedScene).instantiate() as LayarBengkel
		root.add_child(layar)
		await process_frame
		layar.isi(_state(), toko)
		for i: int in range(4):
			await process_frame
		var isi: Rect2 = layar.rect_isi()
		var lebar_game: float = 640.0
		var muat: bool = isi.position.x >= 0.0 and isi.end.x <= lebar_game and isi.end.y <= 360.0
		var timpa: bool = false
		for k: Rect2 in layar.rect_kartu():
			if k.intersects(layar.rect_tombol_hari()):
				timpa = true
		print("%s: isi=%s muat_di_viewport=%s kartu_menimpa_tombol_hari=%s" % [kasus[2], isi, muat, timpa])
		if not muat or timpa:
			_gagal += 1
		root.remove_child(layar)
		layar.free()
	print("QA-001 repro: %d kasus gagal (harus 0 setelah perbaikan)" % _gagal)
	quit(1 if _gagal > 0 else 0)
