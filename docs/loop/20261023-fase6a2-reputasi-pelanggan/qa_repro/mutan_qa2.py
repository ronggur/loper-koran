import subprocess,sys,re,os
R="/Users/ronggur/Works/Games/Loper-Koran/apps/loper-koran"
SP="/private/tmp/claude-501/-Users-ronggur-Works-Games-Loper-Koran-apps-loper-koran/1bca2556-a029-41c6-b925-2dcc051c36b7/scratchpad"
RB="scripts/systems/route_builder.gd"; RM="scripts/systems/reputation_manager.gd"; PR="scripts/systems/pelanggan_rute.gd"
M=[
("Q6","scripts/systems/pelanggan_rute.gd","hari - hari_berhenti(id) >= Config.PELANGGAN_KEMBALI_JEDA_HARI","hari - hari_berhenti(id) > Config.PELANGGAN_KEMBALI_JEDA_HARI","pure rute"),
("Q12","scripts/systems/data_misi.gd","return clampi(int(roundf(float(nilai))), 0, Config.REPUTASI_MISI_GAGAL_MAKS)","return clampi(int(roundf(float(nilai))), 0, 5)","pure"),
("Q20",RM,"if r.terantar:\n\t\t\tkredit += kredit_antaran(r.kualitas, kepribadian)","if r.terantar and e[\"status\"] != PelangganRute.BERHENTI:\n\t\t\tkredit += kredit_antaran(r.kualitas, kepribadian)","pure"),
("N1",RB,"if d == k0 and s == k1:","if d == k0 or s == k1:","rute"),
("N2",RB,"biaya.append(1 if p.status(r.id) == PelangganRute.BERHENTI and not kembali.has(r.id) else 0)","biaya.append(1 if p.status(r.id) != PelangganRute.AKTIF and not kembali.has(r.id) else 0)","rute"),
("N3",RB,"if p.status(rumah.id) == PelangganRute.BERHENTI and not kembali.has(rumah.id):","if p.status(rumah.id) == PelangganRute.BERHENTI:","rute pure"),
("N4",RB,"return aktif.has(r.id)\n","return aktif.has(r.id) or cfg[\"prioritas\"] == 0\n","rute"),
("N5",RB,"dasar = awal + (akhir - awal) * float(langkah) / float(total - 1)","dasar = awal","rute"),
("N6",RB,"butir[j].maju_ubin - butir[i].maju_ubin > Config.RUTE_PELANGGAN_JARAK_MAKS_UBIN:","butir[j].maju_ubin - butir[i].maju_ubin >= Config.RUTE_PELANGGAN_JARAK_MAKS_UBIN:","rute"),
("N7",RB,"if sekarang >= 0 and butir[j].maju_ubin - butir[sekarang].maju_ubin > Config.RUTE_PELANGGAN_JARAK_MAKS_UBIN:","if sekarang >= 0 and butir[j].maju_ubin - butir[sekarang].maju_ubin > Config.RUTE_PELANGGAN_JARAK_MAKS_UBIN + 5:","rute"),
("N8",PR,"return status(id) == BERHENTI and hari - hari_berhenti(id)","return status(id) != BARU and hari - hari_berhenti(id)","pure rute"),
("N9",PR,"\treturn AKTIF\n","\treturn BARU\n","pure rute"),
("N10",RM,"\te[\"meleset\"] = 0\n\te[\"hari_berhenti\"] = 0\n\n\nstatic func _catat","\te[\"hari_berhenti\"] = 0\n\n\nstatic func _catat","pure"),
("N11",RM,"if kembali_hari.has(r.id):\n\t\t\tpeta[r.id] = e","if false and kembali_hari.has(r.id):\n\t\t\tpeta[r.id] = e","pure"),
("N12",RM,"int(e[\"antar\"]) >= Config.PELANGGAN_SETIA_ANTAR","int(e[\"antar\"]) > Config.PELANGGAN_SETIA_ANTAR","pure"),
("N13",RM,"Config.PELANGGAN_SETIA_BERHENTI_MELESET if e[\"status\"] == PelangganRute.SETIA else Config.PELANGGAN_BERHENTI_MELESET","Config.PELANGGAN_BERHENTI_MELESET if e[\"status\"] == PelangganRute.SETIA else Config.PELANGGAN_SETIA_BERHENTI_MELESET","pure"),
("N14","scripts/config.gd","const PELANGGAN_KEMBALI_MAKS_PER_RUTE: int = 1","const PELANGGAN_KEMBALI_MAKS_PER_RUTE: int = 2","rute"),
("N15","scripts/config.gd","const HASIL_BILAH_TEPI_PX: int = 1","const HASIL_BILAH_TEPI_PX: int = 0","scene pure"),
("N16",RB,"rute.pelepasan = tingkat.size()\n\t\treturn true","rute.pelepasan = 0\n\t\treturn true","rute"),
("N17",RB,"var tak_hingga: int = n + 1","var tak_hingga: int = 3","rute"),
]
sel=sys.argv[1:]
for (n,f,old,new,g) in M:
    if sel and n not in sel: continue
    p=os.path.join(R,f); s=open(p).read()
    c=s.count(old)
    if c!=1: print(n,"SKIP count",c,flush=True); continue
    open(p,"w").write(s.replace(old,new))
    try:
        out=subprocess.run(["godot","--headless","--path",R,"--script",SP+"/mini.gd","--",g],capture_output=True,text=True,timeout=1500)
        txt=out.stdout+out.stderr
        m=re.search(r"RINGKAS lolos (\d+) gagal (\d+)",txt)
        err="SCRIPT ERROR" in txt
        first=[l for l in txt.splitlines() if l.startswith("GAGAL")][:1]
        print(n,f.split('/')[-1],"->",(m.group(0) if m else "NO SUMMARY"),"scripterr" if err else "", "TERTANGKAP" if ((m and int(m.group(2))>0) or err or not m) else "LOLOS!!!", first, flush=True)
    finally:
        open(p,"w").write(s)
