class_name AdeganJalan
extends Node2D
## Dasar adegan jalan (dari `JalanUji`, run fase3a-rute): sepeda digerakkan stick, kamera, jeda, lemparan koran, mode bantu, bunyi, dan HUD
## sementara. Dipakai bersama oleh `JalanUji` (jalan lurus tanpa ujung, dev) dan `RuteMain` (rute dari segmen); yang berbeda hanya
## dunianya, lewat kait (`_siapkan_dunia`, `_perbarui_dunia`, `_zona_bantu`, `_langkah_koran`, `_vektor_stick`, `_lempar_diizinkan`,
## `_medan`). Semua perilaku di bawah berlaku sama di kedua scene (satu kode, bukan salinan). Riwayat keputusan (D-nomor) menunjuk run
## yang membuatnya ketika kode ini masih bagian dari `JalanUji`.
##
## Akar tipis: tiap `_process` memberi vektor stick (sentuhan, atau keyboard di editor) ke `SepedaUji`, lalu
## menggeser tanah dan objek berkala, kamera, dan HUD. Kamera mengikuti sepeda penuh (posisi dibulatkan ke piksel)
## dengan sepeda di sepertiga kiri layar (ART_DIRECTION 2.2) dan tanpa zoom, ditambah dorongan kecepatan (GDD 15):
## saat ngebut sepeda bergeser maju sedikit di bingkai, saat melambat mundur sedikit, dihaluskan eksponensial. Geseran
## hanya menggeser kamera (`DoronganKecepatan`); posisi dunia dan posisi sprite sepeda serta HUD tidak berubah. Gerak
## halus tetap float di `SepedaUji`; hanya posisi gambar yang dibulatkan. Stamina dan rem tampil di HUD dan cincin stick.
##
## Lemparan koran (run fase2a-lemparan bagian 1b, arah bebas run fase2-arah-bebas): SATU fungsi `lintasan_swipe` (`ThrowSolver.dari_swipe`
## dari posisi sepeda, kecepatan maju sebenarnya, kecepatan lateral efektif langkah terakhir, dan jeda lepas animasi) dipakai garis bidik
## tiap langkah (sesudah sepeda digerakkan). Koran terbang ke arah swipe seperti terlihat di layar (arah tanah dari `Iso`), panjang |v|
## menentukan kekuatan, dan tidak ada sudut yang ditolak. Saat jari dilepas (D-5 run fase2-arah-bebas), lemparan memakai OBJEK lintasan
## garis bidik yang sedang tampil untuk swipe itu (dibekukan pada langkah terakhir), bukan menghitung ulang dari posisi lepas: jari yang
## masih bergerak atau berbelok ke arah mana pun saat diangkat (flick) tidak membatalkan lemparan dan tidak mengubah titik mendarat, jadi
## koran mendarat tepat di elips terakhir yang terlihat (QA-001 Run 2A). Lemparan batal HANYA bila panjang swipe di posisi lepas |v_lepas|
## di bawah min (jari ditarik kembali ke dekat titik awal): tidak ada koran, jadi tidak ada hasil yang berbeda dari prediksi. Bila tidak
## ada garis bidik yang tampil untuk swipe itu (swipe turun dan naik di antara dua langkah, atau langkah terakhir menolak swipe karena
## masih pendek), lemparan dihitung dari posisi lepas dengan `lintasan_swipe` yang sama dan keadaan sepeda yang sama (keadaan langkah
## terakhir): tidak ada prediksi tampil yang bisa berbeda. Lemparan diterima bila `SisaKoran` mengizinkan (koran ada, jeda antar lempar
## 0,35 detik lewat; D-8, D-9): koran berkurang tepat 1, animasi lempar dimulai ke sisi lintasan (`ThrowSolver.sisi_dari_arah`), dan
## `KoranLempar` membekukan lintasannya. Koran terbang, mendarat, dinilai zona dari titik mendarat saja (`ZonaSasaran`), dan penandanya
## tampil sesuai waktu langkah (`dt` efektif), digambar `KoranGambar` (bayangan di tanah, koran dan penanda di atas objek). Garis bidik
## (`GarisBidik`, D-5 Run 2A) hanya tampil selama swipe ditahan, |v| cukup, dan lempar diizinkan. Isi ulang koran khusus jalan uji
## (`SisaKoran.isi_ulang_jalan_uji`, alat uji, hanya di `JalanUji` lewat `_langkah_koran`). Zona placeholder digambar `ZonaGambar` di bawah objek dunia (hanya `JalanUji`).
##
## Jeda (D-6 run fase1b-umpan-balik, `JedaSim`): tombol jeda di HUD, app di-background atau kehilangan fokus (PAUSED, FOCUS_OUT), dan
## tombol back Android saat berjalan membuka **layar jeda** (`LayarJeda`). Tidak ada lanjut otomatis: RESUMED dan FOCUS_IN tidak
## mengubah apa pun; pemain melanjutkan lewat tombol "Lanjut" atau back saat layar jeda terbuka. Selama jeda `SceneTree.paused`
## menyala, jadi sprite pemain, partikel umpan balik, dan input stick dan swipe berhenti; bunyi sepeda dihentikan `Audio` lewat
## `jeda_berubah` (lihat bawah); hanya layar jeda (`PROCESS_MODE_WHEN_PAUSED`) yang menerima sentuhan. `perbarui` tetap boleh dipanggil tetapi
## memakai `dt` 0, jadi kecepatan, jarak, stamina, lama tahan rem, dan geseran dorongan tidak berubah; saat menjeda stick dan swipe
## dilepas, lempar ditutup, dan lama tahan rem kembali 0 (`SepedaUji.jeda`). Langkah pertama sesudah lanjut ber-`dt` 0.
## Koran yang sudah diterima tidak hilang karena jeda (D-11): waktunya ikut `dt` efektif, jadi koran terbang, jeda antar lempar, penanda,
## dan isi ulang membeku selama jeda dan lanjut tanpa lompatan; jeda di antara jari dilepas dan frame lepas hanya menutup animasi.
## Titik kait untuk node lain: sinyal `jeda_berubah` dan `sedang_jeda()`.
##
## Mode bantu (GDD 5.3; K-1 sampai K-4, D-1 sampai D-7 run fase2b-bantu-audio, usulan): sakelar di HUD (`HudDev.bantu_diubah`, bawaan
## mati, tidak disimpan). Saat menyala, TAP di zona swipe (`TouchRouter.tap_selesai`, posisi = titik awal sentuhan) melempar otomatis:
## sisi dari posisi tap terhadap garis jalan yang melewati sepeda di layar (`BantuLempar.sisi_tap`, `posisi_layar_sepeda`), sasaran =
## kotak surat pelanggan terdekat di depan pada sisi itu (`BantuLempar.pilih` atas zona jalan uji sejauh jangkauan lemparan), lintasan =
## keluaran `ThrowSolver.hitung` dari keadaan sepeda langkah terakhir, dibekukan saat tap diterima (tanpa garis bidik; elips pendaratan
## dan penanda tetap). Gerbangnya sama dengan swipe (tidak jeda, `SisaKoran.boleh_lempar`, `SisaKoran.terima`) dan langkah sesudahnya juga
## sama (`_lempar`: koran terbang, animasi, HUD, sinyal `koran_dilempar`). Tap yang ditolak karena tidak ada sasaran tidak memakai koran
## dan tidak memulai jeda; tanda kecil tampil di titik tap (`KontrolTouch.tampilkan_tanda`, D-6). Ditolak karena habis atau jeda antar
## lempar = tidak ada tanda (HUD koran sudah memberi tanda HABIS). Swipe manual tetap melempar seperti biasa di mode bantu. Kecepatan
## otomatis (K-1) = perilaku stick netral (santai 3,0 u/d, tidak menguras stamina); stick tetap aktif penuh.
##
## Bunyi lempar dan mendarat (D-10 sampai D-12 run fase2b-bantu-audio): `koran_dilempar` dipancarkan tepat sekali per lemparan yang
## DITERIMA, swipe maupun tap (lemparan ditolak tidak memancarkannya), dan disambungkan ke `Audio.putar_lempar` ("wus"; pasangan visualnya
## garis bidik hilang dan koran muncul). `koran_mendarat` tepat sekali per koran pada langkah ia mendarat, disambungkan ke
## `Audio.putar_mendarat` dengan hasil koran itu dan sakelar jendela yang sama dengan penilaiannya (pasangan visualnya penanda di titik
## mendarat). `jeda_berubah` menghentikan bunyi lempar/mendarat yang sedang berbunyi lewat `Audio.atur_jeda`.
##
## Bunyi sepeda (D-3, D-5): tiap langkah keadaan sebenarnya (pose, kecepatan, rem, jeda) diberikan ke autoload `Audio` (`/root/Audio`,
## dicari lewat jalur node, bukan nama global, supaya scene tetap jalan tanpa autoload); `jeda_berubah` disambungkan ke
## `Audio.atur_jeda` (semua bunyi sepeda berhenti saat jeda, tanpa decit rem tertunda), dan keluar dari pohon menghentikannya.
##
## Rintangan, tabrakan, skor, dan bel (run fase3b-rintangan-skor bagian B; keadaan murni `RintanganRute`, `SkorRute`, `Bel`):
## - Urutan satu langkah (sama dengan simulasi `TesRintangan._sim_rute`): sepeda digerakkan dengan `beku_detik = jatuh_detik` (diam selama
##   jatuh), lalu `RintanganRute.langkah` dengan posisi dan kecepatan sepeda baru; tiap peristiwa (waspada, mengejar, lampu mundur, mesin)
##   ke `Audio.putar_peristiwa` (pasangan visualnya animasi sprite rintangan); tabrakan baru = jatuh (keputusan pemilik 2026-10-17):
##   `SepedaUji.tabrak` (kecepatan 0), combo putus, `Audio.putar_tabrakan`, sinyal `tabrakan(jenis)` dengan jenis data penyebabnya (AC-8),
##   dan visual jatuh/terjerembab, kedip kebal sesudah bangun, dan kilatan dari keadaan tabrakan tiap langkah. Selama jatuh lemparan swipe
##   dan tap mode bantu ditolak tanpa memakai koran (`_lempar_terbuka`) dan garis bidik tidak tampil; bel tetap boleh (paling sederhana:
##   tidak ada aturan tambahan). Rintangan dunia diisi kait `_rintangan_awal` (jalan uji: kosong, scene rute: dari data rute).
## - Koran mendarat: di scene yang menilai skor (`_skor_aktif`, hanya rute) `SkorRute.nilai_koran` dulu, penanda koran ditimpa penanda skor
##   (tepat, netral), umpan balik melayang, lalu `koran_mendarat` dan bunyi: mendarat dengan nada combo (`BunyiLempar.pitch_mendarat`),
##   denting tip, kilau tepat. Jalan uji tidak menilai skor (zonanya tanpa id rumah) dan bunyinya tetap nada dasar.
## - Mode bantu: koran tap dibuat `KoranLempar.baru(lintasan, true)`, jadi tidak pernah tepat (O-4).
## - Bel: jari yang turun di zona bel (`TouchRouter.bel_ditekan`) -> `ketuk_bel`: `Bel.ketuk` (ditolak saat jeda game), bunyi bel, dan
##   `RintanganRute.terapkan_bel` (anjing waspada/mengejar dalam jangkauan mundur, ikon "!"). Tombol dan efek "KRING!" dari `Bel` tiap langkah.
## - Semua waktu (rintangan, jatuh, kebal, bel, label PUTUS, umpan balik melayang) ikut `dt` efektif: jeda membekukannya, tanpa lanjut
##   otomatis. `_kembalikan_awal` ("Main lagi") mengatur ulang rintangan, tabrakan, skor, combo, koin, status terantar, bel, dan bunyi rute.
##
## Run fase4b-misi-kucing (AC-11 sampai AC-14): kait `_koran_dinilai` (koran yang baru dinilai skor, untuk petunjuk misi dari lemparan tepat) dan
## `_koin_tambahan` (koin hadiah misi yang ikut tampil di HUD, supaya HUD, layar hasil, dan save memakai angka yang sama). Bawaan: tidak ada.
##
## Run fase6a1-bengkel-kondisi bagian B (AC-6, AC-8, AC-11, AC-23): kondisi sepeda (`KondisiRute`, logika murni) hanya ada bila adegan turunan menyediakannya (kait `_kondisi_awal`; rute
## ya, jalan uji tidak). Tiap langkah: `SepedaUji.gerak` memakai `EfekKondisi` dari kondisi dan level upgrade tersimpan, lalu telemetri gerak dan tabrakan baru (tepi naik `Tabrakan`)
## masuk `KondisiRute.langkah` (aus, kerusakan, peringatan). Peristiwa peringatan = bunyi (`Audio.putar_kondisi_peringatan`) dan visual (ikon bergetar, kotak WARN di HUD) pada langkah yang
## sama. Tanpa cabang mode bantu (K-2). Waktu ikut `dt` efektif, jadi jeda dan background membekukan semuanya.
##
## Run fase3c-hud-hasil (O-6, K-1, AC-9): HUD bertipe `HudDasar` (jalan uji `HudDev`, rute `HudRute`). Kidal dan mode bantu diubah dari
## sakelar layar jeda (`LayarJeda.kidal_diubah` / `bantu_diubah`) atau sakelar HUD dev jalan uji; keduanya lewat `atur_kidal` /
## `atur_mode_bantu`, yang menyamakan kontrol, HUD, dan layar jeda. Zona tap bel mengikuti geseran zona aman HUD (`HudDasar.geser_bel`)
## tiap langkah. Kait baru: `_langkah_waktu` (jam tenggat rute, dt efektif, sesudah sepeda digerakkan), `_tenggat_lewat` (status tenggat
## saat koran mendarat, untuk tip, `SkorRute.nilai_koran`), dan `_saring_jeda` (rute mengabaikan back di layar hasil).
##
## Run garis-finish-portal bagian C (G-2, G-5; usulan): sesudah garis akhir sepeda melaju keluar viewport (bukan direm), jadi adegan turunan punya kait tambahan, semuanya bawaan tidak berubah
## untuk jalan uji: `_siapkan_gerak` (laju dijaga sebelum langkah gerak), `_jarak_dunia` (jarak yang dipakai tanah dan dunia; dibekukan di garis akhir supaya tanah dan jendela daur tidak ikut sepeda
## keluar dan tidak muncul lubang di belakang kamera yang beku), `_rintangan_aktif` (mati sesudah garis akhir: tidak ada tabrakan baru, jam jatuh tetap berjalan), `_bel_diizinkan`, dan
## `_sepeda_senyap`. Kamera beku (`_bekukan_kamera`, dipanggil adegan turunan SEKALI saat garis tercapai): posisi kamera dan geseran dorongan tidak berubah lagi sampai `_kembalikan_awal`.

