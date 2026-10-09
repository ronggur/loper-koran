#!/usr/bin/env python3
"""Pemeriksa keluaran tes Godot (rule `testing`). Hanya pustaka standar Python 3.

Exit code Godot TIDAK cukup: error skrip saat runtime (`SCRIPT ERROR`) menghentikan fungsi tes
di tengah jalan, tetapi ringkasan tetap mencetak "0 gagal" dan exit code tetap 0. Skrip ini
membaca keluaran yang ditangkap dengan `tee` dan menolak log yang memuat salah satu dari:

  - `SCRIPT ERROR` di baris mana pun;
  - baris berawalan `ERROR:` (juga `USER ERROR:` dan `USER SCRIPT ERROR:`);
  - baris yang memuat `GAGAL` (format kegagalan tes: `GAGAL: <label>`);
  - tanda crash Godot (`handle_crash`, `Program crashed`);
  - tanpa baris ringkasan `N lolos, 0 gagal`, ringkasan ganda, `N lolos, M gagal` dengan M > 0,
    atau ringkasan `0 lolos` (tidak ada tes yang berjalan).

Baris berawalan `WARNING:` dilaporkan sebagai peringatan dan baru menggagalkan dengan `--ketat`.
Kode warna ANSI dibuang dulu sebelum dicocokkan.

Cara pakai:

    godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log
    python3 tools/cek_keluaran_tes.py build/tests.log            # tambah --ketat untuk peringatan
    python3 tools/cek_keluaran_tes.py -                          # baca dari stdin

Exit code: 0 lolos, 1 ada masalah di log, 2 salah pakai (berkas tidak bisa dibaca).
Bukti pemeriksa sendiri: `python3 tools/tests_cek/uji_pemeriksa.py` (contoh log baik dan buruk).
"""
import argparse
import re
import sys

ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")
RINGKASAN = re.compile(r"^(\d+) lolos, (\d+) gagal$")
BARIS_ERROR = re.compile(r"^\s*(?:USER (?:SCRIPT )?)?ERROR:")
BARIS_PERINGATAN = re.compile(r"^\s*(?:USER )?WARNING:")
TANDA_CRASH = re.compile(r"handle_crash|Program crashed")


def periksa(teks, ketat=False):
    """Mengembalikan (masalah, peringatan, ringkasan) untuk teks log.

    `masalah` dan `peringatan` adalah daftar teks; `ringkasan` = (lolos, gagal) atau None.
    """
    masalah = []
    peringatan = []
    ringkasan = []
    for nomor, mentah in enumerate(teks.splitlines(), start=1):
        baris = ANSI.sub("", mentah).rstrip()
        if "SCRIPT ERROR" in baris:
            masalah.append("baris %d: SCRIPT ERROR: %s" % (nomor, baris.strip()))
        elif BARIS_ERROR.match(baris):
            masalah.append("baris %d: %s" % (nomor, baris.strip()))
        if "GAGAL" in baris:
            masalah.append("baris %d: tes gagal: %s" % (nomor, baris.strip()))
        if TANDA_CRASH.search(baris):
            masalah.append("baris %d: Godot crash: %s" % (nomor, baris.strip()))
        if BARIS_PERINGATAN.match(baris):
            peringatan.append("baris %d: %s" % (nomor, baris.strip()))
        cocok = RINGKASAN.match(baris.strip())
        if cocok:
            ringkasan.append((int(cocok.group(1)), int(cocok.group(2))))
    if not ringkasan:
        masalah.append("tidak ada baris ringkasan 'N lolos, 0 gagal' (tes tidak selesai?)")
    elif len(ringkasan) > 1:
        masalah.append("ada %d baris ringkasan, seharusnya tepat satu" % len(ringkasan))
    else:
        lolos, gagal = ringkasan[0]
        if gagal > 0:
            masalah.append("ringkasan melaporkan %d tes gagal" % gagal)
        if lolos == 0:
            masalah.append("ringkasan '0 lolos': tidak ada tes yang berjalan")
    if ketat:
        masalah.extend("peringatan (mode --ketat) %s" % p for p in peringatan)
    return masalah, peringatan, (ringkasan[0] if len(ringkasan) == 1 else None)


def main():
    parser = argparse.ArgumentParser(
        description="Memeriksa log keluaran tes Godot (SCRIPT ERROR, ERROR:, GAGAL, ringkasan)."
    )
    parser.add_argument("log", help="jalur berkas log, atau - untuk stdin")
    parser.add_argument("--ketat", action="store_true", help="peringatan (WARNING:) juga menggagalkan")
    args = parser.parse_args()
    try:
        if args.log == "-":
            teks = sys.stdin.read()
        else:
            with open(args.log, encoding="utf-8", errors="replace") as f:
                teks = f.read()
    except OSError as galat:
        print("pemeriksa: tidak bisa membaca log: %s" % galat, file=sys.stderr)
        return 2
    masalah, peringatan, ringkasan = periksa(teks, ketat=args.ketat)
    for p in peringatan:
        print("peringatan: %s" % p)
    if masalah:
        for m in masalah:
            print("MASALAH: %s" % m)
        print("pemeriksa: TIDAK LOLOS (%d masalah)" % len(masalah))
        return 1
    print("pemeriksa: lolos (%d lolos, 0 gagal, %d peringatan)" % (ringkasan[0], len(peringatan)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
