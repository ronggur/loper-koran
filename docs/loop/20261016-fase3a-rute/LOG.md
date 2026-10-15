# Loop Log — 20261016-fase3a-rute
Scope: Run 3A Fase 3, fondasi rute (segmen JSON, RouteBuilder berseed, scene rute, zona dari data, penutup semi-transparan)  ·  Branch: `feat/fase3a-rute`  ·  Mulai: 2026-10-16  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
- [ ] Rute dari awal sampai garis akhir tanpa patah, 60 fps, memuat < 1 detik; tiga seed berbeda tidak terasa dihafal.
- [ ] Kotak surat kena dengan sengaja di santai/cepat/ngebut; mode bantu mengenai kotak surat pelanggan terdekat.
- [ ] Objek penutup semi-transparan terbaca; rumah dan kotak surat tajam di ×3.
- [ ] Banner "Rute selesai" dan tombol "Main lagi" terbaca dan tidak tersentuh tak sengaja.
- [ ] Hasil uji HP Fase 2 (SETUP_ANDROID 8.5) belum diisi pemilik; Fase 2 dan M1 tetap tidak dicentang.

## Keputusan & catatan
- Keputusan pemilik 2026-10-16 ("ok semua"): K-1 segmen JSON; K-2 9 segmen, 7 per rute, 25 pelanggan, koran awal 30; K-3 id rumah `<id_segmen>@<pos>`, pemetaan ke save ditunda ke Fase 6; K-4 scene baru `scenes/rute/rute.tscn`, jalan uji tetap dev; K-5 akhir rute berhenti + banner sementara + "Main lagi" dev. Rincian di `SPEC.md`.
- Pemilik belum menjalankan uji HP Fase 2; 3A dimulai tanpa hasilnya.
- Lingkungan (2026-10-16): Godot 4.7.2, Java 17, `main` = `origin/main` = `51aaedf`, vivo V2108 (`12d8c9da`) tersambung, A54 tidak.
