class_name TesMisiAlur
extends RefCounted
## Tes alur penuh run fase4b-misi-kucing (AC-10, AC-11, AC-14, AC-16, AC-17, AC-18): `scenes/hari/hari.tscn` sungguhan dengan `SaveManager` jalur sementara
## (`user://tes_save_4a_alur/`; TIDAK PERNAH menyentuh `user://save.json`, dicek sebelum dan sesudah). Tombol ditekan lewat `ditekan.emit()`; langkah rute
## nyata `RuteMain.perbarui`, posisi sepeda diatur pembantu tes (`TesAlurHari`, dipakai ulang lewat komposisi). Tiga skenario: A ambil lalu selesai, B ambil lalu
## gagal, C lewati. Angka harapan literal tes: rute 100 koin tidak diisi (skor rute diisi `TesAlurHari._selesaikan_rute`: koin 120 termasuk tip 25, skor 1500).

var _cek: Callable
var _judul: Callable
var _tree: SceneTree
var _a: TesAlurHari = null


func _init(cek: Callable, judul: Callable, tree: SceneTree) -> void:
	_cek = cek
	_judul = judul
	_tree = tree
	_a = TesAlurHari.new(cek, judul, tree)


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	var sebelum: Dictionary = _a._jejak_save_asli()
	await _test_skenario_a_selesai()
	await _test_skenario_b_gagal()
	await _test_skenario_c_lewati()
	await _test_simpan_hanya_akhir_hari_dengan_misi()
	await _test_tutup_di_tengah_rute_dengan_misi()
	await _test_tutorial_sekali()
	var sesudah: Dictionary = _a._jejak_save_asli()
	check(sebelum == sesudah, "user://save.json tidak tersentuh oleh tes alur misi (%s -> %s)" % [sebelum, sesudah])


func _hari_berikutnya(rute: RuteMain) -> void:
	rute.layar_hasil().tombol_main_lagi().ditekan.emit()
	await _tree.process_frame


