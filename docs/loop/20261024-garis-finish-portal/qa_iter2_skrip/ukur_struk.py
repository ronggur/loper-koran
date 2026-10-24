import json,sys
import numpy as np
from PIL import Image
def hexrgb(h): h=h.lstrip('#'); return np.array([int(h[i:i+2],16) for i in (0,2,4)],float)
def ink(img,rect,warna,s,tol=60):
    x,y,w,h=[int(round(v*s)) for v in rect]
    sub=np.asarray(img.convert('RGB'),float)[max(y-6,0):y+h+6,max(x-6,0):x+w+6]
    d=np.linalg.norm(sub-hexrgb(warna),axis=2)
    m=d<tol
    return m,(max(x-6,0),max(y-6,0))
def baseline(m):
    cnt=m.sum(axis=1)
    if cnt.max()==0: return None
    rows=np.where(cnt>=0.3*cnt.max())[0]
    return rows.max()+1
def main(pref,keadaan):
    d=json.load(open(f'{pref}_{keadaan}.json')); img=Image.open(f'{pref}_{keadaan}.png'); s=img.width/d['viewport'][0]
    T=d['teks']
    out=[]
    used=set()
    for i,a in enumerate(T):
        for j,b in enumerate(T):
            if i>=j: continue
            ay=a['rect'][1]+a['rect'][3]/2; by=b['rect'][1]+b['rect'][3]/2
            same_col=(a['rect'][0]<520)==(b['rect'][0]<520)
            if abs(ay-by)<=7 and same_col and a['rect'][0]<b['rect'][0] and a['rect'][0]+a['rect'][2]<=b['rect'][0]+2:
                ma,oa=ink(img,a['rect'],a['warna'],s); mb,ob=ink(img,b['rect'],b['warna'],s)
                ba=baseline(ma); bb=baseline(mb)
                if ba is None or bb is None: continue
                ya=(oa[1]+ba)/s; yb=(ob[1]+bb)/s
                cols=np.where(mb.any(axis=0))[0]
                xr=(ob[0]+cols.max()+1)/s if len(cols) else None
                out.append((a['teks'][:22],b['teks'][:24],round(ya,2),round(yb,2),round(ya-yb,2),round(xr,2) if xr else None,round(b['rect'][0]+b['rect'][2],2)))
    for o in out: print(o)
if __name__=='__main__': main(sys.argv[1],sys.argv[2])
