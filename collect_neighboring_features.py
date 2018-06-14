# coding: utf-8
from imageio import imread, imwrite
import numpy as np
from glob import glob
import os
from scipy.io import loadmat

classes = os.listdir('features_filtered/original')
index_map = loadmat('indexesToFrames.mat')['index_map']

for cls in classes:
    imgpaths = glob('features_filtered/original/{}/*.jpg'.format(cls))
    save_dir = 'features_filtered/neighboring/{}'.format(cls)
    try:
        os.listdir(save_dir)
    except:
        os.makedirs(save_dir)
    for imgpath in imgpaths:
        img = imread(imgpath)
        img_num, sw, sh = map(lambda s: int(s), imgpath.split('/')[-1].split('.')[0].split('_')[1:])
        sw -= 1
        sh -= 1

        image = imread('TraderJoe/image/image{:07d}.jpg'.format(index_map[img_num-1][0]))

        if sw > 0:
            imwrite('{}/{}_left_{}_{}.jpg'.format(save_dir, img_num, sw-50, sh), image[sh:sh+100, sw-50:sw+50, :])
        if sw < 1200:
            imwrite('{}/{}_right_{}_{}.jpg'.format(save_dir, img_num, sw+50, sh), image[sh:sh+100, sw+50:sw+150, :])
        if sh > 0:
            imwrite('{}/{}_top_{}_{}.jpg'.format(save_dir, img_num, sw, sh-50), image[sh-50:sh+50, sw:sw+100, :])
        if sh < 700:
            imwrite('{}/{}_bottom_{}_{}.jpg'.format(save_dir, img_num, sw, sh+50), image[sh+50:sh+150, sw:sw+100, :])
