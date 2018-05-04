import numpy as np
import random
import sys
from scipy.io import savemat
from glob import glob

# RANSAC params
t = .25
d = 20
k = 2000


dirs = glob('reconstruction*')

for dir_ in dirs:
    # ver = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    with open('{}/camera.txt'.format(dir_)) as f:
        cams = np.stack([ list(map(float, line.strip().split())) for i,line in enumerate(f.readlines()) if (i+1) % 5 == 0 ])
    num_cams = cams.shape[0]


    best_p, best_n, best_err = None, None, float('inf')
    for _ in range(k):
        p1,p2,p3 = cams[random.sample(range(num_cams), 3), :]
        n = np.cross(p2-p1,p3-p1)
        n = n / np.linalg.norm(n)
        dists = np.abs((cams-p1) @ n)   # np.array(list(map(lambda p: np.abs(np.dot(n,p-p1)), cams)))
        good_idx = dists <= t
        if sum(good_idx) > d:
            # LS fit to 'good' points
            pts = cams[good_idx,:]
            centroid = cams.mean(axis=0)
            pts -= centroid
            xs = pts[:,0]
            ys = pts[:,1]
            zs = pts[:,2]
            X = np.array((
                ( (xs ** 2).sum(axis=0), (xs * zs).sum(axis=0) ),
                ( (xs * zs).sum(axis=0), (zs ** 2).sum(axis=0) )
                ))
            y = -np.array(( (xs*ys).sum(axis=0), (zs*ys).sum(axis=0) ))
            a, c = tuple(np.linalg.inv(X) @ y)
            # b = 1, d = 0
            b = 1
            n = np.array((a,b,c))   # downward facing gravity vector
            n /= np.linalg.norm(n)
            err = np.abs((cams - centroid) @ n).mean()
            if err < best_err:
                best_p, best_n, best_err = centroid, n, err

    print(best_err)
    print(best_n)
    savemat('{}/gravity.mat'.format(dir_), { 'gravity': best_n })