## Status jeda berubah: true = layar jeda dibuka (simulasi, sprite, partikel, dan input berhenti), false = lanjut.
signal jeda_berubah(jeda: bool)
## Lemparan diterima (jari swipe dilepas atau tap mode bantu diterima, koran berkurang 1): lintasan beku koran itu. Tepat sekali per
## koran yang benar-benar terpakai.
signal koran_dilempar(lintasan: ThrowSolver.Lintasan)
## Tap mode bantu ditolak karena tidak ada kotak surat terjangkau (D-6): titik tap, koordinat viewport game.
signal bantu_tanpa_sasaran(posisi: Vector2)
## Koran mendarat dan sudah dinilai (`KoranLempar.Koran`: hasil, antaran, penanda; di scene rute penanda sudah dari skor).
signal koran_mendarat(koran: KoranLempar.Koran)
## Tabrakan baru dengan rintangan berjenis data `jenis` (`anjing_penjaga`, `mobil_garasi`; AC-8).
signal tabrakan(jenis: String)
## Satu koran dinilai skor (hanya scene yang menilai skor): hasil `SkorRute.nilai`.
signal skor_dinilai(hasil: SkorRute.Hasil)
## Ketukan bel berbunyi (`Bel.Bunyi.KRING` atau `KRING_KRING`); `bereaksi` = id rintangan yang mundur.
signal bel_berbunyi(bunyi: Bel.Bunyi, bereaksi: Array[int])
## Satu peristiwa tanda peringatan kondisi (rantai berisik, rem berdecit, ban mendesis): id komponen. Bunyi dan visual HUD sudah dipicu pada langkah yang sama.
signal peringatan_kondisi(komponen: String)

