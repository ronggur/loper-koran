"""Gambar AI loper (sumber 1792x2240) jadi pixel art 240x292, versi konversi2.

Hasil: docs/design/character/loper_agen/konversi2/. Langkah-langkahnya ada di
folder konversi2/ dan dijalankan berurutan:

  mask.py     latar cokelat polos dibuang (masker latar)
  stage1.py   bayangan tanah dipisah, palet 36 warna (k-means Lab), tiap sel 7x7 px
              mengambil warna terbanyak, tepi antialias diabaikan
  stage2.py   piksel lepas dirapikan
  compose.py  garis luar, roda digambar ulang, lalu bagian-bagian yang diubah dengan tangan:
              drive.py     satu gir belakang, rantai lurus, dua engkol segaris
              bag.py       tas boncengan terbuka berisi koran gulung
              headfix.py, headmove_a.py, collar.py, headmove_b.py
                           tanpa leher, dagu melengkung, kerah belakang, kepala turun 2 px
              cables.py    kabel rem tinggal dua
              paper.py     tulisan KORAN, gelang kuning, bayangan tanah dirapikan
              shoes.py     tali sepatu kiri

Koordinat di tiap langkah khusus untuk gambar sumber ini.

  python3 tools/loper_art/fullbody/konversi2.py \\
      docs/design/character/loper_agen/konversi2/sumber_ai.jpg --out build/loper_art/konversi2

Butuh numpy, pillow, opencv-python, scikit-learn.
"""
import argparse
import os
import runpy
import shutil

from PIL import Image

HERE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "konversi2")
STEPS = ["mask.py", "stage1.py", "stage2.py", "compose.py"]


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("source", help="gambar sumber (sumber_ai.jpg)")
    ap.add_argument("--out", default="build/loper_art/konversi2")
    args = ap.parse_args()

    out = os.path.abspath(args.out)
    work = os.path.join(out, "kerja")
    os.makedirs(work, exist_ok=True)
    shutil.copyfile(args.source, os.path.join(work, "src.jpg"))

    for step in STEPS:
        print("..", step)
        runpy.run_path(os.path.join(HERE, step), init_globals={"W": work + os.sep, "HERE": HERE})

    img = Image.open(os.path.join(work, "comp1x.png")).convert("RGBA")
    img.save(os.path.join(out, "loper_agen_konversi2.png"))
    w, h = img.size
    big = img.resize((w * 3, h * 3), Image.NEAREST)
    os.makedirs(os.path.join(out, "preview"), exist_ok=True)
    big.save(os.path.join(out, "preview", "loper_agen_konversi2_x3.png"))
    print("selesai:", os.path.join(out, "loper_agen_konversi2.png"), f"{w}x{h}")


if __name__ == "__main__":
    main()
