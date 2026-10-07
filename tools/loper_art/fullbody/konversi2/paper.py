# ---- crisp "KORAN" masthead on the held newspaper
FONT={'K':["X..X","X.X.","XX..","X.X.","X..X"],'O':[".XX.","X..X","X..X","X..X",".XX."],
      'R':["XXX.","X..X","XXX.","X.X.","X..X"],'A':[".XX.","X..X","XXXX","X..X","X..X"],
      'N':["X..X","XX.X","X.XX","X..X","X..X"]}
BAND=hexc('3A2E3C'); TXT=hexc('EDDEC3')
for y in range(10,17):
    for x in range(156,186): img.put(x,y,BAND)
x0=159
for ch in "KORAN":
    g=FONT[ch]
    for r,row in enumerate(g):
        for c,v in enumerate(row):
            if v=='X': img.put(x0+c,11+r,TXT)
    x0+=5
# yellow wristband on the raised arm
YEL=hexc('FFC94A'); YEL_D=hexc('E98E3F')
for y,col in ((57,YEL),(58,YEL_D)):
    xs=[x for x in range(155,176) if img.a[y,x]]
    if xs:
        for x in range(min(xs)+1,max(xs)):
            img.put(x,y,col)
# ---- drop stray outline fragments lying in the ground shadow
snapa=img.a.copy()
for y in range(245,GH-1):
    for x in range(1,GW-1):
        if not snapa[y,x]: continue
        c=np.array(img.rgb[y,x],np.uint8).reshape(1,1,3); l=int(cv2.cvtColor(c,cv2.COLOR_RGB2LAB)[0,0,0])*100//255
        if l>=26: continue
        nopq=int((snapa[y-1:y+2,x-1:x+2]==255).sum())-1
        if nopq>3: continue
        # any non-dark opaque pixel nearby? if not, it is a stray line
        ok=False
        for yy in range(y-2,y+3):
            for xx in range(x-2,x+3):
                if 0<=yy<GH and 0<=xx<GW and snapa[yy,xx]==255:
                    cc=np.array(img.rgb[yy,xx],np.uint8).reshape(1,1,3)
                    if int(cv2.cvtColor(cc,cv2.COLOR_RGB2LAB)[0,0,0])*100//255>=26: ok=True
        if not ok:
            img.rgb[y,x]=SHADOW; img.a[y,x]=SHA if shad.a[y,x] else 0
