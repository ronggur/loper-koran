# Papan base model Kemeja Agen

Pose yang dikunci 2026-10-07 (`tools/loper_art/base.py`), sama dengan papan "Base model Kemeja Agen · 5 arah" dan "Pose per kecepatan" di kanvas "Karakter Loper Koran".

- `agen_5arah_1x.png` (+ `_x6`): lima arah santai: normal, serong kanan, kanan, serong kiri, kiri.
- `agen_kecepatan_1x.png` (+ `_x6`): santai, cepat, ngebut; baris atas arah normal, baris bawah dari samping.

File `_1x` berlatar transparan, `_x6` berlatar abu untuk dilihat.

    python3 tools/loper_art/base.py --out build/loper_art/base
