# coding: utf-8
import sys
import pickle
import numpy as np

data = pickle.load(open('features_places.pkl', 'rb'))
img_map = data['img_map']
features = data['features']

lim = np.where(img_map == 12000)[0][0]
train_ftrs = features[:lim+1]
test_ftr = features[np.where(img_map == int(sys.argv[1]))][0]

residues = np.sum((train_ftrs - test_ftr) ** 2, axis=1)
res = img_map[list(np.argsort(residues)[:10])]
print(res)
