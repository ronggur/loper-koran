extends SceneTree
func _initialize() -> void:
	var dt: float = 1.0 / 60.0
	var k: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	k.kecepatan_ud = 3.0
	var tahap: int = 0
	var syarat_detik: float = 0.0
	var syarat_tanpa_berhenti: float = 0.0
	var per_pose: Dictionary = {}
	var maks_runtun: float = 0.0
	for i: int in range(600):
		var stick: Vector2 = Vector2(0, -1) if tahap == 0 else Vector2.ZERO
		var h: BikeMotion.Hasil = BikeMotion.langkah(k, stick, dt)
		k = h.keadaan
		if tahap == 0 and k.kecepatan_ud == 0.0:
			tahap = 1
		var syarat: bool = k.kecepatan_ud <= Config.MISI_TANGKAP_KECEPATAN_MAKS_UD + Config.MISI_TANGKAP_TOLERANSI
		if syarat:
			syarat_detik += dt
			var nama: String = LoperAnim.Pose.keys()[h.pose]
			per_pose[nama] = float(per_pose.get(nama, 0.0)) + dt
			if h.pose != LoperAnim.Pose.BERHENTI:
				syarat_tanpa_berhenti += dt
		elif tahap == 1 and syarat_detik > 0.0:
			break
	print("runtun syarat tangkap %.3f detik; per pose %s; tanpa BERHENTI %.3f detik (rem dilepas segera sesudah berhenti)" % [syarat_detik, per_pose, syarat_tanpa_berhenti])
	# Kasus 2: tanpa rem sama sekali, stick bawah 0,89 dari santai: kecepatan tujuan.
	print("tujuan stick -0,89 (di bawah ambang rem 0,90): %.3f u/d" % BikeMotion.kecepatan_tujuan_ud(-0.89))
	# Kasus 3: rem diketuk berulang supaya 0 < v <= 1,5 tanpa pernah berhenti.
	k = BikeMotion.Keadaan.new()
	k.kecepatan_ud = 3.0
	var tekan: bool = true
	var runtun: float = 0.0
	var terbaik: float = 0.0
	var min_v: float = 9.0
	var pose_dipakai: Dictionary = {}
	for i: int in range(1200):
		if k.kecepatan_ud <= 0.4:
			tekan = false
		elif k.kecepatan_ud >= 1.3:
			tekan = true
		var h: BikeMotion.Hasil = BikeMotion.langkah(k, Vector2(0, -1) if tekan else Vector2.ZERO, dt)
		k = h.keadaan
		if k.kecepatan_ud <= 1.5 + 0.000001:
			runtun += dt
			min_v = minf(min_v, k.kecepatan_ud)
			pose_dipakai[LoperAnim.Pose.keys()[h.pose]] = true
		else:
			runtun = 0.0
		terbaik = maxf(terbaik, runtun)
	print("rem diketuk (lepas di <= 0,4, tekan di >= 1,3): runtun syarat %.2f detik (batas 20 detik simulasi), kecepatan minimum %.3f, pose %s" % [terbaik, min_v, pose_dipakai.keys()])
	quit(0)
