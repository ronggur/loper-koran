import re,sys
src=open('tests/run_tests.gd').read().split('\n')
sel={'TesGarisFinish','TesGarisFinishScene','TesHiasan','TesRevisiUiE','TesHudRuteScene','TesTampilHasil','TesHasilStruk','TesRadar','TesHasil','TesRuteScene','TesDekor','TesRute','TesTampilHud'}
keep_fn={'_test_palet()','_test_tanpa_hex_di_luar_palet()','_test_gaya_kode()','_test_terjemahan()'}
out=[];i=0
# locate _initialize
start=next(k for k,l in enumerate(src) if l.startswith('func _initialize'))
end=next(k for k,l in enumerate(src) if l.startswith('## Jejak `user://save.json`'))
out+=src[:start+1]
body=src[start+1:end]
j=0
while j<len(body):
    l=body[j]
    s=l.strip()
    if s.startswith('var save_asli_awal') or s.startswith('await process_frame') or s.startswith('var ukuran_sebelum') or s.startswith('var audio') or s.startswith('if audio') or s.startswith('audio.set') :
        out.append(l); j+=1; continue
    if s in keep_fn:
        out.append(l); j+=1; continue
    m=re.match(r'var (\w+): (Tes\w+) = ',s)
    if m and m.group(2) in sel:
        out.append(l); j+=1
        if j<len(body) and ('jalankan' in body[j]): out.append(body[j]); j+=1
        continue
    if s.startswith('root.size = ukuran_sebelum') or s.startswith('var save_asli_akhir') or s.startswith('check(save_asli_awal') or s.startswith('await create_timer') or s.startswith('print("%d lolos') or s.startswith('quit(') or s.startswith('audio.call') or s.startswith('audio.set(&"putar'):
        out.append(l); j+=1; continue
    j+=1
out+=src[end-1:]
open('tests/qa2_subset.gd','w').write('\n'.join(out))