## Skrip autoload `Audio`, hanya untuk tipe (`Audio` tidak merujuk autoload lain, rule `gdscript`).
const SKRIP_AUDIO := preload("res://scripts/autoload/audio.gd")

## Geseran sepeda di layar akibat dorongan kecepatan yang sudah dihaluskan, piksel game.
var _geser_dorongan: Vector2 = Vector2.ZERO
## True selama layar jeda terbuka (`JedaSim`).
var _jeda: bool = false
## True bila langkah berikutnya adalah langkah pertama sesudah lanjut (memakai dt 0).
var _baru_lanjut: bool = false
## Autoload `Audio` bila terdaftar (null bila scene dijalankan tanpa autoload).
var _audio: SKRIP_AUDIO = null
## Sisa koran dan jeda antar lempar (`SisaKoran`). Publik untuk tes; diganti objek baru tiap perubahan.
var koran: SisaKoran.Keadaan = SisaKoran.awal(Config.KORAN_AWAL)
## Koran yang sudah dilempar dan belum selesai (terbang, atau penandanya masih tampil).
var _terbang: Array[KoranLempar.Koran] = []
## Nomor swipe (`TouchRouter.nomor_swipe`) yang garis bidiknya sedang tampil; -1 bila belum ada.
var _bidik_nomor: int = -1
## True selama mode bantu menyala (D-7; bawaan mati, tidak disimpan).
var _mode_bantu: bool = false

## Rintangan dunia dan tabrakan sepeda (`RintanganRute`). Kosong di jalan uji.
var _rintangan: RintanganRute.Keadaan = RintanganRute.Keadaan.new()
## Skor, combo, koin, tip, rumah terantar (`SkorRute`).
var _skor: SkorRute.Keadaan = SkorRute.awal()
## Bel (`Bel`).
var _bel: Bel.Keadaan = Bel.awal()
## Sisa waktu label PUTUS di HUD, detik.
var _putus_detik: float = 0.0
## Umpan balik melayang yang sedang tampil (`UmpanMelayang`).
var _umpan: Array[UmpanMelayang.Entri] = []
## Kondisi sepeda rute ini (`KondisiRute`); null di jalan uji (tanpa aus, tanpa efek).
var _kondisi: KondisiRute.Keadaan = null

## True sejak kamera dibekukan (`_bekukan_kamera`) sampai `_kembalikan_awal`, dan posisi kamera beku itu.
var _kamera_beku: bool = false
var _posisi_kamera_beku: Vector2 = Vector2.ZERO

## Medan sasaran koran (zona penilaian dan kotak penutup): null = jalan uji, `MedanKoran.dari_rute` di scene rute. Dipakai penilaian koran dan garis
## bidik dengan fungsi yang sama (prediksi = hasil).
var _medan: MedanKoran = null

@onready var _kamera: Camera2D = %Kamera
@onready var _tanah: TanahDaur = %Tanah
@onready var _sepeda: SepedaUji = %Sepeda
@onready var _kontrol: KontrolTouch = %KontrolTouch
@onready var _hud: HudDasar = %Hud
@onready var _layar_jeda: LayarJeda = %LayarJeda
@onready var _koran_tanah: KoranGambar = %KoranTanah
@onready var _koran_udara: KoranGambar = %KoranUdara
@onready var _garis_bidik: GarisBidik = %GarisBidik


