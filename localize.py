# coding: utf-8
import os
import sys
import shutil
import pickle
import numpy as np
from glob import glob


# stores = os.listdir('Traderjoe')
stores = [ 'StPaul', 'Shoreview', 'Minnetonka', 'StLouis', 'Edina' ]
lims = []

test_store_idx = stores.index(sys.argv[1])
test_store = stores.pop(test_store_idx)
train_stores = stores

train_data = [pickle.load(open('Traderjoe/{}/features.pkl'.format(store), 'rb')) for store in train_stores]
import ipdb; ipdb.set_trace()
# train_img_map = np.concatenate([data['img_map'] for data in train_data])
train_img_map = np.concatenate([np.arange(len(data))+1 for data in train_data])
store_map = np.concatenate([ np.tile(i, len(data)) for i, data in enumerate(train_data) ])
train_ftrs = np.concatenate([data for data in train_data])
# import ipdb; ipdb.set_trace()

test_data = pickle.load(open('Traderjoe/{}/features.pkl'.format(test_store), 'rb'))
test_img_map = np.arange(len(test_data))+1
test_ftrs = test_data


test_ftr = test_ftrs[np.where(test_img_map == int(sys.argv[2]))][0]
# test_ftr = test_ftrs[int(sys.argv[2]),:]
residues = np.sum((train_ftrs - test_ftr) ** 2, axis=1)
res = list(np.argsort(residues)[:10])

res_dir = 'results'
idx = max([int(ex_dir.strip().split('_')[-1]) for ex_dir in glob('results/*')]) + 1
res_dir = '{}/example_{}'.format(res_dir, idx)
os.makedirs(res_dir)
# shutil.copy('Traderjoe/{}/rectification/cylindrical/image{:07d}.jpg'.format(test_store, int(sys.argv[2])), '{}/0_test_img_{}.jpg'.format(res_dir, test_store))
shutil.copy('Traderjoe/{}/image/image{:07d}.jpg'.format(test_store, int(sys.argv[2])), '{}/0_test_img_{}.jpg'.format(res_dir, test_store))
for i, r in enumerate(res):
    store = train_stores[store_map[r]]
    img_num = train_img_map[r]
    print('{} : {}'.format(store, img_num))
    shutil.copy('Traderjoe/{}/image/image{:07d}.jpg'.format(store, img_num), '{}/{}_{}.jpg'.format(res_dir, i+1, store))

os.system('vimiv {} &'.format(res_dir))
