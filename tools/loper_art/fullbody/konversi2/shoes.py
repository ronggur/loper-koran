# ---- tidy the left shoe laces (front-facing shoe)
SHOE=hexc('46353D'); SHOE_D=hexc('362B36'); LACE=hexc('EDDEC3'); LACE_D=hexc('C4A59C')
for y in range(264,278):
    for x in range(81,95):
        if img.a[y,x]:
            c=np.array(img.rgb[y,x],np.uint8).reshape(1,1,3); l=int(cv2.cvtColor(c,cv2.COLOR_RGB2LAB)[0,0,0])*100//255
            inner=all(img.a[yy,xx] for yy,xx in ((y-1,x),(y+1,x),(y,x-1),(y,x+1)))
            if inner and (l<20 or l>55): img.put(x,y,SHOE if x<91 else SHOE_D)
for y,(a,b) in {266:(84,91),268:(83,91),270:(83,90),272:(84,90),274:(85,89)}.items():
    for x in range(a,b+1): img.put(x,y,LACE if x<b-1 else LACE_D)
    img.put(a-1,y,OUT); img.put(b+1,y,OUT)
# lace holes / eyelet shadows between bars
for y in (267,269,271,273):
    img.put(83 if y<272 else 84,y,OUT); img.put(91 if y<270 else 90,y,OUT)