func _ready() -> void:
	_hud.kidal_diubah.connect(atur_kidal)
	_hud.jeda_diminta.connect(minta_jeda)
	_hud.bantu_diubah.connect(atur_mode_bantu)
	_layar_jeda.lanjut_diminta.connect(minta_lanjut)
	_layar_jeda.kidal_diubah.connect(atur_kidal)
	_layar_jeda.bantu_diubah.connect(atur_mode_bantu)
	_kontrol.router.swipe_selesai.connect(_saat_swipe_selesai)
	_kontrol.router.tap_selesai.connect(_saat_tap_selesai)
	_kontrol.router.bel_ditekan.connect(_saat_bel_ditekan)
	_layar_jeda.tampilkan(false)
	_hud.atur_skor_tampil(_skor_aktif())
	_audio = get_node_or_null(^"/root/Audio") as SKRIP_AUDIO
	if _audio != null:
		jeda_berubah.connect(_audio.atur_jeda)
		koran_dilempar.connect(_bunyi_lempar)
	_siapkan_dunia()
	perbarui(0.0)


func _notification(what: int) -> void:
	_terapkan_jeda(JedaSim.peristiwa_dari_notifikasi(what))


func _exit_tree() -> void:
	# Scene keluar saat dijeda (mis. ganti scene atau tes selesai): pause pohon dilepas supaya tidak menahan scene lain.
	if _jeda:
		get_tree().paused = false
	if _audio != null:
		_audio.hentikan_sepeda()
		_audio.hentikan_lempar()


## Lemparan diterima: satu "wus" lewat `Audio` (D-11).
func _bunyi_lempar(_lintasan: ThrowSolver.Lintasan) -> void:
	_audio.putar_lempar()


## Koran mendarat: satu bunyi permukaan lewat `Audio`, dengan sakelar jendela yang sama dengan penilaian koran (D-10, D-11), nada combo dari
## urutan antaran beruntun (AC-18; 0 = nada dasar: jalan uji, tidak sah, ulang), lalu denting tip dan kilau tepat bila ada (AC-19).
func _bunyi_mendarat(koran_mendarat_ini: KoranLempar.Koran, hasil_skor: SkorRute.Hasil) -> void:
	if _audio == null:
		return
	var urutan: int = hasil_skor.urutan_beruntun if hasil_skor != null else 0
	_audio.putar_mendarat(koran_mendarat_ini.hasil, Config.JENDELA_KENA_BONUS, BunyiLempar.pitch_mendarat(urutan))
	if hasil_skor != null and hasil_skor.tip > 0:
		_audio.putar_tip()
	if hasil_skor != null and hasil_skor.tepat:
		_audio.putar_tepat()


## Tombol jeda di HUD: membuka layar jeda (tidak berpengaruh bila sudah jeda).
func minta_jeda() -> void:
	_terapkan_jeda(JedaSim.Peristiwa.JEDA)


## Tombol "Lanjut" di layar jeda: menutup layar jeda dan melanjutkan (langkah pertama ber-`dt` 0).
func minta_lanjut() -> void:
	_terapkan_jeda(JedaSim.Peristiwa.LANJUT)


## Menerapkan satu peristiwa jeda. Saat menjeda (juga bila sudah jeda): sepeda dijeda, jari dilepas, cincin rem padam. Saat status
## berubah: layar jeda tampil atau hilang, `SceneTree.paused` mengikuti, dan `jeda_berubah` dipancarkan.
func _terapkan_jeda(peristiwa_masuk: JedaSim.Peristiwa) -> void:
	if not is_node_ready():
		return
	var peristiwa: JedaSim.Peristiwa = _saring_jeda(peristiwa_masuk)
	if peristiwa == JedaSim.Peristiwa.TIDAK_ADA:
		return
	var jeda_baru: bool = JedaSim.jeda_sesudah(_jeda, peristiwa)
	_baru_lanjut = JedaSim.baru_lanjut_sesudah(_jeda, _baru_lanjut, peristiwa)
	var berubah: bool = jeda_baru != _jeda
	_jeda = jeda_baru
	if _jeda:
		_sepeda.jeda()
		_kontrol.lepas_semua()
		_kontrol.atur_rem(false)
		_garis_bidik.sembunyikan()
	if not berubah:
		return
	_layar_jeda.tampilkan(_jeda)
	if is_inside_tree():
		get_tree().paused = _jeda
	jeda_berubah.emit(_jeda)


func _process(delta: float) -> void:
	perbarui(minf(delta, Config.LANGKAH_WAKTU_MAKS_DETIK))


# --- Kait untuk adegan turunan (bawaan = tidak melakukan apa pun atau perilaku jalan uji) ---

## Dipanggil sekali di `_ready`, sesudah sinyal dihubungkan dan sebelum langkah pertama: menyusun dunia (rute, rumah) dan sisa koran awal.
func _siapkan_dunia() -> void:
	pass


## Dipanggil tiap langkah sesudah tanah digeser: memperbarui objek dunia untuk jarak tempuh sepeda `jarak_ubin`.
func _perbarui_dunia(_jarak_ubin: float) -> void:
	pass


## Zona sasaran mode bantu untuk titik mendarat dengan jarak maju dari `maju_awal_ubin` sampai `maju_akhir_ubin` (jangkauan lemparan).
func _zona_bantu(_maju_awal_ubin: float, _maju_akhir_ubin: float) -> Array[ZonaSasaran.Zona]:
	return []


## Sisa koran sesudah jeda antar lempar dimajukan `dt`: kait untuk alat uji (isi ulang jalan uji). Bawaan = tidak berubah.
func _langkah_koran(keadaan: SisaKoran.Keadaan) -> SisaKoran.Keadaan:
	return keadaan


## True bila scene ini menilai skor dan koin (bawaan false: jalan uji tidak punya id rumah).
func _skor_aktif() -> bool:
	return false


## Rute untuk pemberi tip `SkorRute.nilai_koran` (bawaan: rute kosong, tanpa pemberi tip).
func _rute_skor() -> RouteBuilder.Rute:
	return null


## Keadaan kondisi sepeda di awal rute (dan sesudah "Main lagi"). Bawaan null: jalan uji tidak punya aus, efek, atau HUD kondisi.
func _kondisi_awal() -> KondisiRute.Keadaan:
	return null


## True bila sepeda sudah melewati garis akhir: aus, kerusakan, dan peringatan berhenti. Bawaan false (jalan uji tanpa ujung).
func _kondisi_selesai() -> bool:
	return false


