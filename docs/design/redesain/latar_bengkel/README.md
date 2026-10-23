# Latar bengkel (usulan, 2026-10-23)

- `sumber_ai.jpg` (1792×1008): ilustrasi AI dikirim pemilik 2026-10-23. Generator dan ketentuan lisensi komersial **belum dicatat**; isi sebelum dipakai di rilis (ART_DIRECTION 9).
- `bengkel_latar_640.png` (640×360) dan `bengkel_latar_800.png` (800×360): hasil konversi, 26 warna, 1×.
- `bengkel_latar_800_x3.png`: pratinjau ×3 tanpa penghalusan.

Dibuat dengan `python3 tools/ui_art/redesain/latar_bengkel.py --mock` (butuh numpy, pillow, opencv-python, scikit-learn). Langkah dan alasannya ada di docstring skrip dan di [`../README.md`](../README.md) bagian 5. Yang diubah dari sumber: semua tanaman dihapus (permintaan pemilik), cahaya lampu jadi cincin bertingkat, dan versi 800 diperlebar dengan pantulan tepi.
