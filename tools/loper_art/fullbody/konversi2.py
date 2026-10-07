"""Gambar full body loper (resmi sejak 2026-10-08): gambar AI 1792x2240 jadi pixel art 240x292.

Hasil: docs/design/character/loper_agen/loper_agen_fullbody.png (sumber dan catatan di
konversi2/ di folder yang sama). Langkah-langkahnya ada di folder konversi2/ di sini dan
dijalankan berurutan:

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
  # --layers: juga simpan layer kepala dan badan terpisah (untuk ekspresi potret)

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
    ap.add_argument("--layers", action="store_true", help="juga simpan layer kepala dan badan terpisah")
    args = ap.parse_args()

    out = os.path.abspath(args.out)
    work = os.path.join(out, "kerja")
    os.makedirs(work, exist_ok=True)
    shutil.copyfile(args.source, os.path.join(work, "src.jpg"))

    for step in STEPS:
        print("..", step)
        runpy.run_path(os.path.join(HERE, step), init_globals={"W": work + os.sep, "HERE": HERE})

    name = "loper_agen_fullbody"
    img = Image.open(os.path.join(work, "comp1x.png")).convert("RGBA")
    img.save(os.path.join(out, name + ".png"))
    w, h = img.size
    img.resize((w * 3, h * 3), Image.NEAREST).save(os.path.join(out, name + "_x3.png"))
    if args.layers:
        shutil.copyfile(os.path.join(work, "layer_badan.png"), os.path.join(out, name + "_body.png"))
        shutil.copyfile(os.path.join(work, "layer_kepala.png"), os.path.join(out, name + "_head.png"))
    print(f"{name}: {w}x{h} -> {out}")


if __name__ == "__main__":
    main()
