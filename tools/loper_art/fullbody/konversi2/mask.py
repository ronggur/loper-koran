import numpy as np, cv2
from PIL import Image
src=cv2.imread(W+'src.jpg')[:,:,::-1]
blur=cv2.medianBlur(src,5).astype(np.int16)
R,G,B=blur[...,0],blur[...,1],blur[...,2]
bgc=((np.abs(R-109)<13)&(np.abs(G-61)<9)&(np.abs(B-32)<9)).astype(np.uint8)
n,lab,stats,_=cv2.connectedComponentsWithStats(bgc,8)
bg=np.zeros_like(bgc)
keep=np.where(stats[:,cv2.CC_STAT_AREA]>250)[0]
keep=keep[keep>0]
bg=np.isin(lab,keep).astype(np.uint8)
fg=1-bg
n,lab,stats,_=cv2.connectedComponentsWithStats(fg,8)
small=np.where(stats[:,cv2.CC_STAT_AREA]<400)[0]
fg[np.isin(lab,small)]=0
bg=1-fg
np.save(W+'bg.npy',bg)
Image.fromarray((bg*255).astype(np.uint8)).resize((896,1120)).save(W+'bgmask.png')
print(bg.mean())
