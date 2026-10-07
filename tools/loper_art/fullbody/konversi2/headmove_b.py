# ---- paste the head 2 px lower, in front of the collar
for y in range(GH-1,-1,-1):
    for x in range(HX0,HX1):
        if HEAD_A[y,x]:
            img.put(x,y+HEAD_SHIFT,tuple(HEAD_RGB[y,x]))
