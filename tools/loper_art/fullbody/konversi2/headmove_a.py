# ---- lift the head into its own layer (to curve the jaw and move it down)
HX0,HX1,HY1=60,142,77
HEAD_RGB=img.rgb.copy(); HEAD_A=np.zeros_like(img.a)
for y in range(0,HY1+1):
    for x in range(HX0,HX1):
        if not img.a[y,x]: continue
        if 96<=x<=101 and 74<=y<=77: continue      # left collar tip, not head
        HEAD_A[y,x]=255; img.a[y,x]=0
# curved left jaw: steep under the ear, flatter toward the chin
SK=hexc('EFA462'); SKD=hexc('DA7244')
JAW={67:(100,100),68:(100,100),69:(101,101),70:(102,102),71:(103,103),72:(104,104),73:(105,105),74:(106,107),75:(108,109),76:(110,111)}
for y,(l,r) in JAW.items():
    xs=[x for x in range(95,115) if HEAD_A[y,x]]
    old=min(xs)
    for x in range(l,r+1):
        HEAD_RGB[y,x]=OUT; HEAD_A[y,x]=255
    for x in range(r+1,max(old,r)+1):
        HEAD_RGB[y,x]=SKD if (y>=72 and x==r+1) else SK; HEAD_A[y,x]=255
    if old>r+1 and y>=72:
        pass
HEAD_SHIFT=2
