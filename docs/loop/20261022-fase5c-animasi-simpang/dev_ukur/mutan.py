import subprocess, re, sys, json
R='/Users/ronggur/Works/Games/Loper-Koran/apps/loper-koran'
M=[
("A1","scripts/systems/loper_anim.gd","if t + Config.TABRAKAN_TOLERANSI_DETIK >= mulai_bangkit:","if t + Config.TABRAKAN_TOLERANSI_DETIK > mulai_bangkit:","batas mulai bangkit >= jadi >"),
("A2","scripts/systems/loper_anim.gd","if t + Config.TABRAKAN_TOLERANSI_DETIK >= mulai_bangkit:","if t >= mulai_bangkit:","toleransi batas bangkit dibuang"),
("A3","scripts/systems/loper_anim.gd","var mulai_bangkit: float = maxf(total_detik - float(n_bangkit) / fps_bangkit, lama_jatuh)","var mulai_bangkit: float = total_detik - float(n_bangkit) / fps_bangkit","maxf dibuang"),
("A4","scripts/systems/loper_anim.gd","f.frame = mini(floori(posisi + Config.TABRAKAN_TOLERANSI_DETIK), n_bangkit - 1)","f.frame = posmod(floori(posisi + Config.TABRAKAN_TOLERANSI_DETIK), n_bangkit)","frame terakhir bangkit tidak ditahan (berulang)"),
("A5","scripts/systems/loper_anim.gd","return StringName(\"%s_%s\" % [NAMA_BANGKIT, NAMA_ARAH[jepit_arah(arah)]])","return StringName(\"%s_%s\" % [NAMA_BANGKIT, NAMA_ARAH.get(arah, \"normal\")])","arah bangkit tidak dijepit"),
("A6","scripts/systems/loper_anim.gd","return StringName(\"%s_%s\" % [NAMA_BANGKIT, NAMA_ARAH[jepit_arah(arah)]])","return StringName(\"%s_%s\" % [NAMA_BANGKIT, NAMA_ARAH[0]])","bangkit memakai arah 0"),
("A7","scripts/systems/loper_anim.gd","\tif rem_aktif:\n\t\tif not is_nan","\tif rem_aktif or kecepatan_ud == 0.0:\n\t\tif not is_nan","BERHENTI tanpa rem"),
("A8","scripts/systems/loper_anim.gd","kecepatan_ud <= Config.POSE_MELUNCUR_TOLERANSI_UD:\n\t\t\treturn Pose.BERHENTI","kecepatan_ud < Config.POSE_MELUNCUR_TOLERANSI_UD:\n\t\t\treturn Pose.BERHENTI","BERHENTI <= jadi <"),
("A9","scripts/systems/loper_anim.gd","if not is_nan(kecepatan_ud) and kecepatan_ud <= Config.POSE_MELUNCUR_TOLERANSI_UD:","if is_nan(kecepatan_ud) or kecepatan_ud <= Config.POSE_MELUNCUR_TOLERANSI_UD:","NaN = BERHENTI"),
("A10","scripts/systems/loper_anim.gd","\tif NAMA_POSE.has(pose):\n\t\treturn 0\n","\tif NAMA_POSE.has(pose) and pose != Pose.BERHENTI:\n\t\treturn 0\n","lempar dari BERHENTI memakai tingkat kayuh"),
("A11","scenes/entities/loper_agen.tscn","offset = Vector2(0, -17)","offset = Vector2(0, -16)","offset pijak salah 1 px"),
("A12","assets/sprites/loper/loper_agen_frames.tres","region = Rect2(700, 352, 140, 88)","region = Rect2(700, 351, 140, 88)","region bangkit_kiri frame 5 bergeser 1 px"),
("A13","scripts/entities/loper_sprite.gd","\t\t\t\tset_frame_and_progress(0, 0.0)\n","\t\t\t\tpass\n","fix A-F1 dilepas (bangun mewarisi indeks frame)"),
("A14","scripts/entities/sepeda_uji.gd","\tif not _sprite.sedang_jatuh():\n","\tif true:\n","fix A-F2 dilepas (arah diganti selama jatuh)"),
("A15","scripts/entities/sepeda_uji.gd","\t_sprite.atur_jatuh(false, 0.0)\n\tgerak(Vector2.ZERO, 0.0)","\tgerak(Vector2.ZERO, 0.0)","atur_ulang tidak keluar dari jatuh dulu"),
("B1","scripts/systems/pose_kucing.gd","return jenis == JENIS_TANGKAP and is_finite(progres) and progres > 0.0","return jenis == JENIS_TANGKAP and is_finite(progres) and progres >= 0.0","ditangkap saat progres 0"),
("B2","scripts/systems/pose_kucing.gd","return jenis == JENIS_TANGKAP and is_finite(progres) and progres > 0.0","return is_finite(progres) and progres > 0.0","ditangkap di langkah lain"),
("B3","scripts/config.gd","const MISI_KUCING_DITANGKAP_FPS: float = 3.0","const MISI_KUCING_DITANGKAP_FPS: float = 4.0","fps ditangkap salah"),
("B4","scripts/config.gd","const MISI_KUCING_KOLOM_DITANGKAP: Array[int] = [7, 8]","const MISI_KUCING_KOLOM_DITANGKAP: Array[int] = [6, 7]","kolom 6 (kaget) dipakai"),
("B5","scripts/systems/pose_kucing.gd","floori(t * Config.MISI_KUCING_DITANGKAP_FPS + Config.MISI_TANGKAP_TOLERANSI)","floori(t * Config.MISI_KUCING_DITANGKAP_FPS)","toleransi batas 1/3 detik dibuang"),
("B6","scripts/entities/kucing_misi.gd","\t_badan.frame = PoseKucing.frame(titik.jenis, progres, detik)\n","\t_badan.frame = PoseKucing.frame(titik.jenis, progres, detik + float(Time.get_ticks_usec()) * Config.MISI_TANGKAP_TOLERANSI)\n","pose tidak membeku saat jeda (waktu dinding)"),
("B7","scripts/entities/kucing_misi.gd","\t_badan.frame = PoseKucing.frame(titik.jenis, progres, detik)\n","","KucingMisi tidak memakai PoseKucing"),
("B8","scripts/systems/pose_kucing.gd","\tvar t: float = detik if is_finite(detik) and detik > 0.0 else 0.0","\tvar t: float = detik","waktu NaN/negatif tidak dibersihkan"),
]
hasil=[]
pilih=sys.argv[1:] 
for kode,f,a,b,ket in M:
    if pilih and kode not in pilih: continue
    p=R+'/'+f; s=open(p).read()
    assert s.count(a)==1, (kode, s.count(a))
    open(p,'w').write(s.replace(a,b))
    out=subprocess.run('godot --headless --script res://tests/run_tests.gd > build/mutan.log 2>&1; python3 tools/cek_keluaran_tes.py build/mutan.log',shell=True,cwd=R,capture_output=True,text=True)
    log=open(R+'/build/mutan.log',errors='replace').read()
    ring=re.findall(r'(\d+) lolos, (\d+) gagal',log)
    gagal=[l for l in log.splitlines() if 'GAGAL' in l][:3]
    err=len(re.findall('SCRIPT ERROR',log))
    subprocess.run(['git','checkout','--',f],cwd=R)
    st=subprocess.run(['git','status','--short'],cwd=R,capture_output=True,text=True).stdout.strip()
    r=dict(kode=kode,file=f,ket=ket,ringkas=ring[-1] if ring else None,script_error=err,pemeriksa=out.stdout.strip().splitlines()[-1] if out.stdout.strip() else out.stderr.strip()[-200:],gagal=gagal,status=st)
    print(json.dumps(r,ensure_ascii=False),flush=True)