## Rintangan dunia di awal (dan sesudah "Main lagi"). Bawaan kosong (jalan uji).
func _rintangan_awal() -> RintanganRute.Keadaan:
	return RintanganRute.Keadaan.new()


## Vektor stick yang diberikan ke sepeda langkah ini (bawaan: kontrol touch atau keyboard di editor).
func _vektor_stick() -> Vector2:
	return _kontrol.vektor_stick()


## Dipanggil tiap langkah sebelum sepeda digerakkan: adegan turunan boleh mengganti keadaan gerak (rute: laju dijaga sesudah garis akhir, `AkhirRute.keadaan_dijaga`). Bawaan tidak mengubah apa pun.
func _siapkan_gerak() -> void:
	pass


## Jarak maju (ubin) yang dipakai tanah, jendela daur, dan dunia lain. Bawaan = jarak sepeda; rute membekukannya di garis akhir (G-5: tanah di belakang portal tetap tergambar, tanpa lubang).
func _jarak_dunia() -> float:
	return _sepeda.jarak_ubin


## False bila rintangan tidak lagi bergerak dan tidak bisa menabrak (rute sesudah garis akhir). Jam jatuh tabrakan yang sedang berjalan tetap maju. Bawaan true.
func _rintangan_aktif() -> bool:
	return true


## False bila bel tidak boleh berbunyi (rute sesudah garis akhir). Bawaan true.
func _bel_diizinkan() -> bool:
	return true


## True bila bunyi sepeda dimatikan (rute: layar hasil terbuka, sepeda sudah di luar layar). Bawaan false.
func _sepeda_senyap() -> bool:
	return false


## Membekukan kamera di posisi yang menaruh sepeda di titik pijak kamera (`AkhirRute.posisi_kamera`) dengan geseran dorongan saat ini; posisi dan geseran tidak berubah lagi sampai `_kembalikan_awal`.
## Dipanggil adegan turunan SEKALI saat garis akhir tercapai. Kamera langsung dipasang.
func _bekukan_kamera() -> void:
	_posisi_kamera_beku = AkhirRute.posisi_kamera(_sepeda.position, get_viewport_rect().size, _geser_dorongan)
	_kamera_beku = true
	_kamera.position = _posisi_kamera_beku


## False bila lemparan (swipe dan tap mode bantu) sedang tidak diterima, mis. sesudah akhir rute. Bawaan true.
func _lempar_diizinkan() -> bool:
	return true


## Dipanggil tiap langkah sesudah sepeda digerakkan, dengan `dt` efektif (0 saat jeda): jam tenggat rute. Bawaan tidak melakukan apa pun.
func _langkah_waktu(_langkah_dt: float) -> void:
	pass


## True bila tenggat rute sudah lewat saat ini (koran yang mendarat tidak memberi tip, K-1). Bawaan false (jalan uji tanpa tenggat).
func _tenggat_lewat() -> bool:
	return false


## Koran `k` baru dinilai (di scene yang menilai skor): hasil skornya `hasil_skor`. Bawaan tidak melakukan apa pun (rute memberi tahu `MissionManager`).
func _koran_dinilai(_k: KoranLempar.Koran, _hasil_skor: SkorRute.Hasil) -> void:
	pass


## Koin tambahan di luar skor rute yang ikut tampil di HUD (hadiah misi, K-1). Bawaan 0.
func _koin_tambahan() -> int:
	return 0


## Peristiwa jeda sesudah disaring adegan turunan (mis. back diabaikan di layar hasil). Bawaan apa adanya.
func _saring_jeda(peristiwa: JedaSim.Peristiwa) -> JedaSim.Peristiwa:
	return peristiwa


## Lintasan koran untuk swipe dari `awal` ke `akhir` (piksel game) dengan keadaan sepeda SAAT INI, atau null bila swipe tidak melempar.
## Satu-satunya panggilan lintasan di scene: garis bidik tiap langkah dan lemparan saat jari dilepas (D-4).
func lintasan_swipe(awal: Vector2, akhir: Vector2) -> ThrowSolver.Lintasan:
	var lebar: float = get_viewport_rect().size.x
	var sisi: LoperAnim.Sisi = ThrowSolver.sisi_dari_swipe(awal, akhir, lebar)
	if sisi == LoperAnim.Sisi.TIDAK_ADA:
		return null
	return ThrowSolver.dari_swipe(awal, akhir, lebar, _sepeda.posisi_dunia(), _sepeda.kecepatan_ud, _sepeda.lateral_ud, _sepeda.jeda_lepas(sisi))


## Satu swipe selesai (jari dilepas): lempar bila diizinkan (D-8, D-9) dan panjang swipe di posisi lepas |v_lepas| >= min (D-5 run
## fase2-arah-bebas; arah posisi lepas tidak menentukan apa pun). Lintasan = garis bidik yang sedang tampil untuk swipe ini
## (`lintasan_bidik_tampil`); tanpa garis bidik tampil, dihitung dari posisi lepas. Ditolak = koran tidak berkurang dan jeda tidak mulai
## ulang. Garis bidik selalu hilang saat jari dilepas.
func _saat_swipe_selesai(awal: Vector2, akhir: Vector2, _durasi_detik: float) -> void:
	var bidik: ThrowSolver.Lintasan = lintasan_bidik_tampil(_kontrol.router.nomor_swipe)
	_garis_bidik.sembunyikan()
	if not _lempar_terbuka() or not SisaKoran.boleh_lempar(koran):
		return
	if not ThrowSolver.cukup_panjang(ThrowSolver.panjang_swipe(awal, akhir), get_viewport_rect().size.x):
		return
	var lintasan: ThrowSolver.Lintasan = bidik if bidik != null else lintasan_swipe(awal, akhir)
	if lintasan == null:
		return
	_lempar(lintasan)


## Satu tap di zona swipe selesai (D-1): di mode bantu, lempar otomatis ke kotak surat pelanggan terdekat di depan pada sisi tap (D-3 sampai
## D-6). Di luar mode bantu tidak melakukan apa pun. Gerbang sama dengan swipe; tanpa sasaran = tanda di titik tap, koran dan jeda tetap.
func _saat_tap_selesai(posisi: Vector2, _durasi_detik: float) -> void:
	if not _mode_bantu or not _lempar_terbuka() or not SisaKoran.boleh_lempar(koran):
		return
	var pilihan: BantuLempar.Pilihan = pilihan_bantu(BantuLempar.sisi_tap(posisi, posisi_layar_sepeda()))
	if pilihan == null:
		_kontrol.tampilkan_tanda(posisi)
		bantu_tanpa_sasaran.emit(posisi)
		return
	_lempar(pilihan.lintasan, true)


