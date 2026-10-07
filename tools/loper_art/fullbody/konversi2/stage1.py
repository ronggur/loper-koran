# Stage 1: base conversion -> base_clean.png (RGBA, shadow separate) 
import numpy as np, cv2
from PIL import Image
from sklearn.cluster import MiniBatchKMeans
src=cv2.imread(W+'src.jpg')[:,:,::-1].copy()
bg=np.load(W+'bg.npy').astype(np.uint8)
S=7; X0,Y0=56,105; GW,GH=240,292
K=36
# shadow mask (source res)
med=cv2.medianBlur(src,5).astype(np.int16)
R,G,B=med[...,0],med[...,1],med[...,2]
sh=((B-R)>14)&(G>=R-2)&(R<70)&(B<95)
sh[:1860]=False
sh[1850:1897,630:765]=False   # left trouser cuff has the same navy as the ground shadow
sh=sh&(bg==0)
sh=cv2.morphologyEx(sh.astype(np.uint8),cv2.MORPH_OPEN,np.ones((5,5),np.uint8))
fg=(bg==0).astype(np.uint8)
obj=fg&(1-sh)
# fringe = object pixels within 2px of non-object
er=cv2.erode(obj,np.ones((5,5),np.uint8))
den=cv2.bilateralFilter(src,7,30,7)
crop=lambda a: a[Y0:Y0+GH*S, X0:X0+GW*S]
c_den,c_obj,c_er,c_sh=crop(den),crop(obj),crop(er),crop(sh)
lab=cv2.cvtColor(c_den,cv2.COLOR_RGB2LAB).reshape(-1,3).astype(np.float32)
idx=np.where(c_er.reshape(-1)>0)[0]
rng=np.random.default_rng(0)
km=MiniBatchKMeans(K,random_state=0,n_init=3,batch_size=4096).fit(lab[rng.choice(idx,250000,replace=False)])
cent=km.cluster_centers_
lbl=km.predict(lab).reshape(c_den.shape[:2])
pal=cv2.cvtColor(cent.reshape(1,-1,3).astype(np.uint8),cv2.COLOR_LAB2RGB).reshape(-1,3)
L=cent[:,0]*100/255
wgt=np.where(L<22,1.6,1.0)
def blocks(a): return a.reshape(GH,S,GW,S).transpose(0,2,1,3).reshape(GH,GW,S*S)
lb,ob,eb,sb=blocks(lbl),blocks(c_obj),blocks(c_er),blocks(c_sh)
idxmap=np.full((GH,GW),-1,np.int16)   # -1 transparent, -2 shadow
for y in range(GH):
    for x in range(GW):
        o=ob[y,x].astype(bool)
        if o.sum()>=S*S*0.5:
            e=eb[y,x].astype(bool)
            use=e if e.sum()>=6 else o
            c=np.bincount(lb[y,x][use],minlength=K)*wgt
            idxmap[y,x]=c.argmax()
        elif (sb[y,x].sum()+o.sum())>=S*S*0.5 and sb[y,x].sum()>0:
            idxmap[y,x]=-2
np.save(W+'idxmap.npy',idxmap); np.save(W+'pal.npy',pal)
print('done',(idxmap>=0).sum(),(idxmap==-2).sum())
