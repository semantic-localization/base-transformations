import imageio
from label_image import softmax_layer
import argparse
import scipy.io as sio
import pickle
import os
import numpy as np
import time


if __name__ == '__main__':
    imgfiles = sorted(os.listdir('image'))
    st = time.time()
    n = len(imgfiles)
    for k, imgfile in enumerate(imgfiles):
        img = imageio.imread('image/{}'.format(imgfile))
        imgfile = imgfile.split('.')[0][5:]
        height, width, _ = img.shape
        window_labels = []

        feature_vector = []
        step = 100
        for i in range(0,height,step):
            for j in range(0,width,step):
                hend = min(i+step,height)
                wend = min(j+step,width)
                sample = img[i:hend,j:wend,:]
                sinfo = '{}+{}+{}x{}'.format(i, j, hend-i, wend-j)
                fname = 'windows/image_{}.jpg'.format(sinfo)
                imageio.imwrite(fname, sample)
                patch_vector = softmax_layer(fname)
                feature_vector.append(patch_vector)
                # print('{}: {}'.format(sinfo, patch_vector), flush=True)

        feature_vector = np.concatenate(feature_vector, axis=0)
        fname = 'image/softmax_features_{}'.format(imgfile)
        sio.savemat('{}.mat'.format(fname), { 'feature_vector': feature_vector })
        with open('{}.pkl'.format(fname), 'wb') as f:
            pickle.dump(feature_vector, f)

        if (i+1) % 50 == 0:
            time_taken = time.time() - st
            avg_time_taken = time_taken / (k+1)
            time_remaining = (avg_time_taken * (n - k - 1)) % 60
            print('Step: {}, time/img: {} s, time remaining: {} m'.format(k+1, avg_time_taken, time_remaining), flush=True)