func _test_skenario_a_selesai() -> void:
	_judul.call("Alur A: Ambil -> Berangkat -> misi aktif -> kucing ketemu -> banner -> hasil dengan rekap -> Hari berikutnya -> koran hari 2 'Sudah Pulang' (AC-17)")
	_a._bersihkan_folder()
	var m: Node = _a._manajer()
	var hari: HariMain = await _a._siapkan(m)
	hari.koran().tombol_ambil().ditekan.emit()
	var rute: RuteMain = await _a._berangkat(hari)
	check(rute.misi() != null and rute.misi().id == "p1_kucing" and rute.keadaan_misi() != null and rute.hud_rute().kartu_tampil(), "Ambil lalu Berangkat: misi P1 aktif di rute dengan kartu HUD (AC-11)")
	check(rute.hud_rute().teks_kartu() == "Kucing 0/1 · 12 rumah" and rute.tutorial_node().tampil() and rute.tutorial_node().teks_langkah() == "PETUNJUK 1/4", "kartu 'Kucing 0/1 · 12 rumah' dan tutorial langkah 1/4 di hari 1")
	check(rute.benih() == SeedHari.rute(1) and rute.rencana_misi().id_misi == "p1_kucing" and rute.rencana_misi().sah(), "seed rute hari 1 dan rencana misi dari benih hari")
	_a._selesaikan_misi(rute)
	check(rute.keadaan_misi().status == MissionManager.Status.SELESAI and rute.hud_rute().teks_banner() == "Kucing ketemu! +75", "kucing ketemu: banner 'Kucing ketemu! +75'")
	var koin_hud: String = rute.hud_rute().teks_koin()
	await _a._selesaikan_rute(rute)
	var angka: HasilRute.Angka = rute.angka_hasil()
	check(angka != null and angka.koin == 195 and angka.koin_misi == 75 and angka.misi_hasil == "selesai" and koin_hud == "75", "koin HUD sebelum antaran (75) dan Angka hasil (195 = 120 + 75) konsisten (AC-14)")
	check(rute.layar_hasil().teks_rekap_misi() == "Misi: Kucing ketemu! +75 koin" and rute.layar_hasil().teks_tombol() == "Hari berikutnya" and rute.layar_hasil().rect_tombol().size.y >= 42.0, "layar hasil: rekap misi dan tombol 'Hari berikutnya' >= 42 px (AC-16)")
	check(m.get(&"jumlah_simpan") == 0, "sampai layar hasil terbuka: nol simpan (AC-10)")
	rute.layar_hasil().tombol_main_lagi().ditekan.emit()
	rute.layar_hasil().tombol_main_lagi().ditekan.emit()
	await _tree.process_frame
	check(m.get(&"jumlah_simpan") == 1 and hari.status().hari == 2, "'Hari berikutnya' (dua ketukan): tepat satu simpan, hari 2")
	var s: Dictionary = _a._baca_save()
	check(s["koin"] == 195 and s["tip_total"] == 25 and s["flag"] == ["kucing_ketemu"] and s["misi_hasil"] == {"p1_kucing": {"hasil": "selesai", "hari": 1}} and s["terakhir"]["koin_misi"] == 75, "isi save sesuai oracle: koin 195, tip 25, flag kucing_ketemu, misi_hasil selesai, koin_misi 75")
	check(hari.halaman().ringan.id == "lanjutan_kucing_ketemu" and hari.koran().teks_tampil()[5] == "Kucing Bu Ratmi Sudah Pulang ke Rumah", "koran hari 2 menampilkan 'Kucing Bu Ratmi Sudah Pulang ke Rumah'")
	var rute2: RuteMain = await _a._berangkat(hari)
	check(rute2.misi() == null and rute2.keadaan_misi() == null and not rute2.hud_rute().kartu_tampil(), "hari 2: tanpa misi (P1 masih jeda), rute tanpa kucing")
	check(rute2.keadaan_tutorial() == null and not rute2.tutorial_node().tampil(), "hari 2: tutorial tidak muncul lagi (tutorial.selesai true di save)")
	await _a._selesaikan_rute(rute2)
	await _hari_berikutnya(rute2)
	var s2: Dictionary = _a._baca_save()
	check(s2["flag"] == [] and hari.status().hari == 3 and hari.halaman().ringan.id != "lanjutan_kucing_ketemu", "hari 2 selesai: flag dikonsumsi, hari 3 tanpa lanjutan lagi")
	check(hari.jumlah_rute_dibuat == 2, "dua rute dibuat untuk dua hari (Berangkat ganda tidak menggandakan)")
	_a._bersihkan(hari)
	_a._tutup_manajer(m)
	_a._bersihkan_folder()


func _test_skenario_b_gagal() -> void:
	_judul.call("Alur B: Ambil -> gagal -> hasil 'Kucingnya lolos hari ini' -> hari 2 'Belum Ditemukan' sekali (tanpa tombol) -> hari 3 tanpa lanjutan (AC-17, K-4)")
	_a._bersihkan_folder()
	var m: Node = _a._manajer()
	var hari: HariMain = await _a._siapkan(m)
	hari.koran().tombol_ambil().ditekan.emit()
	var rute: RuteMain = await _a._berangkat(hari)
	await _a._selesaikan_rute(rute)
	var angka: HasilRute.Angka = rute.angka_hasil()
	check(angka.misi_hasil == "gagal" and angka.koin_misi == 0 and angka.koin == 120 and rute.layar_hasil().teks_rekap_misi() == "Misi: Kucingnya lolos hari ini", "misi gagal: koin 120 (tidak berkurang, tanpa hadiah), rekap 'Misi: Kucingnya lolos hari ini'")
	await _hari_berikutnya(rute)
	var s: Dictionary = _a._baca_save()
	check(s["koin"] == 120 and s["flag"] == ["kucing_belum"] and s["misi_hasil"] == {"p1_kucing": {"hasil": "gagal", "hari": 1}} and s["terakhir"]["misi_hasil"] == "gagal", "save: koin 120, flag kucing_belum, misi_hasil gagal")
	check(hari.halaman().misi != null and hari.halaman().misi.id == "lanjutan_kucing_belum" and hari.koran().teks_tampil()[8] == "Kucing Bu Ratmi Belum Ditemukan" and not hari.koran().ada_misi(), "hari 2: 'Kucing Bu Ratmi Belum Ditemukan' di baris misi tanpa tombol Ambil/Lewati")
	var rute2: RuteMain = await _a._berangkat(hari)
	check(rute2.misi() == null and rute2.keadaan_misi() == null, "hari 2: lanjutan tanpa misi (misi_ditunda): rute tanpa kucing")
	await _a._selesaikan_rute(rute2)
	await _hari_berikutnya(rute2)
	check(_a._baca_save()["flag"] == [] and (hari.halaman().misi == null or hari.halaman().misi.id != "lanjutan_kucing_belum") and hari.status().hari == 3, "hari 3: lanjutan tidak tampil lagi, flag sudah dikonsumsi")
	_a._bersihkan(hari)
	_a._tutup_manajer(m)
	_a._bersihkan_folder()


