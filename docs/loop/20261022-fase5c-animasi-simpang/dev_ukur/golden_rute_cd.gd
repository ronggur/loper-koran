extends SceneTree
## Golden AC-16 run 5C bagian CD: sidik FNV-1a uraian rute (rumah, rintangan, pelanggan, titik misi, dekor, tenggat, skor) untuk seed 20261016 + 7 i, i 0..59.
## Dijalankan di 7f30557 (sebelum simpang). Uraian sama dengan `TesSimpang._uraian`.
func _initialize() -> void:
	var pustaka: Array[SegmenRute] = PemuatRute.muat_folder("res://assets/data/routes/perumahan").segmen
	var keluar: Array[String] = []
	for i: int in range(60):
		var h: RouteBuilder.Hasil = RouteBuilder.bangun(20261016 + 7 * i, pustaka)
		keluar.append(str(_fnv(_uraian(h.rute))))
	print("GOLDEN: " + ", ".join(keluar))
	quit(0)

func _uraian(rute: RouteBuilder.Rute) -> String:
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
