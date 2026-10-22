extends SceneTree
## Putusan P-6 run 5C: banding rute sebelum dan sesudah rumah seberang per_buka_02@18 dihapus (berkas lama dari argumen), dan golden baru dihitung dari kode.
## Pakai: godot --headless --script docs/loop/20261022-fase5c-animasi-simpang/dev_ukur/banding_p6.gd -- <per_buka_02 lama.json>
func _initialize() -> void:
	var lama_teks: String = FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0])
	var baru: Array[SegmenRute] = PemuatRute.muat_folder().segmen
	var lama: Array[SegmenRute] = []
	for s: SegmenRute in baru:
		lama.append(PemuatRute.parse_teks(lama_teks, "lama").segmen if s.id == "per_buka_02" else s)
	var g_simpang: Array[String] = []
	var g_dekor: Array[String] = []
	var berubah: int = 0
	var lain: int = 0
	for i: int in range(60):
		var a: RouteBuilder.Rute = RouteBuilder.bangun(20261016 + 7 * i, lama).rute
		var b: RouteBuilder.Rute = RouteBuilder.bangun(20261016 + 7 * i, baru).rute
		var la: PackedStringArray = _uraian(a, true).split("\n")
		var lb: PackedStringArray = _uraian(b, true).split("\n")
		var hilang: Array[String] = []
		var tambah: Array[String] = []
		for x: String in la:
			if not lb.has(x):
				hilang.append(x)
		for x: String in lb:
			if not la.has(x):
				tambah.append(x)
		if not hilang.is_empty() or not tambah.is_empty():
			berubah += 1
			var hanya: bool = tambah.is_empty() and hilang.size() == 1 and hilang[0].begins_with("R|per_buka_02@18|")
			if not hanya:
				lain += 1
				print("seed ke-%d BEDA LAIN: hilang %s tambah %s" % [i, hilang, tambah])
		g_simpang.append(str(_fnv(_uraian(b, true))))
		g_dekor.append(str(_fnv(_uraian(b, false))))
	print("60 seed dev: %d berubah, %d dengan perbedaan selain baris rumah per_buka_02@18" % [berubah, lain])
	print("GOLDEN_SIMPANG: " + ", ".join(g_simpang))
	print("GOLDEN_DEKOR: " + ", ".join(g_dekor))
	# Rencana kucing 600 hari dan rute hari 600: pelanggan, tip, rintangan, titik, dekor, tenggat, skor sama; rencana kucing yang berubah dihitung.
	var misi: DataMisi = PemuatMisi.muat_folder().cari("p1_kucing")
	var hari_rute: int = 0
	var hari_beda_lain: int = 0
	var rencana_beda: int = 0
	var contoh: String = ""
	for hari: int in range(1, 601):
		var a2: RouteBuilder.Rute = RouteBuilder.bangun(SeedHari.rute(hari), lama).rute
		var b2: RouteBuilder.Rute = RouteBuilder.bangun(SeedHari.rute(hari), baru).rute
		var la2: PackedStringArray = _uraian(a2, true).split("\n")
		var lb2: PackedStringArray = _uraian(b2, true).split("\n")
		if la2 != lb2:
			hari_rute += 1
			var sisa: Array[String] = []
			for x: String in la2:
				if not lb2.has(x) and not x.begins_with("R|per_buka_02@18|"):
					sisa.append(x)
			if not sisa.is_empty() or lb2.size() != la2.size() - 1:
				hari_beda_lain += 1
		var ra: RencanaMisi.Rencana = RencanaMisi.buat(misi, a2, SeedHari.misi(hari))
		var rb: RencanaMisi.Rencana = RencanaMisi.buat(misi, b2, SeedHari.misi(hari))
		var ta: String = ""
		var tb: String = ""
		for t: RencanaMisi.Titik in ra.titik:
			ta += "%s@%s/%s;" % [t.id_rumah, t.maju_ubin, t.lateral_ubin]
		for t: RencanaMisi.Titik in rb.titik:
			tb += "%s@%s/%s;" % [t.id_rumah, t.maju_ubin, t.lateral_ubin]
		if ta != tb:
			rencana_beda += 1
			if contoh.is_empty():
				contoh = "hari %d: %s -> %s" % [hari, ta, tb]
	print("600 hari: %d rute berubah, %d dengan perbedaan selain rumah per_buka_02@18; rencana kucing berubah %d hari (%s)" % [hari_rute, hari_beda_lain, rencana_beda, contoh])
	var total: int = 0
	var seb: int = 0
	var per: Array[String] = []
	for s: SegmenRute in baru:
		var n: int = 0
		for r: SegmenRute.Rumah in s.rumah:
			total += 1
			if r.sisi == LoperAnim.Sisi.SEBERANG:
				seb += 1
				n += 1
		per.append("%s %d" % [s.id, n])
	print("rumah: total %d, seberang %d, per segmen seberang %s" % [total, seb, per])
	quit(0)

func _uraian(rute: RouteBuilder.Rute, dekor: bool) -> String:
	var bagian: Array[String] = []
	bagian.append("benih=%d;panjang=%s;koran=%d;tenggat=%s" % [rute.benih, str(rute.panjang_ubin), rute.koran_awal, str(TenggatRute.awal(rute.panjang_ubin).tenggat_detik)])
	var ids: Array[String] = []
	for s: SegmenRute in rute.segmen:
		ids.append(s.id)
	bagian.append("segmen=" + ",".join(ids))
	for r: RouteBuilder.RumahRute in rute.rumah:
		bagian.append("R|%s|%s|%d|%s|%s|%s|%s" % [r.id, str(r.maju_ubin), r.sisi, r.jenis, r.pelanggan, r.pelanggan_boleh, r.pemberi_tip])
	for o: RouteBuilder.ObjekRute in rute.objek:
		bagian.append("O|%s|%s|%s|%s|%s" % [o.jenis, o.id_segmen, str(o.maju_ubin), o.jalur, str(o.tanda_ubin)])
	for p: RouteBuilder.RumahRute in rute.pelanggan:
		bagian.append("P|" + p.id)
	for t: RouteBuilder.TitikMisiRute in rute.titik_misi:
		bagian.append("T|%s|%s|%s|%d" % [t.nama, t.id_segmen, str(t.maju_ubin), t.sisi])
	if dekor:
		for d: RouteBuilder.DekorItem in rute.dekor:
			bagian.append("D|%s|%s|%s|%s|%d|%s|%s" % [d.id, d.id_segmen, str(d.maju_ubin), str(d.lateral_ubin), d.sisi, d.jenis, d.varian])
	var k: SkorRute.Keadaan = SkorRute.awal()
	var i: int = 0
	for p: RouteBuilder.RumahRute in rute.pelanggan:
		var hasil: ZonaSasaran.Hasil = ZonaSasaran.Hasil.KOTAK_SURAT if i % 2 == 0 else ZonaSasaran.Hasil.TERAS
		var kecepatan: float = 3.0 if i % 3 != 0 else 5.0
		k = SkorRute.nilai(k, hasil, p.id, i % 3 == 0, kecepatan, RouteBuilder.pemberi_tip(rute, p.id), false).keadaan
		i += 1
	bagian.append("skor=%d;koin=%d;tip=%d;tepat=%d;antar=%d" % [k.skor, k.koin, k.jumlah_tip, k.jumlah_tepat, k.jumlah_antar])
	return "\n".join(bagian)

func _fnv(teks: String) -> int:
	var nilai: int = 2166136261
	for b: int in teks.to_utf8_buffer():
		nilai = nilai ^ b
		nilai = (nilai * 16777619) & 4294967295
	return nilai
