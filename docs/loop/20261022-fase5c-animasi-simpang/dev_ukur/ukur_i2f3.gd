extends SceneTree
## Ukur ulang I2-F3 (AC-7 run 5C): piksel opak dekor di atas pose jatuh/terjerembab/bangkit (sel 140x88) yang TIDAK ditutup kotak penutup, di posisi tabrakan
## yang masuk akal (sisi rintangan, maju pos-1,5..pos+3,5, langkah 1/16) untuk tiap dekor dan rintangan di segmen yang sama (9 segmen nyata). Kontrol: pose berkendara.
func _gabung(daftar: Array) -> UkurPenutupPiksel.Topeng:
	var g: UkurPenutupPiksel.Topeng = UkurPenutupPiksel.Topeng.new()
	g.lebar = UkurPenutupPiksel.KANVAS
	g.tinggi = UkurPenutupPiksel.KANVAS
	g.pijak = Vector2i(UkurPenutupPiksel.KANVAS_PIJAK, UkurPenutupPiksel.KANVAS_PIJAK)
	g.data.resize(g.lebar * g.tinggi)
	for t: UkurPenutupPiksel.Topeng in daftar:
		for i: int in range(t.data.size()):
			if t.data[i] == 1:
				g.data[i] = 1
	g.selesai()
	return g
func _initialize() -> void:
	var f: String = "res://assets/sprites/loper/"
	var jatuh: UkurPenutupPiksel.Topeng = _gabung([UkurPenutupPiksel.topeng_sheet(f + "loper_agen_jatuh.png", f + "loper_agen_jatuh.json", false), UkurPenutupPiksel.topeng_sheet(f + "loper_agen_bangkit.png", f + "loper_agen_bangkit.json", false)])
	var kendara: UkurPenutupPiksel.Topeng = UkurPenutupPiksel.topeng_pemain()
	var lst: Array = DirAccess.get_files_at("res://assets/data/routes/perumahan")
	var total_kombinasi: int = 0
	var kena: int = 0
	var langkah: float = 1.0 / 16.0
	for nama: String in lst:
		if not nama.ends_with(".json"):
			continue
		var seg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/routes/perumahan/" + nama))
		for o: Dictionary in seg.get("objek", []):
			var pos: float = float(o["pos"])
			var arah: float = -1.0 if o["jalur"] == "seberang" else 1.0
			for dd: Dictionary in seg.get("dekor", []):
				var sisi: LoperAnim.Sisi = LoperAnim.Sisi.SEBERANG if dd["sisi"] == "seberang" else LoperAnim.Sisi.DEKAT
				var d: RouteBuilder.DekorItem = UkurPenutupPiksel.dekor_buatan(dd["jenis"], dd.get("varian", ""), sisi, float(dd["pos"]))
				var topeng_d: UkurPenutupPiksel.Topeng = UkurPenutupPiksel.topeng_prop(UkurPenutupPiksel.nama_prop(d))
				var ld: float = UkurPenutupPiksel.lateral_dekor(d)
				var pos_d: Vector2i = UkurPenutupPiksel.layar(ld, d.maju_ubin)
				var y_d: float = UkurPenutupPiksel.y_urut(ld, d.maju_ubin)
				var kotak: PenutupPemain.Objek = PenutupPemain.dari_dekor(d)
				var hasil: Array = [0, 0, 0, 0]  # posisi tak tertutup jatuh, piksel maks jatuh, posisi tak tertutup berkendara, piksel maks berkendara
				var terburuk: Vector2 = Vector2.ZERO
				for i: int in range(0, 33):
					var lateral: float = arah * float(i) * langkah
					for k: int in range(0, 81):
						var maju: float = pos - 1.5 + float(k) * langkah
						if y_d < UkurPenutupPiksel.y_urut(lateral, maju):
							continue
						if PenutupPemain.menutupi(Vector2(lateral, -maju), kotak):
							continue
						var p_layar: Vector2i = UkurPenutupPiksel.layar(lateral, maju)
						var pj: int = UkurPenutupPiksel.hitung_tumpang(topeng_d, pos_d, jatuh, p_layar)
						var pk: int = UkurPenutupPiksel.hitung_tumpang(topeng_d, pos_d, kendara, p_layar)
						if pj > 0:
							hasil[0] += 1
							if pj > hasil[1]:
								hasil[1] = pj
								terburuk = Vector2(lateral, maju)
						if pk > 0:
							hasil[2] += 1
							hasil[3] = maxi(hasil[3], pk)
				total_kombinasi += 1
				if hasil[0] > 0 or hasil[2] > 0:
					kena += 1
					print("%s %s %s@%d lawan %s %s@%d: jatuh %d posisi tak tertutup, maks %d piksel di (lat %.3f, maju %.3f); berkendara %d posisi, maks %d" % [nama, dd["jenis"], dd["sisi"], int(dd["pos"]), o["jenis"], o["jalur"], int(pos), hasil[0], hasil[1], terburuk.x, terburuk.y, hasil[2], hasil[3]])
	print("kombinasi dekor x rintangan sesegmen: %d, dengan tumpang: %d" % [total_kombinasi, kena])
	quit(0)
