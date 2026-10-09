"""Animasi lempar koran (usulan): lengan dan koran digambar di atas frame kayuh.

    python3 tools/loper_art/lempar.py docs/design/character/loper_agen/loper_agen.png build/loper_art/lempar.png

Menulis sheet 4 x 18 dan <keluaran>.rows.json (nama animasi dan baris sumber).
Belum dari renderer model (produce.py); lihat docs/design/character/loper_agen/lempar/README.md.
Metadata JSON dan GIF pratinjau di folder itu disusun dari sheet ini.
"""
import sys, math, json
from PIL import Image
SRC, OUT = sys.argv[1], sys.argv[2]
sh = Image.open(SRC).convert('RGBA')
CW, CH = 46, 58
OL = (14,10,28,255); SHADOW=(0,0,0,71); T=(0,0,0,0)
SK_L=(242,185,140,255); SK=(232,160,122,255); SK_D=(180,124,95,255)
SH_L=(155,196,216,255); SH=(95,150,200,255); SH_D=(70,110,140,255)
PAP_W=(255,255,255,255); PAP=(251,246,232,255); PAP_D=(194,175,134,255); BAND=(153,69,50,255)
SKINS={SK_L,SK,SK_D}

# konfigurasi per baris sumber: bahu kiri/kanan, kotak hapus lengan, apakah lengan di depan badan
N_L = [((-8,4),(-9,12),'down'),((-4,-2),(-3,-8),'up'),((-6,-2),(-11,-5),'out'),((-6,-1),(-11,-3),None)]
N_R = [((-3,6),(-8,11),'down'),((-4,3),(-9,4),'back'),((4,3),(8,5),'out'),((4,3),(8,6),None)]
PSK_L = [((-6,4),(-9,11),'down'),((-3,-3),(-2,-9),'up'),((-5,-3),(-10,-7),'out'),((-5,-2),(-10,-5),None)]
PSK_R = [((-4,5),(-9,9),'down'),((-5,1),(-9,-1),'back'),((4,4),(8,8),'out'),((4,4),(8,9),None)]
SKI_L = [((-3,6),(0,14),'down'),((-4,-2),(-4,-8),'up'),((-6,-2),(-11,-5),'out'),((-6,-1),(-11,-3),None)]
SKI_R = [((2,6),(-1,14),'down'),((4,-1),(5,-7),'up'),((5,3),(10,6),'out'),((5,3),(9,7),None)]
ROWS = [
 # (heading, speed, row, ls, rs, erase_L, erase_R, front_L, poses_L, poses_R)
 ('normal','santai',0,(19,19),(29,20),None,(27,19,40,31),False,N_L,N_R),
 ('normal','cepat',5,(21,21),(31,22),None,(28,21,40,31),False,N_L,N_R),
 ('normal','ngebut',10,(24,17),(32,19),None,(26,19,40,31),False,N_L,N_R),
 ('serong_kanan','santai',1,(17,20),(24,22),None,(20,21,38,32),False,PSK_L,PSK_R),
 ('serong_kanan','cepat',6,(24,22),(27,24),None,(14,24,40,33),False,PSK_L,PSK_R),
 ('serong_kanan','ngebut',11,(26,20),(29,21),None,(14,22,40,32),False,PSK_L,PSK_R),
 ('serong_kiri','santai',3,(15,19),(28,19),(12,20,17,28),(26,20,31,28),True,SKI_L,SKI_R),
 ('serong_kiri','cepat',8,(16,19),(29,19),(13,20,18,29),(27,20,32,29),True,SKI_L,SKI_R),
 ('serong_kiri','ngebut',13,(15,15),(28,15),(12,16,18,27),(26,16,31,24),True,SKI_L,SKI_R),
]

def seg_dist(px,py,a,b):
    ax,ay=a; bx,by=b; dx,dy=bx-ax,by-ay
    L=dx*dx+dy*dy
    t=0 if L==0 else max(0,min(1,((px-ax)*dx+(py-ay)*dy)/L))
    cx,cy=ax+t*dx,ay+t*dy
    return math.hypot(px-cx,py-cy), t, (px-cx, py-cy)

def draw_arm(im, sh_pt, el, hd, front):
    W,H=im.size
    core={}
    segs=[(sh_pt,el,0),(el,hd,1)]
    for y in range(H):
        for x in range(W):
            best=None
            for a,b,i in segs:
                d,t,(ox,oy)=seg_dist(x,y,a,b)
                if d<=(1.45 if i==0 else 1.2) and (best is None or d<best[0]): best=(d,t,i,ox,oy)
            if best:
                d,t,i,ox,oy=best
                light = (-ox - oy)  # cahaya dari kiri atas
                if i==0 and t<0.55:
                    c = SH_L if light>0.5 else (SH_D if light<-0.5 else SH)
                else:
                    c = SK_L if light>0.5 else (SK_D if light<-0.5 else SK)
                core[(x,y)]=c
    # tangan: 2x2 di ujung
    hx,hy=hd
    for dx in (0,1):
        for dy in (0,1):
            core[(hx+dx-1,hy+dy)] = SK if dx==0 else SK_D
    paint(im, core, front)

