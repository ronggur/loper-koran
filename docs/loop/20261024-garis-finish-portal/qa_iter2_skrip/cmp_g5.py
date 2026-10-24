import json,sys
m=json.load(open('g5_main.json'))['kasus']; b=json.load(open('g5_branch.json'))['kasus']
def diff(a,b,p=''):
    out=[]
    if isinstance(a,dict) and isinstance(b,dict):
        for k in a:
            if k=='ekstra': continue
            if k not in b: out.append(p+'/'+k+' hilang'); continue
            out+=diff(a[k],b[k],p+'/'+k)
    elif a!=b: out.append(f'{p}: main={a} branch={b}')
    return out
tot=0
for x,y in zip(m,b):
    d=diff(x,y); tot+=len(d)
    h=x['hasil']; g=x['garis']
    print(x['nama'], 'garis@',x['langkah_garis'], 'DIFF:',len(d), '| skor',h['skor'],'koin',h['koin'],'tip',h['tip'],'tepat',h['tepat'],'kirim',h['terkirim'],'buang',h['terbuang'],'(garis:',g['terbuang'],') misi',h['misi'],'tab',x['tabrakan_sebelum'],x['tabrakan_sesudah'],'lempar',x['lempar_sebelum'],x['lempar_sesudah'],'terbang@garis',x['garis_terbang'],'v',x['garis_sepeda_v'],'tenggat_lewat',h['tenggat_lewat'])
    for l in d[:10]: print('   ',l)
    e=y['ekstra']; print('     ekstra g->hasil',e['langkah_garis_ke_hasil'],'hampir->hasil',e['langkah_hampir_ke_hasil'],'vmin',round(e['laju_min_setelah'],3),'rem',e['rem_setelah'],'kamgeser',e['kamera_geser_maks'],'latgeser',e['lateral_geser_maks'],'luar',e['badan_kiri_di_luar'],'hasilsinyal',y['jumlah_hasil_sinyal'])
print('total diff',tot)