## True bila lemparan (swipe dan tap mode bantu) boleh sekarang: tidak jeda, kait `_lempar_diizinkan` (mis. belum lewat akhir rute), dan
## pemain tidak sedang jatuh sesudah tabrakan (keputusan pemilik 2026-10-17).
func _lempar_terbuka() -> bool:
	return not _jeda and _lempar_diizinkan() and not Tabrakan.jatuh(_rintangan.tabrakan)


## Gerbang terakhir dan langkah sesudahnya, sama untuk swipe dan tap (D-5): `SisaKoran.terima`; diterima = koran -1, koran terbang dengan
## lintasan beku, animasi lempar ke sisi lintasan, HUD, dan `koran_dilempar`. Ditolak = tidak ada yang berubah. True bila diterima.
## `bantu` true untuk tap mode bantu (koran bantu tidak pernah tepat, O-4).
func _lempar(lintasan: ThrowSolver.Lintasan, bantu: bool = false) -> bool:
	var hasil: SisaKoran.Hasil = SisaKoran.terima(koran, _sepeda.jarak_ubin)
	koran = hasil.keadaan
	if not hasil.diterima:
		return false
	_terbang.append(KoranLempar.baru(lintasan, bantu))
	_sepeda.lempar(lintasan.sisi)
	_hud.tampilkan_koran(koran.sisa, koran.penuh)
	koran_dilempar.emit(lintasan)
	return true


## Sasaran lemparan mode bantu untuk tap ke `sisi` dari keadaan sepeda langkah terakhir (posisi dunia, kecepatan maju sebenarnya, kecepatan
## lateral efektif, jeda lepas animasi sisi itu), atas zona jalan uji dari posisi sepeda sampai jangkauan lemparan; null bila tidak ada.
func pilihan_bantu(sisi: LoperAnim.Sisi) -> BantuLempar.Pilihan:
	if sisi == LoperAnim.Sisi.TIDAK_ADA:
		return null
	var posisi: Vector2 = _sepeda.posisi_dunia()
	var jeda_lepas: float = _sepeda.jeda_lepas(sisi)
	var maju: float = -posisi.y
	var zona: Array[ZonaSasaran.Zona] = _zona_bantu(maju, maju + BantuLempar.jangkauan_maju_ubin(_sepeda.kecepatan_ud, jeda_lepas))
	return BantuLempar.pilih(sisi, posisi, _sepeda.kecepatan_ud, _sepeda.lateral_ud, jeda_lepas, get_viewport_rect().size.x, zona)


## Titik pijak sepeda di layar, koordinat viewport game (sama dengan koordinat sentuhan): posisi gambar sepeda dikurangi pojok kiri atas
## kamera (kamera di tengah layar, tanpa zoom). Garis pemisah sisi tap mode bantu melewati titik ini (D-3).
func posisi_layar_sepeda() -> Vector2:
	return _sepeda.global_position - _kamera.position + get_viewport_rect().size / 2


## Menyalakan atau mematikan mode bantu (sakelar layar jeda O-6, atau sakelar HUD dev jalan uji, D-7). Sakelar HUD dan layar jeda ikut
## disamakan.
func atur_mode_bantu(nilai: bool) -> void:
	_mode_bantu = nilai
	_hud.atur_bantu(nilai)
	_layar_jeda.atur_bantu(nilai)


## Menyalakan atau mematikan opsi kidal (sakelar layar jeda O-6, atau sakelar HUD dev jalan uji): zona kontrol ditukar (`KontrolTouch`),
## panel bawah dan tombol bel HUD dicerminkan, sakelar layar jeda disamakan, dan zona tap bel ikut tombolnya.
func atur_kidal(nilai: bool) -> void:
	_kontrol.atur_kidal(nilai)
	_hud.atur_kidal(nilai)
	_layar_jeda.atur_kidal(nilai)
	_kontrol.router.geser_bel = _hud.geser_bel()


## True selama opsi kidal menyala.
func kidal() -> bool:
	return _kontrol.router.kidal()


## True selama mode bantu menyala.
func mode_bantu() -> bool:
	return _mode_bantu


## Lintasan garis bidik yang sedang tampil bila dihitung untuk swipe bernomor `nomor` (`TouchRouter.nomor_swipe`), atau null (tidak
## tampil, atau sisa garis bidik swipe lain yang dibatalkan sebelum langkah berikutnya menyembunyikannya).
func lintasan_bidik_tampil(nomor: int) -> ThrowSolver.Lintasan:
	if not _garis_bidik.tampil() or _bidik_nomor != nomor:
		return null
	return _garis_bidik.lintasan()


## Koran yang sedang dilempar (terbang atau penandanya masih tampil), urut dari yang pertama dilempar. Untuk tes dan probe.
func koran_terbang() -> Array[KoranLempar.Koran]:
	return _terbang


## Garis bidik di ruang dunia (untuk tes dan probe).
func garis_bidik() -> GarisBidik:
	return _garis_bidik


## Pelacak jari kontrol sentuh (untuk tes dan probe).
func kontrol_router() -> TouchRouter:
	return _kontrol.router


## Satu langkah permainan selama `dt` detik. Publik supaya tes terpadu bisa menjalankannya tanpa menunggu frame. Selama jeda
## dan pada langkah pertama sesudah lanjut `dt` diganti 0 (`JedaSim.dt_efektif`).
func perbarui(dt: float) -> void:
	var langkah_dt: float = JedaSim.dt_efektif(_jeda, _baru_lanjut, dt)
	if not _jeda:
		_baru_lanjut = false
	_siapkan_gerak()
	var gerak: BikeMotion.Hasil = _sepeda.gerak(_vektor_stick(), langkah_dt, _rintangan.tabrakan.jatuh_detik, _kondisi.efek if _kondisi != null else null)
	_langkah_waktu(langkah_dt)
	var tabrak: Tabrakan.Hasil = _langkah_rintangan(langkah_dt)
	_langkah_kondisi(gerak, langkah_dt, tabrak)
	_bel = Bel.langkah(_bel, langkah_dt)
	_putus_detik = maxf(_putus_detik - langkah_dt, 0.0) if is_finite(langkah_dt) and langkah_dt > 0.0 else _putus_detik
	_umpan = UmpanMelayang.langkah(_umpan, langkah_dt)
	_perbarui_lemparan(langkah_dt)
	_kontrol.langkah_tanda(langkah_dt)
	_tanah.perbarui(_jarak_dunia())
	_perbarui_dunia(_jarak_dunia())
	_hud.tampilkan_kecepatan(_sepeda.kecepatan_ud)
	_hud.tampilkan_stamina(_sepeda.stamina(), _sepeda.lelah())
	_kontrol.atur_rem(_sepeda.rem_aktif())
	_sepeda.tampilkan_tabrakan(_rintangan.tabrakan)
	_sepeda.tampilkan_bel(_bel)
	_hud.tampilkan_skor(_skor.skor, _skor.beruntun, _koin_tampil(), putus_tampil())
	_hud.tampilkan_kondisi(_kondisi)
	_hud.tampilkan_bel(_kontrol.router.bel_ditahan(), Bel.sisa_jeda_pecahan(_bel))
	_kontrol.router.geser_bel = _hud.geser_bel()
	if _audio != null:
		var senyap: bool = _sepeda_senyap()
		_audio.perbarui_sepeda(_sepeda.pose(), 0.0 if senyap else _sepeda.kecepatan_ud, _sepeda.rem_aktif() and not senyap, _jeda)
	if _kamera_beku:
		_kamera.position = _posisi_kamera_beku
		return
	_geser_dorongan = DoronganKecepatan.haluskan(_geser_dorongan, DoronganKecepatan.geser_target(_sepeda.kecepatan_ud), langkah_dt)
	_kamera.position = posisi_kamera()


