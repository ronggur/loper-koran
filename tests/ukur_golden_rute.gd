extends SceneTree
## Pembangkit golden rute `main` (run fase6a2-reputasi-pelanggan, AC-4): menghitung sidik FNV-1a identitas rute untuk 60 seed x hari 1..5 dengan `RouteBuilder.bangun` TANPA keadaan pelanggan
## dan menulis `tests/data/golden_rute_main.json`. Dijalankan SEKALI pada commit yang `scripts/systems/route_builder.gd`-nya identik dengan `main` (blob dicatat di berkas); bukan angka tulisan tangan.
##   godot --headless --script res://tests/ukur_golden_rute.gd
## `TesRutePelanggan` membandingkan rute `bangun` (tanpa keadaan, dan hari 1-2 dengan keadaan) dengan berkas ini.

const KELUARAN: String = "res://tests/data/golden_rute_main.json"
const SEED_AWAL: int = 20261016
const SEED_LANGKAH: int = 7
const JUMLAH_SEED: int = 60
const HARI_MAKS: int = 5


static func fnv(teks: String) -> int:
	var nilai: int = 2166136261
	for b: int in teks.to_utf8_buffer():
		nilai = nilai ^ b
		nilai = (nilai * 16777619) & 4294967295
	return nilai


## Identitas rute (bilangan bulat dan teks saja).
static func identitas(rute: RouteBuilder.Rute) -> String:
	var bagian: Array[String] = []
	bagian.append("panjang=%d;koran=%d;tenggat=%d" % [int(rute.panjang_ubin), rute.koran_awal, int(TenggatRute.awal(rute.panjang_ubin).tenggat_detik)])
	var ids: Array[String] = []
	for s: SegmenRute in rute.segmen:
		ids.append(s.id)
	bagian.append("S=" + ",".join(ids))
	var pel: Array[String] = []
	for p: RouteBuilder.RumahRute in rute.pelanggan:
		pel.append(p.id)
	bagian.append("P=" + ",".join(pel))
	var tip: Array = rute.id_pemberi_tip.keys()
	tip.sort()
	bagian.append("T=" + ",".join(PackedStringArray(tip)))
	var objek: Array[String] = []
	for o: RouteBuilder.ObjekRute in rute.objek:
		objek.append("%s@%s@%d@%s" % [o.jenis, o.id_segmen, int(o.maju_ubin), o.jalur])
	bagian.append("O=" + ";".join(objek))
	var misi: Array[String] = []
	for t: RouteBuilder.TitikMisiRute in rute.titik_misi:
		misi.append("%s@%d@%d" % [t.nama, int(t.maju_ubin), t.sisi])
	bagian.append("M=" + ";".join(misi))
	var dekor: Array[String] = []
	for d: RouteBuilder.DekorItem in rute.dekor:
		dekor.append(d.id)
	bagian.append("D=" + ",".join(dekor))
	var rumah: Array[String] = []
	for r: RouteBuilder.RumahRute in rute.rumah:
		rumah.append("%s:%d:%s" % [r.id, int(r.maju_ubin), r.jenis])
	bagian.append("R=" + ",".join(rumah))
	return "\n".join(bagian)


func _initialize() -> void:
	var pustaka: Array[SegmenRute] = PemuatRute.muat_folder("res://assets/data/routes/perumahan").segmen
	var sidik: Dictionary = {}
	for hari: int in range(1, HARI_MAKS + 1):
		var daftar: Array = []
		for i: int in range(JUMLAH_SEED):
			var hasil: RouteBuilder.Hasil = RouteBuilder.bangun(SEED_AWAL + SEED_LANGKAH * i, pustaka, hari)
			daftar.append(fnv(identitas(hasil.rute)) if hasil.sah() else -1)
		sidik[str(hari)] = daftar
	var isi: Dictionary = {
		"sumber": "RouteBuilder.bangun(benih, pustaka, hari) tanpa keadaan pelanggan, dihitung tests/ukur_golden_rute.gd",
		"seed_awal": SEED_AWAL, "seed_langkah": SEED_LANGKAH, "jumlah_seed": JUMLAH_SEED,
		"blob_route_builder_main": "ef5a6e183eb253f326a8d3932eb2999bbbc99e82",
		"sidik": sidik,
	}
	var f: FileAccess = FileAccess.open(KELUARAN, FileAccess.WRITE)
	f.store_string(JSON.stringify(isi, "\t", true))
	f.close()
	print("golden ditulis: ", KELUARAN)
	quit()
