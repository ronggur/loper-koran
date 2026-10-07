import numpy as np, cv2, math, sys, os
from PIL import Image
sys.path.insert(0,HERE)
from pxlib import *
idx=np.load(W+'idx_clean.npy'); pal=np.load(W+'pal.npy').astype(np.uint8)
GH,GW=idx.shape
obj=Canvas(GH,GW)
m=idx>=0
obj.rgb[m]=pal[idx[m]]; obj.a[m]=255
SHADOW=hexc('2E3550'); SHA=96
shad=Canvas(GH,GW); s=idx==-2; shad.rgb[s]=SHADOW; shad.a[s]=SHA
labimg=lambda c: cv2.cvtColor(c.rgb.reshape(1,-1,3),cv2.COLOR_RGB2LAB).reshape(c.h,c.w,3).astype(int)
def Lof(c): return labimg(c)[...,0]*100//255
# ---------- unify dark outlines on silhouette
def outline_pass(c):
    L=Lof(c)
    A=c.a>0
    nb=np.zeros_like(A)
    pad=np.pad(A,1)
    edge=A&~(pad[:-2,1:-1]&pad[2:,1:-1]&pad[1:-1,:-2]&pad[1:-1,2:])
    ys,xs=np.where(edge)
    for y,x in zip(ys,xs):
        c.rgb[y,x]=OUT
outline_pass(obj)
# ---------- wheels
WR=dict(cx=49.0,cy=220.0); WF=dict(cx=191.0,cy=220.0); RAD=44
TIRE_HI=hexc('3D2F40'); TIRE=hexc('2B2133'); RIM_HI=hexc('C9C0C6'); RIM_MID=hexc('8E8290'); RIM_DK=hexc('5C5262')
SPOKE_N=hexc('BDB3BB'); SPOKE_F=hexc('7D7280'); METAL_HI=hexc('D8D0D4'); METAL=hexc('A29AA4'); METAL_DK=hexc('6A6170')
def navy_mask(cv):
    r=cv.rgb[...,0].astype(int); g=cv.rgb[...,1].astype(int); b=cv.rgb[...,2].astype(int)
    return (b-r>=14)&(b>45)&(b>g+5)&(cv.a>0)
def dist(x,y,w): return math.hypot(x+0.5-w['cx'],y+0.5-w['cy'])
def keep_mask(c,w,pants_x=None):
    lab=labimg(c); L=lab[...,0]*100//255; a=lab[...,1]; b=lab[...,2]
    NV=navy_mask(c)
    K=np.zeros((GH,GW),bool)
    for y in range(GH):
        for x in range(GW):
            if not c.a[y,x]: continue
            d=dist(x,y,w)
            if d>RAD+0.5: K[y,x]=True; continue
            green=a[y,x]<121 and L[y,x]>14
            red=a[y,x]>148 and L[y,x]>30
            navy=pants_x is not None and x>=pants_x and NV[y,x]
            if green or red or navy: K[y,x]=True
    # dark pixels adjacent to kept colored pixels (inside disc)
    K2=K.copy()
    for y in range(1,GH-1):
        for x in range(1,GW-1):
            if c.a[y,x] and not K[y,x] and L[y,x]<26 and dist(x,y,w)<=RAD+0.5:
                n=K[y-1:y+2,x-1:x+2]
                # neighbours that are colored (inside disc) keep this outline
                if n.any(): K2[y,x]=True
    return K2
def clear_disc(c,w,pants_x=None):
    K=keep_mask(c,w,pants_x)
    for y in range(GH):
        for x in range(GW):
            if c.a[y,x] and not K[y,x] and dist(x,y,w)<=RAD+0.5: c.a[y,x]=0
clear_disc(obj,WR,pants_x=70)
clear_disc(obj,WF)
back=Canvas(GH,GW)
def draw_wheel(c,w,nsp=18,rot=0.0):
    cx,cy=w['cx'],w['cy']
    # spokes first
    for i in range(nsp):
        t0=rot+2*math.pi*i/nsp
        near=i%2==0
        t1=t0+(0.16 if near else -0.16)
        x0=cx+3.0*math.cos(t0); y0=cy+3.0*math.sin(t0)
        x1=cx+34.0*math.cos(t1); y1=cy+34.0*math.sin(t1)
        for (x,y) in bresen(x0-0.5,y0-0.5,x1-0.5,y1-0.5):
            if dist(x,y,w)<=34.4:
                if near or c.a[y,x]==0: c.put(x,y,SPOKE_N if near else SPOKE_F)
    R0=int(cx-RAD-2); R1=int(cx+RAD+2); C0=int(cy-RAD-2); C1=int(cy+RAD+2)
    for y in range(C0,C1):
        for x in range(R0,R1):
            d=dist(x,y,w)
            ang=math.atan2(y+0.5-cy,x+0.5-cx)
            if 43.0<d<=44.0: c.put(x,y,OUT)
            elif 38.0<d<=43.0:
                col=TIRE_HI if d>40.6 else TIRE
                # tread: small dark notches on outer band
                if d>41.8 and int((ang+math.pi)*44/1.6)%2==0: col=TIRE
                c.put(x,y,col)
            elif 37.0<d<=38.0: c.put(x,y,OUT)
            elif 35.6<d<=37.0:
                # light from upper-left: dim the lower-right
                lit=math.cos(ang-(-2.36))
                c.put(x,y,RIM_HI if lit>-0.55 else RIM_MID)
            elif 34.5<d<=35.6: c.put(x,y,RIM_MID)
            elif 33.6<d<=34.5: c.put(x,y,RIM_DK)
            elif d<=2.6: c.put(x,y,METAL_HI if (x+0.5-cx)+(y+0.5-cy)<0 else METAL)
            elif d<=3.6: c.put(x,y,OUT)
