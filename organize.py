import os
import shutil
import numpy as np
import glob
import random
from imageio import imread, imwrite
from scipy.misc import imresize
from collections import defaultdict


THRESHOLD = 120
HEIGHT = 100
WIDTH = 100
TRAIN_TEST_SPLIT = .9


def ensure_dir(dir_name):
    try:
        os.listdir(dir_name)
    except:
        os.makedirs(dir_name)


def trim():
    classes = os.listdir('original')
    shapes = defaultdict(lambda: 0)
    for class_ in classes:
        dest = 'trimmed/complete/{}'.format(class_)
        ensure_dir(dest)
        imgfiles = glob.glob('original/{}/*'.format(class_))
        n_imgs = len(imgfiles)
        if n_imgs > THRESHOLD:
            imgfiles = random.sample(imgfiles, THRESHOLD)
        for imgfile in imgfiles:
            # if shape not 100x100, then reshape
            try:
                img = imread(imgfile)
            except:
                import ipdb; ipdb.set_trace()
            shapes[img.shape] += 1
            if img.shape == (HEIGHT,WIDTH,3):
                shutil.copy(imgfile, dest)
            else:
                img = imresize(img, (HEIGHT, WIDTH), interp='bilinear')
                imwrite('{}/{}'.format(dest, imgfile.split('/')[-1]), img)
    print('STATS')
    for shape, count in shape.items():
        print('{}: {}'.format(shape, count))


def split_dataset():
    classes = os.listdir('complete')
    for class_ in classes:
        imgfiles = glob.glob('complete/{}/*'.format(class_))
        random.shuffle(imgfiles)
        size = len(imgfiles)

        train_size = int(TRAIN_TEST_SPLIT * size)
        train_files = imgfiles[:train_size]
        train_dir = 'train/{}'.format(class_)
        ensure_dir(train_dir)
        for f in train_files:
            shutil.copy(f, train_dir)

        test_files = imgfiles[train_size:]
        test_dir = 'test/{}'.format(class_)
        ensure_dir(test_dir)
        for f in test_files:
            shutil.copy(f, test_dir)


if __name__ == '__main__':
    split_dataset()
