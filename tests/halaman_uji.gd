class_name HalamanUji
extends RefCounted
## Halaman depan koran sintetis dan nyata, dipakai bersama tes layar koran (`tests/tes_halaman_koran.gd`) dan probe jendela
## (`tests/probe_halaman_koran_jendela.gd`) supaya keduanya memotret dan menguji keadaan yang sama (run fase4a-koran-hari).
## Teks sintetis diterjemahkan lewat `Translation` sementara berlokal `id` yang dilepas lagi (`lepas_terjemahan`).

const KUNCI_UTAMA: String = "TES_KORAN_UTAMA_PANJANG"
const KUNCI_MISI: String = "TES_KORAN_MISI_PANJANG"
const KUNCI_RINGKASAN: String = "TES_KORAN_RINGKASAN_PANJANG"
const KUNCI_RINGAN: String = "TES_KORAN_RINGAN_PANJANG"
const KUNCI_LANJUTAN: String = "TES_KORAN_LANJUTAN"
## Teks terpanjang yang sah (40 / 40 / 40 karakter; ringkasan 60), huruf lebar supaya baris terlebar mungkin.
const TEKS_UTAMA: String = "Mmmmmmmm Wwwwwwww Mmmmmmmm Wwwwwwww Mmmm"
const TEKS_MISI: String = "Wwwwwwww Mmmmmmmm Wwwwwwww Mmmmmmmm Wwww"
const TEKS_RINGKASAN: String = "Mmmmmm wwwwww mmmmmm wwwwww mmmmmm wwwwww mmmmmm wwwwww mmmm"
const TEKS_RINGAN: String = "Wwwwwwww Mmmmmmmm Wwwwwwww Mmmmmmmm Mmmm"
const TEKS_LANJUTAN: String = "Kucing Bu Ratmi Belum Ditemukan"


## Memasang terjemahan sintetis; mengembalikan objeknya untuk `lepas_terjemahan`.
static func pasang_terjemahan() -> Translation:
	var t: Translation = Translation.new()
	t.locale = "id"
	t.add_message(&"TES_KORAN_UTAMA_PANJANG", TEKS_UTAMA)
	t.add_message(&"TES_KORAN_MISI_PANJANG", TEKS_MISI)
	t.add_message(&"TES_KORAN_RINGKASAN_PANJANG", TEKS_RINGKASAN)
	t.add_message(&"TES_KORAN_RINGAN_PANJANG", TEKS_RINGAN)
	t.add_message(&"TES_KORAN_LANJUTAN", TEKS_LANJUTAN)
	TranslationServer.add_translation(t)
	return t


static func lepas_terjemahan(t: Translation) -> void:
	TranslationServer.remove_translation(t)


static func _entri(id: String, jenis: String, teks: String, ringkasan: String = "", misi_id: String = "", efek: String = "") -> HeadlineManager.Entri:
	var e: HeadlineManager.Entri = HeadlineManager.Entri.new()
	e.id = id
	e.jenis = jenis
	e.teks = teks
	e.ringkasan = ringkasan
	e.misi_id = misi_id
	e.efek = efek
	return e


## Halaman dengan teks terpanjang yang sah di ketiga baris (perlu `pasang_terjemahan`).
static func terpanjang() -> HeadlineManager.Halaman:
	var h: HeadlineManager.Halaman = HeadlineManager.Halaman.new()
	h.utama = _entri("u_panjang", "utama", KUNCI_UTAMA, "", "", "hajatan")
	h.misi = _entri("m_panjang", "misi", KUNCI_MISI, KUNCI_RINGKASAN, "m_panjang")
	h.ringan = _entri("r_panjang", "ringan", KUNCI_RINGAN)
	return h


## Halaman tanpa misi yang memenuhi syarat (S-8): berita utama dan ringan nyata.
static func tanpa_misi() -> HeadlineManager.Halaman:
	var h: HeadlineManager.Halaman = nyata(3)
	h.misi = null
	return h


## Halaman dengan headline lanjutan di baris misi tanpa misi (misi_ditunda): teks tanpa tombol Ambil/Lewati (perlu `pasang_terjemahan`).
static func lanjutan_tanpa_misi() -> HeadlineManager.Halaman:
	var h: HeadlineManager.Halaman = nyata(4)
	h.misi = _entri("lanjutan_kucing_belum", "lanjutan", KUNCI_LANJUTAN)
	return h


## Halaman nyata hari `hari` dari data (tanpa flag dan tanpa riwayat jeda).
static func nyata(hari: int) -> HeadlineManager.Halaman:
	var m: HeadlineManager.Masukan = HeadlineManager.Masukan.new()
	m.hari = hari
	m.pustaka = PemuatHeadline.muat_folder()
	m.misi = PemuatMisi.muat_folder().misi
	return HeadlineManager.susun(m)
