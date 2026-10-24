import json,sys,glob
import numpy as np
from PIL import Image
def hexrgb(h): h=h.lstrip('#'); return np.array([int(h[i:i+2],16) for i in (0,2,4)],float)
def run(pref,k):
    d=json.load(open(f'{pref}_{k}.json')); img=Image.open(f'{pref}_{k}.png').convert('RGB'); s=img.width/d['viewport'][0]
    A=np.asarray(img,float)
    T=[t for t in d['teks'] if t['rect'][0]>=520 and t['rect'][1]<60]
    lab=[t for t in T if t['teks']=='Reputasi']; 
    num=[t for t in T if t['teks'].lstrip('+-').isdigit() and t['rect'][2]>20 and t['rect'][3]>20]
    chip=[t for t in T if t['teks'][:1] in '+-' and t['teks'][1:].isdigit()]
    if not (lab and num and chip): print(k,'tak lengkap',[t['teks'] for t in T]); return
    def inkc(t,wmax=None):
        x,y,w,h=[int(round(v*s)) for v in t['rect']]
        if wmax: w=min(w,int(wmax*s))
        sub=A[max(y-9,0):y+h+9,x:x+w]
        m=np.linalg.norm(sub-hexrgb(t['warna']),axis=2)<70
        r=np.where(m.any(axis=1))[0]
        return (max(y-9,0)+r.min())/s,(max(y-9,0)+r.max()+1)/s
    a=inkc(lab[0],7); b=inkc(num[0])
    # chip box: scan from the chip text center to find horizontal border lines (bright, long)
    t=chip[0]; x,y,w,h=[int(round(v*s)) for v in t['rect']]
    cx=x+w//2; cy=y+h//2
    col=A[:,cx]
    # border colour = brightest in column near chip: find rows within +-40 game px with luminance high and run length
    def lum(p): return p@np.array([.2126,.7152,.0722])
    rows=[]
    for yy in range(int(cy-30*s),int(cy+30*s)):
        seg=A[yy,x-int(6*s):x+w+int(6*s)]
        L=lum(seg)
        if (L>150).mean()>0.9: rows.append(yy)
    ra=(a[0]+a[1])/2; rb=(b[0]+b[1])/2
    if rows:
        top=min(rows)/s; bot=(max(rows)+1)/s
        print(k,'R-pusat %.2f angka-pusat %.2f chip-pusat %.2f (chip %.2f..%.2f)'%(ra,rb,(top+bot)/2,top,bot),'selisih maks %.2f'%max(abs(ra-rb),abs(ra-(top+bot)/2),abs(rb-(top+bot)/2)))
    else: print(k,'R-pusat %.2f angka-pusat %.2f chip border tak ketemu'%(ra,rb))
for pref in sys.argv[1:]:
    for f in sorted(glob.glob(pref+'_hasil_*.json')):
        k=f.split('_hasil_')[1][:-5]
        if k.endswith('latar'): continue
        run(pref+'_hasil',k)