BODY={(155,196,216,255),(95,150,200,255),(70,110,140,255),(92,106,140,255),(64,74,98,255),(116,128,163,255),(51,59,78,255)}
HEADC={(255,255,255,255),(242,231,201,255),(251,246,232,255),(42,30,23,255),(232,160,122,255),(180,124,95,255),(242,185,140,255)}
def occluder(im,p):
    W,H=im.size
    x,y=p; a=im.getpixel(p)
    if a in BODY: return True
    if a in HEADC and y<18: return True
    if a==OL:
        for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
            q=(x+dx,y+dy)
            if 0<=q[0]<W and 0<=q[1]<H:
                b=im.getpixel(q)
                if b in BODY or (b in HEADC and q[1]<18): return True
    return False
def paint(im, core, front):
    W,H=im.size
    occ=None
    if not front:
        occ={(x,y) for y in range(H) for x in range(W) if occluder(im,(x,y))}
    def can(p):
        if not (0<=p[0]<W and 0<=p[1]<H): return False
        if front: return True
        return p not in occ
    for p,c in core.items():
        if can(p): im.putpixel(p,c)
    for (x,y) in list(core):
        for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
            q=(x+dx,y+dy)
            if q in core or not (0<=q[0]<W and 0<=q[1]<H): continue
            if front or q not in occ:
                im.putpixel(q,OL)

def roll(x0,y0,w=6):
    core={}
    for i in range(w):
        core[(x0+i,y0)]=PAP_W
        core[(x0+i,y0+1)]=PAP
        core[(x0+i,y0+2)]=PAP_D
    core[(x0+w//2,y0)]=BAND; core[(x0+w//2,y0+1)]=BAND; core[(x0+w//2,y0+2)]=(119,53,39,255)
    return core

def paper(im, hd, kind, front):
    hx,hy=hd
    if kind=='down':   core=roll(hx-4,hy+1)
    elif kind=='up':   core=roll(hx-3,hy-4)
    elif kind=='back': core=roll(hx-5,hy-2)
    else:
        left = hd[0]<23
        core=roll(hx-7,hy-4) if left else roll(hx+1,hy+2,5)
    paint(im, core, True)

def erase_right_arm(im, box):
    x0,y0,x1,y1=box
    gone=set()
    for y in range(y0,y1+1):
        for x in range(x0,x1+1):
            if im.getpixel((x,y)) in SKINS:
                im.putpixel((x,y),T); gone.add((x,y))
    # buang garis luar yang hanya membungkus lengan
    changed=True
    while changed:
        changed=False
        for y in range(y0,y1+1):
            for x in range(x0,x1+1):
                if im.getpixel((x,y))!=OL: continue
                nb=[im.getpixel((x+dx,y+dy)) for dx,dy in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1))]
                solid=[c for c in nb if c[3]>0 and c not in (OL,SHADOW)]
                if not solid:
                    im.putpixel((x,y),T); changed=True
    # tutup tepi badan yang terbuka
    for y in range(y0,y1+1):
        for x in range(x0,x1+1):
            c=im.getpixel((x,y))
            if c[3]==0 or c in (OL,SHADOW): continue
            for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                if im.getpixel((x+dx,y+dy))[3]==0 and (x+dx,y+dy) in gone:
                    im.putpixel((x,y),OL); break

rows=[]
order=[]
for hd in ('normal','serong_kanan','serong_kiri'):
    for sp in ('santai','cepat','ngebut'):
        for side in ('kiri','kanan'):
            order.append((hd,sp,side))
cfgmap={(r[0],r[1]):r for r in ROWS}
for hd,sp,side in order:
    _,_,row,ls,rs,eL,eR,frontL,PL,PR=cfgmap[(hd,sp)]
    frames=[]
    poses = PL if side=='kiri' else PR
    for i,(el,hd_,pk) in enumerate(poses):
        fr=sh.crop((i*CW,row*CH,(i+1)*CW,(row+1)*CH))
        if side=='kiri':
            s0=ls; front=frontL
            if eL: erase_right_arm(fr,eL)
        else:
            s0=rs; front=True
            if eR: erase_right_arm(fr,eR)
        E=(s0[0]+el[0],s0[1]+el[1]); H=(s0[0]+hd_[0],s0[1]+hd_[1])
        draw_arm(fr,s0,E,H,front)
        if pk: paper(fr,H,pk,front)
        frames.append(fr)
    rows.append((f'lempar_{side}_{sp}_{hd}',frames,row))
out=Image.new('RGBA',(CW*4,CH*len(rows)),T)
for r,(name,frames,_) in enumerate(rows):
    for c,f in enumerate(frames): out.paste(f,(c*CW,r*CH))
out.save(OUT)
json.dump([[n,src] for n,_,src in rows],open(OUT+'.rows.json','w'))
print([n for n,_,_ in rows])
