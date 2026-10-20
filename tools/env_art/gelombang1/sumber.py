"""Aset yang SUDAH ada di repo, dipakai gelombang 1 sebagai alas dan acuan (tidak diubah, tidak disalin):

- ubin jalan perumahan: dirender di memori oleh `tools/env_art/ubin_perumahan.py` (fungsi yang sama dengan ekspornya),
- rumah perumahan dua sisi + JSON titik pijak: `assets/sprites/houses/perumahan/` (`tools/env_art/fase3.py`),
- kotak surat sasaran dan bukan sasaran: `assets/sprites/props/`,
- sprite pemain: `docs/design/character/loper_agen/loper_agen.png`.
"""
import functools
import json
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image

FOLDER = Path(__file__).resolve().parent
ENV_ART = FOLDER.parent
ROOT = ENV_ART.parent.parent


def _png(jalur):
    with Image.open(jalur) as im:
        return np.array(im.convert('RGBA'))


@functools.lru_cache(maxsize=None)
def _ubin_semua():
    if str(ENV_ART) not in sys.path:
        sys.path.insert(0, str(ENV_ART))
    import ubin_perumahan as UP
    U = UP.U
    hasil = {}
    img, _ = UP.render_adegan(lambda s: UP.build_jalan(s))
    for nm, cxu in UP.KOLOM.items():
        hasil[nm] = UP.potong(img, cxu * U, 0.0)
    im, _ = UP.render_adegan(lambda s: s.add(UP.ground_prim(lambda x, y: UP._polos(x, y, 0), UP.MATS)))
    hasil['aspal_polos'] = UP.potong(im, 0.5 * U, 0.0)
    hasil['rumput_polos'] = UP.potong(im, 6.5 * U, 0.0)
    return hasil


def ubin(nama):
    """Ubin 64x32 (RGBA) dari ubin_perumahan.py: aspal_seberang, aspal_dekat, trotoar_*, rumput_*, aspal_polos, rumput_polos."""
    return _ubin_semua()[nama].copy()


@functools.lru_cache(maxsize=None)
def _sprite(folder, nama):
    jalur = ROOT / folder / nama
    meta = json.loads(Path(str(jalur) + '.json').read_text())
    return _png(str(jalur) + '.png'), tuple(meta['ground_anchor'])


def rumah(nama):
    """(rgba, titik_pijak) rumah `house_perumahan_<nama>`."""
    a, o = _sprite('assets/sprites/houses/perumahan', 'house_perumahan_' + nama)
    return a.copy(), o


def kotak_surat(sasaran=True):
    a, o = _sprite('assets/sprites/props', 'prop_kotak_surat' if sasaran else 'prop_kotak_surat_bukan')
    return a.copy(), o


def pemain_frame(baris=0, kolom=0):
    """Satu sel 46x58 sheet pemain (pijak 23,46). Baris 0 = santai_normal."""
    sheet = _png(ROOT / 'docs/design/character/loper_agen/loper_agen.png')
    return sheet[baris * 58:(baris + 1) * 58, kolom * 46:(kolom + 1) * 46].copy()
