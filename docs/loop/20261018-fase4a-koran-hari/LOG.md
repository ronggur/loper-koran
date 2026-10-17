# Loop Log — 20261018-fase4a-koran-hari
Scope: Run 4A — halaman depan koran, format misi dan headline, HeadlineManager, SaveManager v1, alur satu hari  ·  Branch: feat/koran-hari-4a  ·  Mulai: 2026-10-17  ·  Godot: 4.7.2.stable

## Status: IN_PROGRESS   (iterasi saat ini: 0/2)

Baseline (main 2910bed, sebelum perubahan): `godot --headless --import` bersih; `run_tests.gd` = 10907 lolos, 0 gagal; `tools/cek_keluaran_tes.py` lolos (0 peringatan).

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## Mutan (AC-26, diisi Dev; QA mengulang sedikitnya 5)
| # | Mutan (file, perubahan) | Tes yang merah | Dikembalikan |
|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
- [ ] Layar koran terbaca dalam 10 detik di A54 dan vivo V2108; krem tidak menyilaukan.
- [ ] Ambil, Lewati, Berangkat terasa pas (target sentuh), Ambil/Lewati bisa dibolak-balik.
- [ ] Alur satu hari: Koran → Rute → Hasil → "Hari berikutnya" → Koran hari 2 (headline dan rute berbeda dari hari 1).
- [ ] Force stop app di tengah rute, buka lagi: koran hari yang sama, progres kemarin utuh (JANGAN `pm clear`).
- [ ] Back Android: koran = keluar, rute = jeda, hasil = diabaikan.
- [ ] Sakelar Kidal/Bantu yang diubah di jeda bertahan ke hari berikutnya.

## Keputusan & catatan
- Keputusan pemilik 2026-10-17: tetap mulai walau uji HP Fase 3 kosong; koran "Warta Kring", perumahan "Perumahan Melati"; layar hasil "Hari berikutnya" saja; tutup di tengah rute = ulang hari dari layar koran; misi lintas hari ditunda ke 4B.
- Keputusan orchestrator S-1 sampai S-8 di SPEC (usulan, bisa ditolak di review).
- Catatan untuk PR: `allowBackup` (rule save-system: aktif; preset export: false) — tanyakan pemilik, jangan diubah di run ini.
- PR #38 (docs perintah Fase 4) masih terbuka di branch `docs/perintah-run-fase4`; tidak disentuh run ini.