func _test_skenario_c_lewati() -> void:
	_judul.call("Alur C: Lewati (atau Berangkat tanpa memilih) -> rute tanpa kucing, tanpa kartu, tanpa baris rekap, tanpa flag (AC-11, AC-17)")
	for cara: String in ["lewati", "tanpa_memilih"]:
		_a._bersihkan_folder()
		var m: Node = _a._manajer()
		var hari: HariMain = await _a._siapkan(m)
		if cara == "lewati":
			hari.koran().tombol_lewati().ditekan.emit()
		var rute: RuteMain = await _a._berangkat(hari)
		check(rute.misi() == null and rute.keadaan_misi() == null and not rute.hud_rute().kartu_tampil() and not rute.kucing().tampil() and hari.misi_diambil() == "", "%s: tanpa misi di rute: tanpa kartu dan tanpa kucing" % cara)
		_a._taruh(rute.find_child("Sepeda", true, false) as SepedaUji, 20.0, 0.5)
		await _a._selesaikan_rute(rute)
		check(rute.angka_hasil().misi_id == "" and rute.angka_hasil().koin_misi == 0 and rute.layar_hasil().teks_rekap_misi() == "" and rute.angka_hasil().koin == 120, "%s: layar hasil tanpa baris rekap dan tanpa koin misi" % cara)
		await _hari_berikutnya(rute)
		var s: Dictionary = _a._baca_save()
		check(s["flag"] == [] and s["misi_hasil"] == {} and s["terakhir"]["misi_hasil"] == "" and s["terakhir"]["koin_misi"] == 0 and s["misi_jeda"] == {} and s["koin"] == 120, "%s: save tanpa flag, tanpa misi_hasil, tanpa jeda misi; koin 120" % cara)
		_a._bersihkan(hari)
		_a._tutup_manajer(m)
	_a._bersihkan_folder()


func _test_simpan_hanya_akhir_hari_dengan_misi() -> void:
	_judul.call("Simpan hanya di akhir hari: misi selesai, banner, petunjuk, dan tutorial tidak menyimpan (AC-10)")
	_a._bersihkan_folder()
	var m: Node = _a._manajer()
	var hari: HariMain = await _a._siapkan(m)
	hari.koran().tombol_ambil().ditekan.emit()
	var rute: RuteMain = await _a._berangkat(hari)
	_a._selesaikan_misi(rute)
	rute.tutorial_node().tombol_lewati().ditekan.emit()
	rute.perbarui(0.5)
	check(m.get(&"jumlah_simpan") == 0 and not FileAccess.file_exists(_a._jalur()), "misi selesai, banner, dan tutorial dilewati: nol simpan, tidak ada berkas")
	await _a._selesaikan_rute(rute)
	check(m.get(&"jumlah_simpan") == 0 and not FileAccess.file_exists(_a._jalur()), "layar hasil terbuka dengan rekap: tetap nol simpan")
	await _hari_berikutnya(rute)
	check(m.get(&"jumlah_simpan") == 1 and _a._baca_save()["tutorial"] == {"selesai": true}, "tepat satu simpan di 'Hari berikutnya'; tutorial.selesai ditulis di sana")
	_a._bersihkan(hari)
	_a._tutup_manajer(m)
	_a._bersihkan_folder()


