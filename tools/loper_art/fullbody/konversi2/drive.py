# ---- drivetrain: single cog, chain, chainring with ONE (near-side) crank, rack & fender stays
COG=dict(cx=49.0,cy=220.0); RING=dict(cx=110.5,cy=227.0)
labo=labimg(obj); Lo=labo[...,0]*100//255; ao=labo[...,1]; bo=labo[...,2]
# clear the leg gap region except pants/green/skin and their outlines
NVd=navy_mask(obj)
def is_keep(y,x):
    return obj.a[y,x] and (NVd[y,x] or ao[y,x]<121 or (ao[y,x]>148 and Lo[y,x]>30))
gap=[(y,x) for y in range(212,253) for x in range(99,122)]
kill=[]
for y,x in gap:
    if not obj.a[y,x] or is_keep(y,x): continue
    if Lo[y,x]<26:
        n=any(is_keep(yy,xx) for yy in range(y-1,y+2) for xx in range(x-1,x+2))
        if n and math.hypot(x+0.5-RING['cx'],y+0.5-RING['cy'])>9.6: continue
    kill.append((y,x))
for y,x in kill: obj.a[y,x]=0
def disc(c,w,r0,r1,col):
    for y in range(int(w['cy']-r1-1),int(w['cy']+r1+2)):
        for x in range(int(w['cx']-r1-1),int(w['cx']+r1+2)):
            d=math.hypot(x+0.5-w['cx'],y+0.5-w['cy'])
            if r0<d<=r1: c.put(x,y,col)
drive=Canvas(GH,GW)
# chain runs
def chain_run(p0,p1):
    pts=bresen(*p0,*p1)
    for i,(x,y) in enumerate(pts):
        drive.put(x,y,METAL if i%2==0 else METAL_DK)
        drive.put(x,y+1,OUT)
# cog r~4.6 ; chain hugs top, back (left) and bottom of cog
disc(drive,COG,0,5.6,OUT)
disc(drive,COG,0,4.6,METAL_DK)
for y in range(int(COG['cy'])-6,int(COG['cy'])+7):
    for x in range(int(COG['cx'])-6,int(COG['cx'])+7):
        d=math.hypot(x+0.5-COG['cx'],y+0.5-COG['cy']); ang=math.atan2(y+0.5-COG['cy'],x+0.5-COG['cx'])
        if 3.4<d<=4.6 and int((ang+math.pi)/(2*math.pi)*16)%2==0: drive.put(x,y,METAL)
disc(drive,COG,0,2.4,METAL)
disc(drive,COG,0,1.2,METAL_HI)
# chain wrap on rear half of cog
for y in range(int(COG['cy'])-7,int(COG['cy'])+8):
    for x in range(int(COG['cx'])-7,int(COG['cx'])+2):
        d=math.hypot(x+0.5-COG['cx'],y+0.5-COG['cy'])
        if 4.7<d<=6.4 and x+0.5<=COG['cx']+0.6:
            drive.put(x,y,OUT if d>5.6 else (METAL if (x+y)%2 else METAL_DK))
chain_run((49,214),(110,218))
chain_run((49,225),(110,235))
# chainring r~8.3 with spider cut-outs
disc(drive,RING,0,9.2,OUT)
disc(drive,RING,0,8.2,METAL)
for y in range(int(RING['cy'])-10,int(RING['cy'])+11):
    for x in range(int(RING['cx'])-10,int(RING['cx'])+11):
        d=math.hypot(x+0.5-RING['cx'],y+0.5-RING['cy']); ang=math.atan2(y+0.5-RING['cy'],x+0.5-RING['cx'])
        if 7.0<d<=8.2: drive.put(x,y,METAL_HI if (math.cos(ang+2.36)>0.2) else METAL)
        if 7.0<d<=8.2 and int((ang+math.pi)/(2*math.pi)*28)%2==0: drive.put(x,y,METAL_DK)
        if 3.0<d<=6.0:
            k=(ang+math.pi)/(2*math.pi)*5
            if 0.25<(k%1)<0.75: drive.put(x,y,RIM_DK)
disc(drive,RING,0,2.0,METAL_DK)
# crank arms: thicker and 4 px longer; near side in front of the chainring,
# far side (opposite direction) behind the frame and legs, showing in the gap
def draw_arm(cv,cx,cy,th,L,hi,base,r_core=1.15,r_out=2.05):
    ex,ey=cx+L*math.cos(th),cy+L*math.sin(th)
    ux,uy=math.cos(th),math.sin(th)
    for y in range(int(min(cy,ey))-3,int(max(cy,ey))+4):
        for x in range(int(min(cx,ex))-3,int(max(cx,ex))+4):
            px,py=x+0.5-cx,y+0.5-cy
            t=max(0.0,min(L,px*ux+py*uy))
            qx,qy=cx+ux*t,cy+uy*t
            d=math.hypot(x+0.5-qx,y+0.5-qy)
            side=(x+0.5-qx)*(-uy)+(y+0.5-qy)*ux
            if d<=r_core: cv.put(x,y,hi if side<0 else base)
            elif d<=r_out: cv.put(x,y,OUT)
    return ex,ey
def draw_pedal(cv,ex,ey,body,top):
    pxi,pyi=int(math.floor(ex)),int(math.floor(ey))
    for x in range(pxi-3,pxi+4):
        cv.put(x,pyi-1,OUT); cv.put(x,pyi,top); cv.put(x,pyi+1,body); cv.put(x,pyi+2,OUT)
    for y in (pyi,pyi+1): cv.put(pxi-4,y,OUT); cv.put(pxi+4,y,OUT)
Lc=19
TH_NEAR=math.radians(275); TH_FAR=TH_NEAR-math.pi
fx,fy=draw_arm(back,RING['cx'],RING['cy'],TH_FAR,Lc,METAL,METAL_DK)
draw_pedal(back,fx,fy,RIM_DK,METAL_DK)
arm=Canvas(GH,GW)   # near crank sits in front of the chain guard
nx,ny=draw_arm(arm,RING['cx'],RING['cy'],TH_NEAR,Lc,METAL_HI,METAL)
disc(arm,RING,0,2.2,OUT); disc(arm,RING,0,1.5,METAL_HI)
draw_pedal(arm,nx,ny,METAL_DK,METAL)
# rack stay (rear) and fender stay (front): thin metal rods
for (x,y) in bresen(17,189,46,218): back.put(x,y,RIM_DK)
for (x,y) in bresen(153,214,188,219): back.put(x,y,RIM_DK)
# axle nuts on top layer later
AXLES=[(49,220),(191,220)]
