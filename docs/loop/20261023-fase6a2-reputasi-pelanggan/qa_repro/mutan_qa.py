import subprocess,sys,re,os
R="/Users/ronggur/Works/Games/Loper-Koran/apps/loper-koran"
SP="/private/tmp/claude-501/-Users-ronggur-Works-Games-Loper-Koran-apps-loper-koran/1bca2556-a029-41c6-b925-2dcc051c36b7/scratchpad"
M=[
("Q1","scripts/systems/reputation_manager.gd","floori(float(kredit) / float(Config.REPUTASI_KREDIT_PER_POIN))","ceili(float(kredit) / float(Config.REPUTASI_KREDIT_PER_POIN))","pure"),
("Q2","scripts/systems/kepribadian_pelanggan.gd","nilai = ((nilai ^ b) * Config.HASH_FNV1A_KALI)","nilai = ((nilai + b) * Config.HASH_FNV1A_KALI)","pure"),
("Q3","scripts/systems/data_save.gd","baru[\"koin_total\"] = clampi(int(baru[\"koin_total\"]) + koin_hari,","baru[\"koin_total\"] = clampi(int(baru[\"koin_total\"]) + koin_hari - maxi(angka.potongan, 0),","pure"),
("Q4","scripts/systems/skor_rute.gd","\t\th.penanda = ZonaSasaran.Penanda.NETRAL\n\t\ts.terbuang += 1\n","\t\th.penanda = ZonaSasaran.Penanda.NETRAL\n","pure"),
("Q5","scripts/systems/hasil_rute.gd","return clampi(maxi(saldo_lama, 0) + koin_bersih, 0, Config.SAVE_ANGKA_MAKS)","return clampi(maxi(saldo_lama, 0) + koin_bersih, -Config.SAVE_ANGKA_MAKS, Config.SAVE_ANGKA_MAKS)","pure"),
("Q6","scripts/systems/pelanggan_rute.gd","hari - hari_berhenti(id) >= Config.PELANGGAN_KEMBALI_JEDA_HARI","hari - hari_berhenti(id) > Config.PELANGGAN_KEMBALI_JEDA_HARI","pure rute"),
("Q7","scripts/systems/route_builder.gd","var batas: int = floori(float(kuota[sisi] * Config.PELANGGAN_SETIA_MAKS_PERSEN)","var batas: int = floori(float(kuota[sisi] * 100)","rute"),
("Q8","scripts/systems/reputation_manager.gd","e[\"status\"] = PelangganRute.AKTIF\n\te[\"antar\"] = 0\n\te[\"meleset\"] = 0\n\te[\"hari_berhenti\"] = 0","e[\"status\"] = PelangganRute.AKTIF\n\te[\"antar\"] = 0\n\te[\"meleset\"] = 0","pure"),
("Q9","scripts/systems/reputation_manager.gd","if kepribadian == KepribadianPelanggan.SENSITIF and int(e[\"meleset\"]) >= batas:","if kepribadian == KepribadianPelanggan.SENSITIF or int(e[\"meleset\"]) >= batas:","pure"),
("Q10","scripts/config.gd","const REPUTASI_BERHENTI_POIN: int = 1","const REPUTASI_BERHENTI_POIN: int = 2","pure"),
("Q11","scripts/entities/adegan_jalan.gd","if SkorRute.hasil_terbuang(hs):","if false and SkorRute.hasil_terbuang(hs):","scene"),
("Q12","scripts/systems/data_misi.gd","return clampi(int(roundf(float(nilai))), 0, Config.REPUTASI_MISI_GAGAL_MAKS)","return clampi(int(roundf(float(nilai))), 0, 5)","pure"),
("Q13","scripts/systems/milestone_tracker.gd","\t\tif n >= target:\n\t\t\tt += 1","\t\tif n > target:\n\t\t\tt += 1","pure"),
("Q14","scripts/systems/milestone_tracker.gd","str((entri as Dictionary).get(\"status\", \"\")) == \"setia\"","str((entri as Dictionary).get(\"status\", \"\")) != \"berhenti\"","pure"),
("Q15","scripts/systems/reputation_manager.gd","hasil.turun_berhenti = berhenti_hari * Config.REPUTASI_BERHENTI_POIN","hasil.turun_berhenti = 0","pure"),
("Q16","scripts/systems/route_builder.gd","\t\t\tif i < (urut_setia[sisi] as Array).size():","\t\t\tif false and i < (urut_setia[sisi] as Array).size():","rute"),
("Q17","scripts/systems/data_save.gd","\"koin_misi\": angka.koin_misi if angka.misi_hasil == \"selesai\" else 0,\n\t\t\"potongan\": maxi(angka.potongan, 0),","\"koin_misi\": angka.koin_misi if angka.misi_hasil == \"selesai\" else 0,\n\t\t\"potongan\": 0,","pure scene"),
("Q18","scripts/systems/hasil_rute.gd","a.lempar_terbuang = maxi(skor.terbuang, 0)","a.lempar_terbuang = a.meleset","pure scene"),
("Q19","scripts/systems/skor_rute.gd","return maxi(k.terbuang, 0) * Config.KOIN_POTONGAN_KORAN_MELESET","return maxi(k.terbuang, 0) * Config.KOIN_POTONGAN_KORAN_MELESET + (k.jumlah_tip if false else 0) + (1 if k.terbuang > 24 else 0)","pure scene"),
("Q20","scripts/systems/reputation_manager.gd","if r.terantar:\n\t\t\tkredit += kredit_antaran(r.kualitas, kepribadian)","if r.terantar and e[\"status\"] != PelangganRute.BERHENTI:\n\t\t\tkredit += kredit_antaran(r.kualitas, kepribadian)","pure"),
]
sel=sys.argv[1:] 
for (n,f,old,new,g) in M:
    if sel and n not in sel: continue
    p=os.path.join(R,f); s=open(p).read()
    c=s.count(old)
    if c!=1: print(n,"SKIP count",c); continue
    open(p,"w").write(s.replace(old,new))
    try:
        out=subprocess.run(["godot","--headless","--path",R,"--script",SP+"/mini.gd","--",g],capture_output=True,text=True,timeout=900)
        txt=out.stdout+out.stderr
        m=re.search(r"RINGKAS lolos (\d+) gagal (\d+)",txt)
        err="SCRIPT ERROR" in txt
        print(n,f.split('/')[-1],"->",(m.group(0) if m else "NO SUMMARY"),"scripterr" if err else "", "TERTANGKAP" if ((m and int(m.group(2))>0) or err or not m) else "LOLOS!!!", flush=True)
    finally:
        open(p,"w").write(s)
