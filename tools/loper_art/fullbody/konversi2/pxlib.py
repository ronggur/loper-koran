import numpy as np, math, cv2
def hexc(h): h=h.lstrip('#'); return tuple(int(h[i:i+2],16) for i in (0,2,4))
OUT=hexc('1B1226')
def lab_L(rgb):
    a=np.array(rgb,np.uint8).reshape(1,1,3); return int(cv2.cvtColor(a,cv2.COLOR_RGB2LAB)[0,0,0])*100//255
class Canvas:
    def __init__(s,h,w):
        s.rgb=np.zeros((h,w,3),np.uint8); s.a=np.zeros((h,w),np.uint8); s.h=h; s.w=w
    def put(s,x,y,c,a=255):
        if 0<=x<s.w and 0<=y<s.h:
            s.rgb[y,x]=c; s.a[y,x]=a
    def get(s,x,y):
        return tuple(s.rgb[y,x]) if s.a[y,x] else None
    def clear(s,x,y):
        if 0<=x<s.w and 0<=y<s.h: s.a[y,x]=0
    def line(s,x0,y0,x1,y1,c,a=255,pattern=None):
        pts=bresen(x0,y0,x1,y1)
        for i,(x,y) in enumerate(pts):
            if pattern is None: s.put(x,y,c,a)
            else:
                cc=pattern[i%len(pattern)]
                if cc is not None: s.put(x,y,cc,a)
        return pts
    def rgba(s):
        return np.dstack([s.rgb,s.a])
def bresen(x0,y0,x1,y1):
    x0,y0,x1,y1=map(int,map(round,(x0,y0,x1,y1)))
    pts=[]; dx=abs(x1-x0); dy=-abs(y1-y0); sx=1 if x0<x1 else -1; sy=1 if y0<y1 else -1; err=dx+dy
    while True:
        pts.append((x0,y0))
        if x0==x1 and y0==y1: break
        e2=2*err
        if e2>=dy: err+=dy; x0+=sx
        if e2<=dx: err+=dx; y0+=sy
    return pts
def composite(base,top):
    # base, top: Canvas; alpha-over (top alpha 255 only or alpha<255 blended)
    m=top.a>0
    out=Canvas(base.h,base.w); out.rgb=base.rgb.copy(); out.a=base.a.copy()
    full=top.a==255
    out.rgb[full]=top.rgb[full]; out.a[full]=255
    part=m&~full
    if part.any():
        ta=top.a[part][:,None]/255.0; ba=out.a[part][:,None]/255.0
        oa=ta+ba*(1-ta)
        out.rgb[part]=((top.rgb[part]*ta+out.rgb[part]*ba*(1-ta))/np.maximum(oa,1e-6)).astype(np.uint8)
        out.a[part]=(oa[:,0]*255).astype(np.uint8)
    return out
