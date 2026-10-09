# Loop Log — 20261009-fase0a-fondasi
Scope: Run 0A — fondasi project Godot  ·  Branch: feat/fase0a-fondasi-godot  ·  Mulai: 2026-10-09  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## Catatan gerbang Dev (tempel ringkasan perintah dan hasilnya per iterasi)

## Bukti verifikasi layar (AC-13)

## NEEDS-MANUAL (uji di HP)
- [ ] Tampilan dan ketajaman piksel di 16:9, 19,5:9 (A54 2340×1080 → 780×360), dan 20:9 di layar sungguhan; jalankan scene `scenes/dev/graybox.tscn`, harapan: piksel tajam tanpa blur, skala bulat, tidak ada tepi bergerigi acak.
- [ ] CI GitHub Actions hijau pada PR (hanya bisa dibuktikan setelah PR dibuka).
- [ ] Cek light 2D / glow / partikel / shader warna bayangan di renderer Compatibility pada HP target (tidak dikerjakan di 0A; masuk run berikutnya atau Fase 1).

## Keputusan & catatan
- Keputusan pemilik (ROADMAP 4b, 2026-10-09): Godot 4.7.2, skala ×3, base 640×360, `canvas_items` + integer + `expand`, package `com.rmh.kring`. Cadangan `viewport` tidak boleh dipakai tanpa persetujuan pemilik.
- Tidak ada keputusan terbuka (ROADMAP 5) yang menghambat scope 0A, jadi tidak ada pertanyaan ke pemilik. Ukuran ubin 64×32 dan font tetap berstatus usulan.
- Keputusan orchestrator D-1..D-5 ada di SPEC.md; dilaporkan ke pemilik di laporan akhir.
