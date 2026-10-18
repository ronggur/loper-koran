class_name TutorialLangkah
extends RefCounted
## Tutorial terpandu hari 1, logika murni (M-9, AC-18 run fase4b-misi-kucing; TECH_PLAN Fase 4, STORY 6; usulan, dinilai lewat uji HP).
##
## Hanya bila `tutorial.selesai` di save masih false DAN hari = `Config.HARI_AWAL` (`boleh_aktif`). Empat petunjuk kontekstual, satu per langkah, urut:
## 1. `KAYUH`: dorong stick ke atas (selesai bila kecepatan >= `TUTORIAL_KAYUH_KECEPATAN_UD`);
## 2. `MELAMBAT`: tarik stick ke bawah (kecepatan <= `TUTORIAL_MELAMBAT_KECEPATAN_UD`);
## 3. `LEMPAR`: lempar koran (sedikitnya satu lemparan diterima);
## 4. `MENEPI`: HANYA bila misi P1 diambil; tampil saat kucing langkah `tangkap` terlihat, selesai bila misi berakhir (selesai atau gagal).
## Tanpa misi: tiga petunjuk, lalu selesai. Tutorial TIDAK memblokir input: ini hanya keadaan dan teks; node (`TutorialController`) tidak membaca atau
## menelan sentuhan di luar tombol Lewati (≥ 42 px, di strip atas di luar zona kontrol). `lewati` mengakhiri tutorial seketika. Hari tutorial yang berakhir
## (rute selesai) menulis `tutorial.selesai` di akhir hari lewat `DataSave.catat_hari` (bukan di tengah rute, rule save-system). Tanpa node, `Time`, atau RNG;
## masukan tidak diubah.

enum Langkah { KAYUH, MELAMBAT, LEMPAR, MENEPI, SELESAI }

## Kunci teks petunjuk per langkah (`translations/ui.csv`, awalan `TUTORIAL_`). `SELESAI` tidak punya teks.
const KUNCI_TEKS: Dictionary = {
	Langkah.KAYUH: "TUTORIAL_KAYUH",
	Langkah.MELAMBAT: "TUTORIAL_MELAMBAT",
	Langkah.LEMPAR: "TUTORIAL_LEMPAR",
	Langkah.MENEPI: "TUTORIAL_MENEPI",
}


## Keadaan tutorial. Diganti objek baru tiap perubahan.
class Keadaan extends RefCounted:
	## Tutorial berjalan (false = tidak pernah dimulai: bukan hari 1 atau sudah selesai di save).
	var aktif: bool = false
	var langkah: Langkah = Langkah.KAYUH
	## Misi P1 diambil hari ini, jadi ada petunjuk menepi.
	var ada_misi: bool = false
	## Dilewati pemain (tombol Lewati).
	var dilewati: bool = false
	## Kucing langkah tangkap sudah pernah terlihat (petunjuk menepi mulai tampil dan tetap tampil sampai misi berakhir).
	var menepi_terlihat: bool = false

	func salin() -> Keadaan:
		var baru: Keadaan = Keadaan.new()
		baru.aktif = aktif
		baru.langkah = langkah
		baru.ada_misi = ada_misi
		baru.dilewati = dilewati
		baru.menepi_terlihat = menepi_terlihat
		return baru


## Masukan satu langkah waktu.
class Masukan extends RefCounted:
	var kecepatan_ud: float = 0.0
	## Jumlah lemparan yang sudah diterima sejak rute dimulai.
	var jumlah_lempar: int = 0
	## Kucing langkah `tangkap` sedang terlihat (`MissionManager`: titik aktif berjenis tangkap dan tampil).
	var kucing_tangkap_terlihat: bool = false
	## Misi sudah berakhir (selesai atau gagal).
	var misi_berakhir: bool = false


## True bila tutorial boleh dimulai: hari pertama dan `tutorial.selesai` belum true.
static func boleh_aktif(hari: int, tutorial_selesai: bool) -> bool:
	return hari == Config.HARI_AWAL and not tutorial_selesai


## Keadaan awal. `aktif` false = tutorial tidak berjalan (semua fungsi lain mengembalikan keadaan selesai).
static func awal(aktif: bool, ada_misi: bool) -> Keadaan:
	var k: Keadaan = Keadaan.new()
	k.aktif = aktif
	k.ada_misi = ada_misi
	if not aktif:
		k.langkah = Langkah.SELESAI
	return k


## Satu langkah waktu. Tutorial yang tidak aktif, dilewati, atau selesai tidak berubah. Beberapa langkah bisa selesai sekaligus (mis. kecepatan sudah melambat).
static func langkah(k: Keadaan, m: Masukan) -> Keadaan:
	var baru: Keadaan = k.salin()
	if not baru.aktif or baru.langkah == Langkah.SELESAI:
		return baru
	var berubah: bool = true
	while berubah and baru.langkah != Langkah.SELESAI:
		berubah = false
		match baru.langkah:
			Langkah.KAYUH:
				if is_finite(m.kecepatan_ud) and m.kecepatan_ud >= Config.TUTORIAL_KAYUH_KECEPATAN_UD:
					baru.langkah = Langkah.MELAMBAT
					berubah = true
			Langkah.MELAMBAT:
				if is_finite(m.kecepatan_ud) and m.kecepatan_ud <= Config.TUTORIAL_MELAMBAT_KECEPATAN_UD:
					baru.langkah = Langkah.LEMPAR
					berubah = true
			Langkah.LEMPAR:
				if m.jumlah_lempar >= 1:
					baru.langkah = Langkah.MENEPI if baru.ada_misi else Langkah.SELESAI
					berubah = true
			Langkah.MENEPI:
				if m.kucing_tangkap_terlihat:
					baru.menepi_terlihat = true
				if m.misi_berakhir:
					baru.langkah = Langkah.SELESAI
					berubah = true
	return baru


## Pemain menekan Lewati: tutorial berakhir seketika (tidak pernah muncul lagi, ditulis `tutorial.selesai` di akhir hari).
static func lewati(k: Keadaan) -> Keadaan:
	var baru: Keadaan = k.salin()
	if baru.aktif and baru.langkah != Langkah.SELESAI:
		baru.dilewati = true
		baru.langkah = Langkah.SELESAI
	return baru


## True bila petunjuk sedang tampil: aktif, belum selesai, dan petunjuk menepi hanya sesudah kucing tangkap terlihat.
static func tampil(k: Keadaan) -> bool:
	if not k.aktif or k.langkah == Langkah.SELESAI:
		return false
	if k.langkah == Langkah.MENEPI:
		return k.menepi_terlihat
	return true


## True bila tutorial sudah berakhir (selesai atau dilewati) atau tidak pernah aktif.
static func berakhir(k: Keadaan) -> bool:
	return not k.aktif or k.langkah == Langkah.SELESAI


## Kunci teks petunjuk langkah sekarang ("" bila selesai).
static func kunci_teks(k: Keadaan) -> String:
	return KUNCI_TEKS.get(k.langkah, "")


## Nomor langkah sekarang (mulai 1) dan jumlah langkah tutorial ini (empat dengan misi, tiga tanpa).
static func nomor(k: Keadaan) -> Vector2i:
	var total: int = Config.TUTORIAL_JUMLAH_LANGKAH_MISI if k.ada_misi else Config.TUTORIAL_JUMLAH_LANGKAH_TANPA_MISI
	return Vector2i(mini(int(k.langkah) + 1, total), total)
