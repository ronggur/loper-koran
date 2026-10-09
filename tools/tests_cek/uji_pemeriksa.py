#!/usr/bin/env python3
"""Bukti bahwa `tools/cek_keluaran_tes.py` benar-benar menolak log yang buruk. Hanya pustaka standar.

Menjalankan pemeriksa terhadap contoh log di folder ini dan membandingkan exit code dengan yang
diharapkan. `baik.log` adalah keluaran asli `run_tests.gd`; log `buruk_*.log` dibuat dengan
menyisipkan baris yang meniru keluaran Godot (SCRIPT ERROR, ERROR:, GAGAL, ringkasan salah).

Cara pakai (dari root repo):
    python3 tools/tests_cek/uji_pemeriksa.py

Exit code: 0 bila semua kasus sesuai harapan, 1 bila ada yang menyimpang.
"""
import os
import subprocess
import sys

FOLDER = os.path.dirname(os.path.abspath(__file__))
PEMERIKSA = os.path.join(FOLDER, "..", "cek_keluaran_tes.py")

# (berkas log, argumen tambahan, exit code yang diharapkan, keterangan)
KASUS = [
    ("baik.log", [], 0, "keluaran asli run_tests.gd tanpa masalah"),
    ("peringatan.log", [], 0, "WARNING saja: lolos tanpa --ketat"),
    ("peringatan.log", ["--ketat"], 1, "WARNING saja: gagal dengan --ketat"),
    ("buruk_script_error.log", [], 1, "SCRIPT ERROR walau ringkasan '0 gagal'"),
    ("buruk_error.log", [], 1, "baris ERROR: walau ringkasan '0 gagal'"),
    ("buruk_error_berwarna.log", [], 1, "ERROR: dengan kode warna ANSI"),
    ("buruk_gagal.log", [], 1, "baris GAGAL dan ringkasan 1 gagal"),
    ("buruk_gagal_ringkasan_lolos.log", [], 1, "baris GAGAL walau ringkasan '0 gagal'"),
    ("buruk_ringkasan_gagal.log", [], 1, "ringkasan 'N lolos, M gagal' dengan M > 0"),
    ("buruk_tanpa_ringkasan.log", [], 1, "tanpa baris ringkasan (tes berhenti di tengah)"),
    ("buruk_ringkasan_nol.log", [], 1, "ringkasan '0 lolos' (tidak ada tes berjalan)"),
    ("buruk_ringkasan_ganda.log", [], 1, "dua baris ringkasan"),
    ("buruk_crash.log", [], 1, "tanda crash Godot"),
    ("kosong.log", [], 1, "log kosong"),
    ("tidak_ada.log", [], 2, "berkas tidak ada = salah pakai (exit 2)"),
]


def jalankan(argumen, masukan=None):
    return subprocess.run(
        [sys.executable, "-I", PEMERIKSA] + argumen,
        input=masukan,
        capture_output=True,
        text=True,
    )


def main():
    menyimpang = 0
    for nama, tambahan, diharapkan, ket in KASUS:
        hasil = jalankan([os.path.join(FOLDER, nama)] + tambahan)
        sesuai = hasil.returncode == diharapkan
        menyimpang += 0 if sesuai else 1
        print("%s  %s %s -> exit %d (harapan %d)  [%s]" % (
            "sesuai  " if sesuai else "MENYIMPANG", nama, " ".join(tambahan), hasil.returncode, diharapkan, ket))
    # Mode stdin: log buruk lewat pipa tetap ditolak.
    with open(os.path.join(FOLDER, "buruk_script_error.log"), encoding="utf-8") as f:
        hasil = jalankan(["-"], masukan=f.read())
    sesuai = hasil.returncode == 1
    menyimpang += 0 if sesuai else 1
    print("%s  stdin buruk_script_error.log -> exit %d (harapan 1)" % ("sesuai  " if sesuai else "MENYIMPANG", hasil.returncode))
    print("uji pemeriksa: %d kasus, %d menyimpang" % (len(KASUS) + 1, menyimpang))
    return 1 if menyimpang else 0


if __name__ == "__main__":
    sys.exit(main())
