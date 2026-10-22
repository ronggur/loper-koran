extends SceneTree
func _initialize() -> void:
	var masukan: Array = SimProfilKondisi.masukan_acak(500, 20261020)
	var semua: Array[PackedFloat64Array] = []
	var dipetakan: Array[PackedFloat64Array] = []
	var n_berhenti: int = 0
	for m: SimProfilKondisi.Masukan in masukan:
		var l: PackedFloat64Array = SimProfilKondisi.nilai_hasil(BikeMotion.langkah(m.keadaan, m.stick, m.dt, m.beku))
		semua.append(l)
		var l2: PackedFloat64Array = l.duplicate()
		if int(l2[11]) == LoperAnim.Pose.BERHENTI:
			n_berhenti += 1
			l2[11] = float(LoperAnim.Pose.REM)
		dipetakan.append(l2)
	print("BERHENTI: %d dari %d" % [n_berhenti, masukan.size()])
	print("sidik sekarang: %s" % SimProfilKondisi.sidik(semua))
	print("sidik BERHENTI->REM: %s" % SimProfilKondisi.sidik(dipetakan))
	quit(0)
