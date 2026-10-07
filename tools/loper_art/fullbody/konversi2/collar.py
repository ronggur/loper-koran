# ---- back of the collar visible behind the (removed) neck; collar tips meet the shoulders
C_RIM=hexc('535F8D'); C_IN=hexc('333959'); C_DEEP=hexc('23223F')
LEAF=hexc('6D86A7'); LEAF_D=hexc('576390'); SKIN_D=hexc('DA7244')
T={}
# back of the collar raised 2 px
for x in range(102,104): T[x]=77
for x in range(104,108): T[x]=77
for x in range(108,120): T[x]=78
T[120]=77; T[121]=77; T[122]=78; T[123]=78; T[124]=79
for x in range(125,130): T[x]=80
EL={77:101,78:101,79:101,80:102,81:103,82:104,83:106}
ER={77:122,78:121,79:120,80:119,81:118,82:117,83:117}
for x,t in T.items():
    jx=max(J.get(x,0),73)
    for y in range(jx+1,t):
        img.a[y,x]=0
    img.put(x,t,OUT)
    for y in range(t+1,84):
        if x<=EL[y]: continue
        if x<ER[y]:
            col=C_RIM if y==t+1 else (C_IN if y==t+2 else C_DEEP)
            img.put(x,y,col)
        elif x==ER[y]:
            img.put(x,y,OUT)
        elif y<=81:
            img.put(x,y,LEAF if y==t+1 else LEAF_D)
for x in range(109,116):
    img.put(x,84,SKIN_D)
# shorten the left collar tip so it matches the right one (top at row 78)
for y in range(74,78):
    for x in range(97,102):
        img.a[y,x]=0
for x in range(98,102): img.put(x,78,OUT)
img.put(97,79,OUT)
for x in (99,100): img.put(x,79,hexc('84A6BA'))
img.put(98,79,LEAF)
