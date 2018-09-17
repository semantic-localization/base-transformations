import os
import imageio
import numpy as np
import ipdb


def prepare_data():
    dir_ = 'features'
    classes = os.listdir(dir_)
    X = []
    y = []
    for i, class_dir in enumerate(classes):
        for img_file in os.listdir('{}/{}'.format(dir_, class_dir)):
            img = np.asarray(imageio.imread('{}/{}/{}'.format(dir_, class_dir, img_file)))
            if img.shape == (100,100,3):
                # ipdb.set_trace()
                img = np.reshape(img, (-1))
                X.append(img)
                y.append(i)
    # ipdb.set_trace()
    X, y = np.asarray(X), np.asarray(y)
    return classes, X, y


if __name__ == '__main__':
    classes, X, y = prepare_data()
    ipdb.set_trace()
