extends SceneTree
## REPRODUKSI QA iterasi 1 run 4B (bukan bagian run_tests.gd; QA-001): kucing misi harus terlihat DI DALAM LAYAR minimal `MISI_TAMPIL_DETIK_MIN` pada
## `KECEPATAN_NGEBUT_UD` (AC-5a, M-2, prinsip 3). Turunan dari geometri iso, kamera (sepeda di 1/3 lebar dan 0,75 tinggi + dorongan ngebut), dan sel sheet kucing
## beserta kilau. Dijalankan: godot --headless --script res://tests/qa_repro_tampil_layar.gd ; exit 1 bila ada kombinasi yang < 2,0 detik.

func _init() -> void:
	var gagal: int = 0
	var geser: Vector2 = DoronganKecepatan.geser_target(Config.KECEPATAN_NGEBUT_UD)
	for lebar: int in [640, 667, 780, 800]:
		for xp: float in [-2.0, -1.0, 0.0, 1.0, 2.0]:
			var d_tampak: float = _jarak_tampak(float(lebar), xp, geser)
			var detik: float = d_tampak / Config.KECEPATAN_NGEBUT_UD
			var ok: bool = detik >= Config.MISI_TAMPIL_DETIK_MIN - 0.001
			if not ok:
				gagal += 1
			print("%s lebar %d lateral sepeda %+.1f: kucing utuh (badan + kilau) di layar dari %.2f ubin = %.2f detik pada ngebut (min %.1f)" % ["OK   " if ok else "GAGAL", lebar, xp, d_tampak, detik, Config.MISI_TAMPIL_DETIK_MIN])
	print("%d kombinasi gagal" % gagal)
	quit(1 if gagal > 0 else 0)


## Jarak maju terjauh (<= MISI_TAMPIL_JARAK_UBIN) di depan sepeda saat seluruh sel kucing + kilau masih di dalam viewport.
func _jarak_tampak(lebar: float, lateral_sepeda: float, geser: Vector2) -> float:
	var sepeda: Vector2 = Vector2(lebar * Config.KAMERA_SEPEDA_X_PECAHAN, 360.0 * Config.KAMERA_SEPEDA_Y_PECAHAN) + geser
	var d: float = Config.MISI_TAMPIL_JARAK_UBIN
	while d > 0.0:
		var rel: Vector2 = Iso.dunia_ke_layar(Vector2(Config.MISI_KUCING_LATERAL_UBIN - lateral_sepeda, -d))
		var kaki: Vector2 = sepeda + rel
		var x_awal: float = kaki.x - float(Config.MISI_KUCING_PIJAK_PX[0])
		var x_akhir: float = x_awal + float(Config.MISI_KUCING_SEL_PX[0])
		var atas: float = kaki.y + float(Config.MISI_KILAU_POSISI_PX[1])
		var bawah: float = kaki.y - float(Config.MISI_KUCING_PIJAK_PX[1]) + float(Config.MISI_KUCING_SEL_PX[1])
		if x_awal >= 0.0 and x_akhir <= lebar and atas >= 0.0 and bawah <= 360.0:
			return d
		d -= 0.05
	return 0.0
