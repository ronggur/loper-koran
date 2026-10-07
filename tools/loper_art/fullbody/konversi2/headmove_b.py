# ---- paste the head 2 px lower, in front of the collar
# (also kept as its own layer, so the head can be swapped for portrait expressions)
PRE_RGB=img.rgb.copy(); PRE_A=img.a.copy()
HEAD_LAYER=Canvas(GH,GW)
for y in range(GH-1,-1,-1):
    for x in range(HX0,HX1):
        if HEAD_A[y,x]:
            img.put(x,y+HEAD_SHIFT,tuple(HEAD_RGB[y,x]))
            HEAD_LAYER.put(x,y+HEAD_SHIFT,tuple(HEAD_RGB[y,x]))
