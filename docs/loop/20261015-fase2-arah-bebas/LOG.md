# Loop Log — 20261015-fase2-arah-bebas
Scope: arah lempar koran bebas (perbaikan uji HP Run 2A)  ·  Branch: feat/lempar-arah-bebas  ·  Mulai: 2026-10-15  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
- [ ] Arah bebas terasa wajar: swipe ke arah rumah yang terlihat mengenai rumah itu (vivo V2108, juga A54 bila tersambung).
- [ ] Kotak surat seberang di depan bisa dikenai dengan sengaja di santai, cepat, ngebut.
- [ ] Swipe kiri murni (mendarat seberang sedikit ke belakang) tidak membingungkan.
- [ ] Swipe ke atas cukup panjang untuk lemparan jauh.
- [ ] Flick dan jari ditarik kembali.
- [ ] Pengamatan untuk Run 2B: apakah jeda antar lempar 0,35 detik dan jeda lepas 0,17 detik masih terasa "tidak responsif".

## Keputusan & catatan
- Keputusan pemilik 2026-10-15 (chat): "arah bebas dong", jawaban atas usulan orchestrator (arah bebas vs dua sisi dilonggarkan). Dicatat di GDD 5.2 dan ROADMAP 4b, commit `06c6797`.
- Laporan pemilik 2026-10-14 sesudah uji Run 2A di vivo V2108: "lemparan koran rasanya gak responsif, suka gagal, terutama ke arah kiri". Penyebab terbukti orchestrator (SPEC, Latar belakang): swipe dominan tegak (45°–135°) ditolak, padahal sasaran seberang di depan terlihat di atas sepeda.
- Run dimulai di sesi yang sama dengan penutupan Run 2A (sesudah ringkasan konteks), atas permintaan langsung pemilik; menyimpang dari Bagian 0c (satu sesi per run) demi kelanjutan, keadaan run tetap seluruhnya di SPEC/LOG.