## Langkah lemparan sesudah sepeda digerakkan: jeda antar lempar, kait koran (isi ulang uji), koran terbang dan mendarat, lalu garis bidik dari
## keadaan sepeda yang baru (bukan keadaan frame sebelumnya).
func _perbarui_lemparan(langkah_dt: float) -> void:
	koran = _langkah_koran(SisaKoran.langkah(koran, langkah_dt))
	if not _terbang.is_empty():
		var sisa: Array[KoranLempar.Koran] = []
		for lama: KoranLempar.Koran in _terbang:
			var baru: KoranLempar.Koran = KoranLempar.langkah(lama, langkah_dt, Config.JENDELA_KENA_BONUS, _medan)
			if baru.mendarat and not lama.mendarat:
				_saat_koran_mendarat(baru)
			if not KoranLempar.selesai(baru):
				sisa.append(baru)
		_terbang = sisa
	_koran_tanah.tampilkan(_terbang)
	_koran_udara.tampilkan(_terbang)
	_hud.tampilkan_koran(koran.sisa, koran.penuh)
	var router: TouchRouter = _kontrol.router
	if _lempar_terbuka() and router.swipe_aktif() and SisaKoran.boleh_lempar(koran):
		var lintasan: ThrowSolver.Lintasan = lintasan_swipe(router.awal_swipe(), router.posisi_swipe())
		if lintasan != null:
			_garis_bidik.tampilkan(lintasan, KoranLempar.bentuk_elips(lintasan, Config.JENDELA_KENA_BONUS, _medan), _medan)
			_bidik_nomor = router.nomor_swipe
			return
	_garis_bidik.sembunyikan()


## Satu langkah rintangan sesudah sepeda digerakkan (urutan di atas): peristiwa ke bunyi; tabrakan baru diterapkan ke sepeda, combo putus,
## bunyi, dan sinyal `tabrakan`. Mengembalikan `Tabrakan.Hasil` langkah ini bila ada tabrakan baru (masukan kerusakan kondisi), selain itu null.
func _langkah_rintangan(langkah_dt: float) -> Tabrakan.Hasil:
	if not _rintangan_aktif():
		# Rintangan membeku di keadaan terakhirnya dan tidak bisa menabrak; hanya jam jatuh yang sedang berjalan tetap maju (sepeda bangun, lalu melaju lagi).
		var beku: RintanganRute.Keadaan = RintanganRute.Keadaan.new()
		beku.daftar = _rintangan.daftar
		beku.tabrakan = Tabrakan.langkah(_rintangan.tabrakan, Tabrakan.kotak_sepeda(_sepeda.jarak_ubin, _sepeda.lateral_ubin), [], langkah_dt).keadaan
		_rintangan = beku
		return null
	var hr: RintanganRute.Hasil = RintanganRute.langkah(_rintangan, _sepeda.jarak_ubin, _sepeda.lateral_ubin, _sepeda.kecepatan_ud, langkah_dt)
	_rintangan = hr.keadaan
	if _audio != null:
		for k: RintanganRute.Kejadian in hr.kejadian:
			_audio.putar_peristiwa(k.peristiwa)
	if not hr.tabrak:
		return null
	_sepeda.tabrak()
	_putus_combo()
	if _audio != null:
		_audio.putar_tabrakan()
	tabrakan.emit(hr.jenis_tabrak)
	var hasil: Tabrakan.Hasil = Tabrakan.Hasil.new()
	hasil.keadaan = hr.keadaan.tabrakan
	hasil.tabrak = true
	hasil.id = hr.id_tabrak
	hasil.jenis = hr.jenis_tabrak
	return hasil


## Satu langkah kondisi sepeda sesudah gerak dan tabrakan langkah ini (tidak melakukan apa pun di jalan uji): aus, kerusakan tabrakan, dan peringatan (`KondisiRute.langkah`). Setiap
## peristiwa peringatan membunyikan `Audio.putar_kondisi_peringatan` dan memancarkan `peringatan_kondisi`; visualnya (ikon bergetar, kotak WARN) dari `KondisiRute.Keadaan.kedip` di HUD.
func _langkah_kondisi(gerak: BikeMotion.Hasil, langkah_dt: float, tabrak: Tabrakan.Hasil) -> void:
	if _kondisi == null:
		return
	var hasil: KondisiRute.Hasil = KondisiRute.langkah(_kondisi, gerak, langkah_dt, tabrak, _kondisi_selesai())
	_kondisi = hasil.keadaan
	for komponen: String in hasil.peringatan:
		if _audio != null:
			_audio.putar_kondisi_peringatan(Config.KONDISI_KOMPONEN.find(komponen))
		peringatan_kondisi.emit(komponen)


## Combo putus (tabrakan atau antaran tidak sah): rangkaian kembali 0; label PUTUS tampil bila ada rangkaian yang putus.
func _putus_combo() -> void:
	if _skor.beruntun > 0:
		_putus_detik = Config.HUD_COMBO_PUTUS_DETIK
	_skor = SkorRute.putus_combo(_skor)


