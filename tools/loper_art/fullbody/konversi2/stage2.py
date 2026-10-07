import numpy as np, cv2, math
from PIL import Image
idx=np.load(W+'idxmap.npy'); pal=np.load(W+'pal.npy').astype(np.int16)
GH,GW=idx.shape
palL=cv2.cvtColor(pal.reshape(1,-1,3).astype(np.uint8),cv2.COLOR_RGB2LAB).reshape(-1,3).astype(int)
Lp=palL[:,0]*100//255
# ---- orphan cleanup on indices
def cleanup(idx,passes=2,thr=28):
    for _ in range(passes):
        new=idx.copy()
        for y in range(1,GH-1):
            for x in range(1,GW-1):
                c=idx[y,x]
                if c<0: continue
                nb=idx[y-1:y+2,x-1:x+2].reshape(-1); nb=np.delete(nb,4)
                if (nb==c).sum()>0: continue
                fgn=nb[nb>=0]
                if len(fgn)<5: continue
                vals,cnt=np.unique(fgn,return_counts=True)
                m=vals[cnt.argmax()]
                if abs(Lp[m]-Lp[c])<thr: new[y,x]=m
        idx=new
    return idx
idx=cleanup(idx)
np.save(W+'idx_clean.npy',idx)
