class_name MesinHari
extends RefCounted
## Mesin alur satu hari, logika murni (TECH_PLAN 3.2, AC-16 run fase4a-koran-hari; S-1, S-6; AC-19 run fase6a1-bengkel-kondisi, M-8). Keadaan: `KORAN` -> `RUTE` -> `HASIL` -> `BENGKEL`
## -> `KORAN` (hari + 1): dari `HASIL` peristiwa `BUKA_BENGKEL` membuka bengkel dan hanya dari `BENGKEL` peristiwa `HARI_BERIKUTNYA` mengakhiri hari (dari `HASIL` ditolak). Tiap peristiwa hanya sah dari satu keadaan; peristiwa di luar urutan ditolak tanpa efek (`diterima` false, status sama), jadi
## ketukan ganda Berangkat atau "Hari berikutnya" tidak memulai dua rute dan tidak menambah hari dua kali. Perilaku tombol back Android per
## keadaan (S-6) juga di sini. Tanpa node, `Time`, atau RNG. Alur hari berurutan ini prototype yang tidak mengunci struktur sesi (ROADMAP 5).

## Keadaan hari.
enum Keadaan { KORAN, RUTE, HASIL, BENGKEL }
## Peristiwa yang menggerakkan hari: Berangkat di layar koran, layar hasil terbuka (rute selesai), "Hari berikutnya" di bengkel, "Ke bengkel" di layar hasil.
enum Peristiwa { BERANGKAT, HASIL_TERBUKA, HARI_BERIKUTNYA, BUKA_BENGKEL }
## Yang dilakukan tombol back Android: keluar app (koran), jeda (rute, diurus `AdeganJalan`), tidak melakukan apa pun (hasil), atau melewati bengkel = "Hari berikutnya" (bengkel).
enum AksiBack { KELUAR_APP, JEDA_RUTE, ABAIKAN, LEWATI_BENGKEL }

## Tabel transisi: keadaan -> {peristiwa -> keadaan berikutnya}.
const _TRANSISI: Dictionary = {
	Keadaan.KORAN: {Peristiwa.BERANGKAT: Keadaan.RUTE},
	Keadaan.RUTE: {Peristiwa.HASIL_TERBUKA: Keadaan.HASIL},
	Keadaan.HASIL: {Peristiwa.BUKA_BENGKEL: Keadaan.BENGKEL},
	Keadaan.BENGKEL: {Peristiwa.HARI_BERIKUTNYA: Keadaan.KORAN},
}


## Status hari: keadaan, nomor hari yang sedang berjalan, dan apakah peristiwa terakhir diterima.
class Status extends RefCounted:
	var keadaan: Keadaan = Keadaan.KORAN
	var hari: int = Config.HARI_AWAL
	## False bila peristiwa terakhir ditolak (di luar urutan).
	var diterima: bool = true

	func salin() -> Status:
		var s: Status = Status.new()
		s.keadaan = keadaan
		s.hari = hari
		s.diterima = diterima
		return s


## Status di layar koran hari `hari`.
static func awal(hari: int) -> Status:
	var s: Status = Status.new()
	s.hari = hari
	return s


## True bila `peristiwa` sah dari `keadaan`.
static func boleh(keadaan: Keadaan, peristiwa: Peristiwa) -> bool:
	var dari: Dictionary = _TRANSISI[keadaan]
	return dari.has(peristiwa)


## Status sesudah `peristiwa`. Peristiwa di luar urutan: salinan status yang sama dengan `diterima` false. "Hari berikutnya" menaikkan hari tepat 1.
static func terapkan(status: Status, peristiwa: Peristiwa) -> Status:
	var baru: Status = status.salin()
	if not boleh(status.keadaan, peristiwa):
		baru.diterima = false
		return baru
	var dari: Dictionary = _TRANSISI[status.keadaan]
	baru.keadaan = dari[peristiwa]
	baru.diterima = true
	if peristiwa == Peristiwa.HARI_BERIKUTNYA:
		baru.hari = status.hari + 1
	return baru


## Aksi tombol back Android pada `keadaan` (S-6, M-8): koran = keluar app (tidak ada yang hilang, simpan hanya di akhir hari), rute = jeda,
## hasil = diabaikan (tombol "Ke bengkel" satu-satunya jalan), bengkel = melewati bengkel (sama dengan "Hari berikutnya": belanja yang sudah dibayar tetap, K-4).
static func aksi_back(keadaan: Keadaan) -> AksiBack:
	match keadaan:
		Keadaan.KORAN:
			return AksiBack.KELUAR_APP
		Keadaan.RUTE:
			return AksiBack.JEDA_RUTE
		Keadaan.BENGKEL:
			return AksiBack.LEWATI_BENGKEL
		_:
			return AksiBack.ABAIKAN
