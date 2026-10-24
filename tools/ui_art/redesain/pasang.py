"""Daftar aset redesain UI yang DIPASANG ke assets/sprites/ui/ (run ui1-komponen-bengkel, diperluas run ui2-semua-layar bagian A untuk layar hasil dan bagian B untuk halaman koran; usulan).

Satu sumber untuk `komponen.py --salin`, `sepeda_fullbody.py --salin`, `latar_bengkel.py --salin`, dan
`tools/tests_cek/uji_ui_redesain.py`. HANYA yang dipakai layar yang sudah dipasang (komponen bersama, bengkel tata C, layar hasil struk);
aset lain di docs/design/redesain/aset/ (koran, foto, panel_hud, sepeda_besar, ikon dan glif yang
belum dipakai) belum dipasang dan dipasang oleh run layar yang memakainya. Isi daftar diputuskan dari papan kanvas
Bengkel*.dc.html dan Spesifikasi.dc.html (lihat LOG run).

Tidak mengimpor pustaka apa pun (hanya data), supaya bisa dibaca skrip mana pun tanpa pillow.
"""

# --- dari komponen.py (keluaran build/ui_art/redesain/<nama>.png), nama sumber -> nama di assets/sprites/ui/ ---
# Tombol empat peran (utama, biasa, sakelar, tenang) + nonaktif; `_tekan` = wajah turun 2 px. Sakelar mati memakai btn_biasa.
TOMBOL: dict[str, str] = {
    'btn_utama': 'ui_btn_utama',
    'btn_utama_tekan': 'ui_btn_utama_tekan',
    'btn_biasa': 'ui_btn_biasa',
    'btn_biasa_tekan': 'ui_btn_biasa_tekan',
    'btn_sakelar_nyala': 'ui_btn_sakelar_nyala',
    'btn_tenang': 'ui_btn_tenang',
    'btn_tenang_tekan': 'ui_btn_tenang_tekan',
    'btn_nonaktif': 'ui_btn_nonaktif',
    'arsir_nonaktif': 'ui_arsir_nonaktif',
}
# Panel layar penuh, tiga kartu, lima chip (panel_hud sudah ada sebagai ui_panel_hud_9slice.png, tidak dipasang ulang).
PANEL: dict[str, str] = {
    'panel_layar': 'ui_panel_layar',
    'kartu_biasa': 'ui_kartu_biasa',
    'kartu_menonjol': 'ui_kartu_menonjol',
    'kartu_redup': 'ui_kartu_redup',
    'chip_gelap': 'ui_chip_gelap',
    'chip_ok': 'ui_chip_ok',
    'chip_warn': 'ui_chip_warn',
    'chip_netral': 'ui_chip_netral',
    'chip_aksen': 'ui_chip_aksen',
    # Layar hasil (run ui2-semua-layar bagian A): struk 9-slice bergerigi (tepi atas dan bawah) dan takik tiket di garis sobek (dicerminkan untuk sisi kanan).
    'struk': 'ui_struk',
    'struk_takik': 'ui_struk_takik',
}
# Halaman koran (run ui2-semua-layar bagian B): kotak misi 9-slice garis ganda, tiga tombol tinta (Berangkat, Berangkat ditekan, Ambil/Lewati tipis, terpilih berongga), tekstur titik kertas, dan dua foto berita tinta dua nada.
# Foto per efek berita utama baru dua ("jalan dan lampu dulu", Spesifikasi.dc.html).
KORAN: dict[str, str] = {
    'koran_kotak': 'ui_koran_kotak',
    'koran_btn_tinta': 'ui_koran_btn_tinta',
    'koran_btn_tinta_tekan': 'ui_koran_btn_tinta_tekan',
    'koran_btn_tipis': 'ui_koran_btn_tipis',
    'koran_btn_terpilih': 'ui_koran_btn_terpilih',
    'kertas_tile': 'ui_kertas_tile',
    'foto_jalan': 'ui_foto_jalan',
    'foto_lampu': 'ui_foto_lampu',
}
# Papan alat bengkel (latar panel sepeda).
PAPAN: dict[str, str] = {'papan_alat': 'ui_bengkel_papan_alat'}
# Ikon 24x24 yang dipakai bengkel (potongan sel dari sheet ikon24): kartu servis dan kartu upgrade.
IKON24: dict[str, str] = {
    'ban': 'ui_icon24_ban',
    'rem': 'ui_icon24_rem',
    'rantai': 'ui_icon24_rantai',
    # Layar hasil: koin di samping angka Koin 32 px, bintang kartu reputasi, lencana tingkat baru tercapai.
    'koin': 'ui_icon24_koin',
    'bintang': 'ui_icon24_bintang',
    'lencana_perunggu': 'ui_icon24_lencana_perunggu',
    'lencana_perak': 'ui_icon24_lencana_perak',
    'lencana_emas': 'ui_icon24_lencana_emas',
    # Halaman koran: kucing (judul kotak misi), kerucut dan bohlam (ikon efek berita utama jalan diperbaiki dan mati lampu).
    'kucing': 'ui_icon24_kucing',
    'kerucut': 'ui_icon24_kerucut',
    'bohlam': 'ui_icon24_bohlam',
}
# Lencana milestone 32x32 (potongan sel dari sheet lencana32, urutan perunggu, perak, emas): target berikutnya di layar hasil. Sel "belum" tidak dipasang (tidak dipakai).
LENCANA32: dict[str, str] = {
    'perunggu': 'ui_lencana32_perunggu',
    'perak': 'ui_lencana32_perak',
    'emas': 'ui_lencana32_emas',
}
# Glif 12x12 yang dipakai bengkel: (nama glif, warna baris sheet) -> nama berkas. Warna sudah tertanam (sheet glif12 satu baris per warna).
GLIF12: dict[tuple[str, str], str] = {
    ('seru', 'warn'): 'ui_glif_seru_warn',          # tanda PERLU SERVIS, catatan ongkos x1,25, galat data
    ('centang', 'ok'): 'ui_glif_centang_ok',        # chip "Baik"
    ('centang', 'teks2'): 'ui_glif_centang_teks2',  # chip "Dimiliki"
    ('kunci', 'terang'): 'ui_glif_kunci_terang',    # tombol "Servis"
    ('panah', 'gelap'): 'ui_glif_panah_gelap',      # tombol "Hari berikutnya"
    ('naik', 'ok'): 'ui_glif_naik_ok',              # chip perubahan reputasi naik (layar hasil)
    ('turun', 'teks2'): 'ui_glif_turun_teks2',      # chip perubahan reputasi turun atau nol (layar hasil)
    ('centang', 'gelap'): 'ui_glif_centang_gelap',  # tombol Ambil/Lewati terpilih (koran)
    ('panah', 'terang'): 'ui_glif_panah_terang',    # tombol Berangkat (koran, di atas tinta)
    ('seru', 'tinta2'): 'ui_glif_seru_tinta2',      # kotak notifikasi save (koran)
}