## Koran `k` (objek baru langkah ini) baru mendarat: dinilai skor bila scene menilai skor (penanda ditimpa penanda skor, umpan balik
## melayang), lalu `koran_mendarat`, `skor_dinilai`, dan bunyi.
func _saat_koran_mendarat(k: KoranLempar.Koran) -> void:
	var hs: SkorRute.Hasil = null
	if _skor_aktif():
		hs = SkorRute.nilai_koran(_skor, k, _rute_skor(), Config.JENDELA_KENA_BONUS, _tenggat_lewat())
		if hs.status == SkorRute.Status.TIDAK_SAH and _skor.beruntun > 0:
			_putus_detik = Config.HUD_COMBO_PUTUS_DETIK
		_skor = hs.keadaan
		k.penanda = hs.penanda
		_umpan = UmpanMelayang.tambah(_umpan, UmpanMelayang.dari_hasil(hs, k.lintasan.titik_mendarat))
		if SkorRute.hasil_terbuang(hs):
			_umpan = UmpanMelayang.tambah(_umpan, UmpanMelayang.dari_potongan(Config.KOIN_POTONGAN_KORAN_MELESET, k.lintasan.titik_mendarat))
	koran_mendarat.emit(k)
	if hs != null:
		skor_dinilai.emit(hs)
	_koran_dinilai(k, hs)
	_bunyi_mendarat(k, hs)


## Jari turun di zona bel (`TouchRouter.bel_ditekan`).
func _saat_bel_ditekan(_posisi: Vector2) -> void:
	ketuk_bel()


## Satu ketukan bel (tombol, juga dipanggil tes): `Bel.ketuk` dengan status jeda game; bila berbunyi: bunyi bel, rintangan dalam jangkauan
## bereaksi (`RintanganRute.terapkan_bel`), dan `bel_berbunyi`. Hasil ketukan dikembalikan.
func ketuk_bel() -> Bel.Bunyi:
	if not _bel_diizinkan():
		return Bel.Bunyi.TOLAK
	var hb: Bel.Hasil = Bel.ketuk(_bel, _jeda)
	_bel = hb.keadaan
	if not Bel.berbunyi(hb.bunyi):
		return hb.bunyi
	if _audio != null:
		_audio.putar_bel(hb.bunyi)
	var reaksi: RintanganRute.HasilBel = RintanganRute.terapkan_bel(_rintangan, _sepeda.jarak_ubin)
	_rintangan = reaksi.keadaan
	_sepeda.tampilkan_bel(_bel)
	bel_berbunyi.emit(hb.bunyi, reaksi.bereaksi)
	return hb.bunyi


## Keadaan rintangan dan tabrakan saat ini (untuk tes dan probe).
func rintangan() -> RintanganRute.Keadaan:
	return _rintangan


## Keadaan kondisi sepeda saat ini (null di jalan uji; untuk tes, probe, dan layar hasil).
func kondisi() -> KondisiRute.Keadaan:
	return _kondisi


## Mengganti keadaan kondisi sepeda (hanya untuk tes dan probe: mis. komponen hampir aus tanpa menjalankan belasan rute). HUD ikut diperbarui.
func atur_kondisi(k: KondisiRute.Keadaan) -> void:
	_kondisi = k
	if is_node_ready():
		_hud.tampilkan_kondisi(_kondisi)


## Koin bersih hari berjalan untuk HUD (O-3): koin kotor + hadiah misi - potongan koran terbuang; boleh negatif.
func _koin_tampil() -> int:
	return _skor.koin + _koin_tambahan() - SkorRute.potongan(_skor)


## Keadaan skor saat ini (untuk tes dan probe).
func skor() -> SkorRute.Keadaan:
	return _skor


## Keadaan bel saat ini (untuk tes dan probe).
func bel() -> Bel.Keadaan:
	return _bel


## Umpan balik melayang yang sedang tampil (untuk tes dan probe).
func umpan_melayang() -> Array[UmpanMelayang.Entri]:
	return _umpan


## True selama label PUTUS tampil.
func putus_tampil() -> bool:
	return _putus_detik > Config.TABRAKAN_TOLERANSI_DETIK


## Mengembalikan adegan ke keadaan awal tanpa memuat ulang scene ("Main lagi", run fase3a-rute): sepeda di awal (jarak 0, kecepatan santai,
## stamina penuh), sisa koran `koran_awal` dengan jeda antar lempar belum berjalan, koran terbang dibuang, garis bidik dan jari dilepas,
## dan geseran dorongan kamera nol. Status jeda tidak diubah.
func _kembalikan_awal(koran_awal: int) -> void:
	_sepeda.atur_ulang()
	_rintangan = _rintangan_awal()
	_kondisi = _kondisi_awal()
	_skor = SkorRute.awal()
	_bel = Bel.awal()
	_putus_detik = 0.0
	_umpan = []
	if _audio != null:
		_audio.atur_ulang_rute()
	koran = SisaKoran.awal(koran_awal)
	_terbang = []
	_bidik_nomor = -1
	_garis_bidik.sembunyikan()
	_kontrol.lepas_semua()
	_kontrol.atur_rem(false)
	_geser_dorongan = Vector2.ZERO
	_kamera_beku = false
	_koran_tanah.tampilkan(_terbang)
	_koran_udara.tampilkan(_terbang)
	_hud.tampilkan_koran(koran.sisa, koran.penuh)
	_sepeda.tampilkan_tabrakan(_rintangan.tabrakan)
	_sepeda.tampilkan_bel(_bel)
	_hud.tampilkan_skor(_skor.skor, _skor.beruntun, _koin_tampil(), false)
	_hud.tampilkan_kondisi(_kondisi)
	_hud.tampilkan_bel(false, 0.0)


## True selama layar jeda terbuka (simulasi, sprite, partikel, dan input berhenti).
func sedang_jeda() -> bool:
	return _jeda


## Geseran sepeda di layar akibat dorongan kecepatan (sudah dihaluskan), piksel game; nol di kecepatan santai.
func geser_dorongan() -> Vector2:
	return _geser_dorongan


## True selama kamera beku di garis akhir (tidak mengikuti sepeda lagi).
func kamera_beku() -> bool:
	return _kamera_beku


## Posisi kamera supaya sepeda jatuh di `KAMERA_SEPEDA_*_PECAHAN` viewport ditambah geseran dorongan kecepatan,
## dibulatkan ke piksel (tidak ada sub-piksel dan tidak ada zoom).
func posisi_kamera() -> Vector2:
	var ukuran: Vector2 = get_viewport_rect().size
	var sasaran: Vector2 = Vector2(ukuran.x * Config.KAMERA_SEPEDA_X_PECAHAN, ukuran.y * Config.KAMERA_SEPEDA_Y_PECAHAN)
	return (_sepeda.position + ukuran / 2 - (sasaran + _geser_dorongan)).round()
