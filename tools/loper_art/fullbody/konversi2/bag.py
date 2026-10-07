# ---- open pannier bag with rolled newspapers inside (drawn on img)
RED_HL=hexc('DA7244'); RED_L=hexc('C25538'); RED=hexc('AD3D32'); RED_D=hexc('7D2C25'); RED_DD=hexc('531A14'); RED_IN=hexc('301616')
P_W=hexc('FBF6E8'); P_L=hexc('EDDEC3'); P_M=hexc('D6C3B4'); P_S=hexc('A79A9B'); INK=hexc('61505F'); INK_D=hexc('42333A')
BX0,BX1,BY0,BY1=27,65,170,203   # front panel box (outline incl.)
BACKTOP=164
def P(x,y,c): img.put(x,y,c)
# back wall + folded-back flap (rolled lip along the back top edge)
for x in range(BX0,BX1+1):
    for y in range(BACKTOP,BY0):
        if y==BACKTOP: col=OUT if BX0+1<x<BX1-1 else None
        elif y==BACKTOP+1: col=RED_L if BX0<x<BX1 else (OUT if x in (BX0+1,BX1-1) else None)
        elif y==BACKTOP+2: col=RED if BX0<x<BX1 else OUT
        elif y==BACKTOP+3: col=OUT if x in (BX0,BX1) else RED_DD
        else: col=OUT if x in (BX0,BX1) else (RED_IN if y>=BY0-2 else RED_DD)
        if col: P(x,y,col)
for x in (BX0+1,BX1-1): P(x,BACKTOP+1,OUT)
# rolled newspapers standing in the bag, only their upper part shows
def roll(x0,top,w,tilt,band=None,photo=None,seed=0):
    for y in range(top,BY0+1):
        off=int(round((BY0-y)*tilt))
        xl=x0+off; xr=x0+off+w-1
        r=y-top
        for x in range(xl,xr+1):
            rel=(x-xl)/(w-1)
            if r==0:
                if x in (xl,xr): continue
                col=OUT
            elif x==xl or x==xr: col=OUT
            elif r==1: col=P_M if x in (xl+1,xr-1) else P_L   # rolled end
            else:
                col=P_W if rel<0.4 else (P_L if rel<0.75 else P_M)
                if x==xr-1: col=P_S
                if r>=3 and (r+seed)%2==0 and xl+1<x<xr-1 and (x*3+r+seed)%5!=0: col=P_S if rel<0.7 else INK
                if photo and photo[0]<=r<=photo[1] and xl+2<=x<=xr-2: col=INK if r==photo[0] else INK_D
                if band and band[0]<=r<=band[1]: col=RED if x not in (xl,xr) else OUT
                if band and r==band[0] and x not in (xl,xr): col=RED_L
            P(x,y,col)
        if r==1:
            P((xl+xr)//2,y,P_S)
roll(29,154,8,0.26,seed=2,band=(8,9))
roll(48,151,8,-0.06,photo=(6,9),seed=1)
roll(38,149,8,0.04,seed=3)
roll(55,156,8,-0.24,seed=4,band=(5,6))
# corners of the lip
P(BX0+1,BACKTOP,None) if False else None
# front panel
for y in range(BY0,BY1+1):
    for x in range(BX0,BX1+1):
        edge = x in (BX0,BX1) or y in (BY0,BY1)
        corner=(y>=BY1-1 and (x<=BX0+1 or x>=BX1-1)) or (y==BY1-2 and x in (BX0,BX1))
        if (y==BY1 and (x<=BX0+1 or x>=BX1-1)): continue
        if corner and not (y==BY1-1 and x in (BX0+1,BX1-1)) and not (y==BY1-2 and x in (BX0,BX1)):
            P(x,y,OUT); continue
        if edge or (y==BY1-1 and x in (BX0+1,BX1-1)) or (y==BY1-2 and x in (BX0,BX1)):
            P(x,y,OUT); continue
        col=RED
        if y==BY0+1: col=RED_HL if x<BX1-3 else RED_L
        elif x==BX0+1: col=RED_L
        elif x==BX1-1 or y>=BY1-2: col=RED_D
        elif x==BX1-2 and y>BY0+2: col=RED_D if y%2 else RED
        # stitching (dashed), inset 2px
        if (x==BX0+3 or x==BX1-3) and BY0+3<=y<=BY1-3 and y%2==0: col=RED_D
        if (y==BY0+3 or y==BY1-3) and BX0+3<=x<=BX1-3 and x%2==0: col=RED_D
        P(x,y,col)
# small metal label
for x in range(43,49):
    P(x,176,OUT); P(x,178,OUT)
    P(x,177,P_M if x<46 else P_S)
P(42,177,OUT); P(49,177,OUT)
# two body straps with empty buckles (flap is open, nothing threaded)
def strap(x0):
    # strap 4px wide x0..x0+3, from y 184 to 196, rounded tip
    for y in range(184,197):
        for x in range(x0,x0+4):
            col=OUT if x in (x0,x0+3) else (RED_DD if x==x0+2 else RED_D)
            if y==196 and x in (x0,x0+3): continue
            if y==196: col=OUT
            P(x,y,col)
    # stitch dots
    P(x0+1,193,RED); P(x0+1,190,RED)
    # buckle frame 6x6 at y 180..185
    for y in range(180,186):
        for x in range(x0-1,x0+5):
            if x in (x0-1,x0+4) or y in (180,185):
                P(x,y,OUT)
            elif x in (x0,x0+3) or y in (181,184):
                P(x,y,METAL_HI if (x==x0 or y==181) else METAL)
    # empty centre shows strap / panel
    P(x0+1,182,RED_DD); P(x0+2,182,RED_DD); P(x0+1,183,RED_D); P(x0+2,183,RED_D)
    # prong
    P(x0+1,182,METAL_DK)
strap(33); strap(54)