# --- disalin apa adanya dari keluaran resmi di docs/ (tidak dibuat ulang): (folder docs relatif root, nama sumber) -> nama tujuan ---
# sepeda_besar tidak dipasang (kanvas bengkel hanya memakai sepeda_kecil). Latar 640 tidak dipasang: kanvas memakai latar 800
# di tengah (bgx = (lebar - 800) / 2), jadi satu berkas 800 melayani lebar 640..800; versi 640 = potongan tengahnya.
SEPEDA: dict[str, str] = {
    'sepeda_kecil.png': 'ui_bengkel_sepeda_kecil.png',
    'sepeda.json': 'ui_bengkel_sepeda.json',
}
FOLDER_SEPEDA = 'docs/design/redesain/aset'
LATAR: dict[str, str] = {'bengkel_latar_800.png': 'ui_bengkel_latar_800.png'}
FOLDER_LATAR = 'docs/design/redesain/latar_bengkel'

# Awalan nama berkas redesain di assets/sprites/ui/: berkas berawalan ini HARUS ada di daftar (set tepat).
AWALAN = ('ui_btn_', 'ui_arsir_', 'ui_panel_layar', 'ui_kartu_', 'ui_chip_', 'ui_icon24_', 'ui_glif_', 'ui_bengkel_', 'ui_struk', 'ui_lencana32_', 'ui_koran_', 'ui_kertas_', 'ui_foto_')


def nama_komponen() -> list[str]:
    """Nama berkas PNG (dengan .png) hasil komponen.py yang dipasang, terurut."""
    semua = list(TOMBOL.values()) + list(PANEL.values()) + list(KORAN.values()) + list(PAPAN.values()) + list(IKON24.values()) + list(LENCANA32.values()) + list(GLIF12.values())
    return sorted(n + '.png' for n in semua)


def nama_semua() -> list[str]:
    """Semua nama berkas redesain yang dipasang di assets/sprites/ui/ (PNG dan JSON), terurut."""
    return sorted(nama_komponen() + list(SEPEDA.values()) + list(LATAR.values()))
