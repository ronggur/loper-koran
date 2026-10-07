# ---- three brake cables -> two: drop the middle cable that splits off the outer loop
def dark(y,x):
    if not img.a[y,x]: return False
    c=np.array(img.rgb[y,x],np.uint8).reshape(1,1,3)
    return int(cv2.cvtColor(c,cv2.COLOR_RGB2LAB)[0,0,0])*100//255<22
drop=[(125,171),(125,172),(125,173),(126,171),(126,172),(126,173),(127,173),(127,174),(128,174),
      (149,173),(150,172),(150,173),(151,171),(151,172),(152,171),(153,170),(153,171),(154,170),(155,169)]
for y in range(129,149):          # outer loop was two cables side by side: keep it 2 px wide
    xs=[x for x in range(172,179) if dark(y,x)]
    if len(xs)>2:
        for x in xs[:-2]: drop.append((y,x))
for y,x in drop:
    if dark(y,x): img.a[y,x]=0