draw_wheel(back,WR,nsp=24,rot=0.1)
draw_wheel(back,WF,nsp=24,rot=0.25)
# ---- band cleanup just outside tires (leftover tire outline / ground contact)
def band_clean(c,w):
    lab=labimg(c); L=lab[...,0]*100//255; a=lab[...,1]; b=lab[...,2]
    NV=navy_mask(c)
    for y in range(GH):
        for x in range(GW):
            if not c.a[y,x] or NV[y,x]: continue
            d=dist(x,y,w)
            if 43.0<d<=48.5 and L[y,x]<30:
                n=[(yy,xx) for yy in range(y-1,y+2) for xx in range(x-1,x+2) if c.a[yy,xx] and (((a[yy,xx]<121 or a[yy,xx]>148) and L[yy,xx]>26) or NV[yy,xx])]
                if not n: c.a[y,x]=0
band_clean(obj,WR); band_clean(obj,WF)
exec(open(os.path.join(HERE,'drive.py')).read())

np.save(W+'stage_obj_rgb.npy',obj.rgb); np.save(W+'stage_obj_a.npy',obj.a)
np.save(W+'stage_back_rgb.npy',back.rgb); np.save(W+'stage_back_a.npy',back.a)
np.save(W+'stage_sh_rgb.npy',shad.rgb); np.save(W+'stage_sh_a.npy',shad.a)
labq=labimg(obj); Lq=labq[...,0]*100//255; aq=labq[...,1]
for y in range(146,206):
    for x in range(16,72):
        if not obj.a[y,x]: continue
        green=aq[y,x]<121 and Lq[y,x]>14
        gadj=Lq[y,x]<26 and any(aq[yy,xx]<121 and Lq[yy,xx]>14 and obj.a[yy,xx] for yy in range(y-1,y+2) for xx in range(x-1,x+2))
        inbag=25<=x<=67 and 163<=y<=205
        if inbag: obj.a[y,x]=0; continue
        if y<166 and not (x>=66 and (green or gadj)): obj.a[y,x]=0
base=composite(composite(shad,back),obj)
# drivetrain goes over the frame, but under the legs and under the chain guard
labb=labimg(obj); Lb=labb[...,0]*100//255; ab=labb[...,1]; bb=labb[...,2]
NVo=navy_mask(obj)
def char_px(y,x):
    return bool(x>=70 and NVo[y,x])
dm=drive.a>0
for y,x in zip(*np.where(dm)):
    hide=char_px(y,x) or (x>=70 and Lb[y,x]<26 and obj.a[y,x] and any(char_px(yy,xx) for yy in range(y-1,y+2) for xx in range(x-1,x+2)))
    if 56<=x<=90 and 209<=y<=217 and obj.a[y,x]: hide=True
    if hide: drive.a[y,x]=0
# the green chain guard covers the chainring (but not the crank arm)
def green_px(y,x): return obj.a[y,x] and ab[y,x]<121 and Lb[y,x]>14
for y,x in zip(*np.where(drive.a>0)):
    if 100<=x<=122 and 204<=y<=240 and obj.a[y,x]:
        if green_px(y,x) or (Lb[y,x]<26 and any(green_px(yy,xx) for yy in range(y-1,y+2) for xx in range(x-1,x+2))):
            drive.a[y,x]=0
img=composite(base,drive)
for y,x in zip(*np.where(arm.a>0)):
    if char_px(y,x) or (x>=70 and Lb[y,x]<26 and obj.a[y,x] and any(char_px(yy,xx) for yy in range(y-1,y+2) for xx in range(x-1,x+2))):
        arm.a[y,x]=0
img=composite(img,arm)
exec(open(os.path.join(HERE,'bag.py')).read())
exec(open(os.path.join(HERE,'headfix.py')).read())
exec(open(os.path.join(HERE,'headmove_a.py')).read())
exec(open(os.path.join(HERE,'collar.py')).read())
exec(open(os.path.join(HERE,'headmove_b.py')).read())
exec(open(os.path.join(HERE,'cables.py')).read())
exec(open(os.path.join(HERE,'paper.py')).read())
exec(open(os.path.join(HERE,'shoes.py')).read())
# dropout tip over the cog
for (x,y) in [(51,219),(52,219),(51,220),(52,220),(53,220)]: img.put(x,y,hexc('3B7E51'))
for (ax,ay) in AXLES:
    for dy in (-1,0):
        for dx in (-1,0):
            img.put(ax+dx,ay+dy,METAL_HI if (dx,dy)==(-1,-1) else METAL)
    for (x,y) in [(ax-2,ay-1),(ax-2,ay),(ax+1,ay-1),(ax+1,ay),(ax-1,ay-2),(ax,ay-2),(ax-1,ay+1),(ax,ay+1)]:
        img.put(x,y,OUT)
Image.fromarray(img.rgba()).save(W+'comp1x.png')
# head and body layers: body keeps what lies under the head (back of the collar)
body=Canvas(GH,GW); body.rgb=img.rgb.copy(); body.a=img.a.copy()
hm=HEAD_LAYER.a>0
body.rgb[hm]=PRE_RGB[hm]; body.a[hm]=PRE_A[hm]
Image.fromarray(body.rgba()).save(W+'layer_badan.png')
Image.fromarray(HEAD_LAYER.rgba()).save(W+'layer_kepala.png')
