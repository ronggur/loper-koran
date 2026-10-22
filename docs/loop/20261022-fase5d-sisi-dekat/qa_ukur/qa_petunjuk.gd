extends SceneTree
func _init() -> void:
	var kum: PemuatRute.Kumpulan = PemuatRute.muat_folder()
	var mk: PemuatMisi.Kumpulan = PemuatMisi.muat_folder()
	var misi: DataMisi = mk.misi[0]
	var n_dekat_jendela: int = 0
	var n_seb_jendela: int = 0
	var n_petunjuk_dekat: int = 0
	var n_petunjuk_seb: int = 0
	var rute_ok: int = 0
	for hari: int in range(3, 103):
		var h: RouteBuilder.Hasil = RouteBuilder.bangun(SeedHari.rute(hari), kum.segmen, hari)
		var rencana: RencanaMisi.Rencana = RencanaMisi.buat(misi, h.rute, SeedHari.rute(hari) + Config.SEED_MISI_SELISIH)
		if not rencana.sah():
			continue
		rute_ok += 1
		var titik0: RencanaMisi.Titik = rencana.titik[0]
		# kucing di sisi seberang (rumah titik)
		for p: RouteBuilder.RumahRute in h.rute.pelanggan:
			if p.maju_ubin < titik0.petunjuk_awal_ubin or p.maju_ubin >= titik0.petunjuk_akhir_ubin:
				continue
			var k: MissionManager.Keadaan = MissionManager.awal(rencana)
			var m: MissionManager.Masukan = MissionManager.Masukan.new()
			m.maju_ubin = 0.0
			m.dt = 0.016
			var l: MissionManager.Lemparan = MissionManager.Lemparan.new()
			l.tepat = true
			l.kotak_pelanggan = true
			l.maju_rumah_ubin = p.maju_ubin
			m.lemparan = [l]
			var r: MissionManager.Hasil = MissionManager.langkah(k, m)
			var dekat: bool = p.sisi == LoperAnim.Sisi.DEKAT
			if dekat:
				n_dekat_jendela += 1
				if r.ada(MissionManager.Peristiwa.PETUNJUK):
					n_petunjuk_dekat += 1
			else:
				n_seb_jendela += 1
				if r.ada(MissionManager.Peristiwa.PETUNJUK):
					n_petunjuk_seb += 1
	print("PETUNJUK rute_ok=", rute_ok, " pelanggan dekat di jendela langkah-1=", n_dekat_jendela, " memberi petunjuk=", n_petunjuk_dekat, " seberang=", n_seb_jendela, " memberi petunjuk=", n_petunjuk_seb)
	quit()
