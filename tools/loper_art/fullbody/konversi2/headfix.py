# ---- remove the neck: head floats with a 3px gap above the collar
def clsf(y,x):
    if img.a[y,x]==0: return '.'
    c=np.array(img.rgb[y,x],np.uint8).reshape(1,1,3)
    l,aa,bb=[int(v) for v in cv2.cvtColor(c,cv2.COLOR_RGB2LAB)[0,0]]
    l=l*100//255
    if l<22: return 'O'
    if aa>140: return 's'
    if bb<122: return 'b'
    return '?'
J={96:65,97:65,98:65,99:66,100:66,101:67,102:68,103:69,104:70,105:71,106:72,107:73,108:74,109:75,110:76,111:76,
   112:77,113:77,114:77,115:77,116:77,117:77,118:76,119:76,120:76,121:75,122:75,123:74,124:73,125:72}
SHIRT_TOP=81
for x,j in J.items():
    for y in range(j+1,SHIRT_TOP):
        k=clsf(y,x)
        if 102<=x<=121:
            img.a[y,x]=0
        elif k=='s':
            img.a[y,x]=0
        elif k=='O':
            nb=[clsf(yy,xx) for yy,xx in ((y-1,x),(y+1,x),(y,x-1),(y,x+1))]
            if 'b' not in nb: img.a[y,x]=0
# outline newly exposed edges (head bottom + shirt top)
snap=img.a.copy()
for y in range(60,96):
    for x in range(94,134):
        if snap[y,x] and any(snap[yy,xx]==0 for yy,xx in ((y-1,x),(y+1,x),(y,x-1),(y,x+1))):
            img.put(x,y,OUT)
# back of the collar shows inside the V, with a little shadow on the chest under it
COLLAR_IN=hexc('535F8D'); SKIN_SH=hexc('DA7244')
for x in range(103,121):
    if clsf(82,x)=='s': img.put(x,82,COLLAR_IN)
    if clsf(83,x)=='s': img.put(x,83,SKIN_SH)
# thin the chin outline to 1px; keep one row of soft shade above it
SKIN=hexc('F0A563'); SKIN_D=hexc('DA7244')
snap=img.a.copy()
def bnd(y,x): return snap[y,x] and any(snap[yy,xx]==0 for yy,xx in ((y-1,x),(y+1,x),(y,x-1),(y,x+1)))
for x in range(106,123):
    for y in range(72,78):
        if snap[y,x] and clsf(y,x) in ('O','s') and not bnd(y,x):
            c=np.array(img.rgb[y,x],np.uint8).reshape(1,1,3); l=int(cv2.cvtColor(c,cv2.COLOR_RGB2LAB)[0,0,0])*100//255
            if l<45:
                below_bnd = y+1<GH and bnd(y+1,x)
                img.put(x,y,SKIN_D if below_bnd else SKIN)
for x in range(105,121):
    if clsf(83,x)=='s': img.put(x,83,SKIN_D)