func _test_tutup_di_tengah_rute_dengan_misi() -> void:
	_judul.call("App ditutup di tengah rute (misi aktif atau sudah selesai belum disimpan): tidak ada tulis, buka lagi = hari sama, misi dari awal (AC-10)")
	_a._bersihkan_folder()
	var m: Node = _a._manajer()
	var hari: HariMain = await _a._siapkan(m)
	hari.koran().tombol_ambil().ditekan.emit()
	var rute: RuteMain = await _a._berangkat(hari)
	_a._selesaikan_misi(rute)
	check(rute.keadaan_misi().status == MissionManager.Status.SELESAI, "misi selesai di memori, belum disimpan")
	_a._bersihkan(hari)
	_a._tutup_manajer(m)
	check(not FileAccess.file_exists(_a._jalur()), "scene dibuang di tengah rute: tidak ada berkas save")
	var m2: Node = _a._manajer()
	var hari2: HariMain = await _a._siapkan(m2)
	check(hari2.status().hari == 1 and hari2.halaman().misi != null and hari2.halaman().misi.id == "p1_kucing", "buka lagi: hari 1 yang sama dengan misi P1 ditawarkan lagi")
	hari2.koran().tombol_ambil().ditekan.emit()
	var rute2: RuteMain = await _a._berangkat(hari2)
	check(rute2.keadaan_misi().status == MissionManager.Status.AKTIF and rute2.keadaan_misi().langkah == 0 and rute2.rencana_misi().titik[0].maju_ubin == rute.rencana_misi().titik[0].maju_ubin, "misi diulang dari awal dengan rencana yang sama (seed hari sama)")
	check(m2.get(&"jumlah_simpan") == 0, "tetap nol simpan")
	_a._bersihkan(hari2)
	_a._tutup_manajer(m2)
	_a._bersihkan_folder()


func _test_tutorial_sekali() -> void:
	_judul.call("Tutorial: hanya hari 1 dan hanya bila belum selesai; save dengan tutorial.selesai true tidak memunculkannya (AC-18)")
	_a._bersihkan_folder()
	var s: Dictionary = DataSave.templat()
	s["tutorial"] = {"selesai": true}
	_a._tulis_save(DataSave.ke_teks(s))
	var m: Node = _a._manajer()
	var hari: HariMain = await _a._siapkan(m)
	var rute: RuteMain = await _a._berangkat(hari)
	check(rute.keadaan_tutorial() == null and not rute.tutorial_node().tampil(), "hari 1 dengan tutorial.selesai true: tidak ada tutorial")
	_a._bersihkan(hari)
	_a._tutup_manajer(m)
	_a._bersihkan_folder()
	# Hari 2 dengan tutorial.selesai false (save buatan): tidak ada tutorial karena bukan hari pertama.
	var s2: Dictionary = DataSave.templat()
	s2["hari"] = 2
	_a._tulis_save(DataSave.ke_teks(s2))
	var m2: Node = _a._manajer()
	var hari2: HariMain = await _a._siapkan(m2)
	var rute2: RuteMain = await _a._berangkat(hari2)
	check(rute2.keadaan_tutorial() == null and not rute2.tutorial_node().tampil(), "hari 2 walau tutorial.selesai false: tidak ada tutorial (hanya hari 1)")
	_a._bersihkan(hari2)
	_a._tutup_manajer(m2)
	_a._bersihkan_folder()
	check(TutorialLangkah.boleh_aktif(1, false) and not TutorialLangkah.boleh_aktif(2, false) and not TutorialLangkah.boleh_aktif(1, true) and not TutorialLangkah.boleh_aktif(0, false), "boleh_aktif: hanya hari 1 dan belum selesai")
