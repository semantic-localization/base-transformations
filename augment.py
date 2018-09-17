import os
import numpy as np
import imageio
import imgaug as ia
from imgaug import augmenters as iaa
import random


counts = {
  'none': 2090,
  'entrance': 1346,
  'beverages': 161,
  'pasta': 421,
  'counter': 1259,
  'cereal': 930,
  'oils': 3048,
  'frozenfood': 4190,
  'health': 311,
  'flowers': 1659,
  'water': 102,
  'dairy': 3756,
  'cheese': 2516,
  'snacks': 6537,
  'vegetables': 5764,
  'bread': 552,
  'meat': 1791
}

seq = iaa.Sequential([
    iaa.Fliplr(0.5), # horizontal flips
    # Small gaussian blur with random sigma between 0 and 0.5.
    # But we only blur about 50% of all images.
    iaa.Sometimes(0.5,
        iaa.GaussianBlur(sigma=(0, 0.5))
    ),
    # Strengthen or weaken the contrast in each image.
    iaa.ContrastNormalization((0.75, 1.5)),
    # Make some images brighter and some darker.
    # In 20% of all cases, we sample the multiplier once per channel,
    # which can end up changing the color of the images.
    iaa.Multiply((0.8, 1.2), per_channel=0.2),
    # Apply affine transformations to each image.
    # Scale/zoom them, translate/move them, rotate them and shear them.
    iaa.Affine(
        scale={"x": (1.0, 1.2), "y": (1.0, 1.2)},
        translate_percent={"x": (-0.2, 0.2), "y": (-0.2, 0.2)},
        rotate=(-25, 25),
        mode=['edge','symmetric','reflect']
    )
], random_order=True) # apply augmenters in random order

target_cnt = 3000
# for class_dir in os.listdir('features'):
for class_dir in ['beverages','health','water']:
    print(class_dir)
    imgs = [ np.asarray(imageio.imread('features_bak/{}/{}'.format(class_dir, imgfile))) for imgfile in os.listdir('features_bak/{}'.format(class_dir)) ]
    cnt = counts[class_dir]
    if cnt >= target_cnt:
        imgs_aug = imgs
    else:
        imgs_aug = []
        for i in range((target_cnt // cnt) + 1):
            imgs_aug += seq.augment_images(imgs)
            if (i+1)%2 == 0:
                print '  Aug in progress: {}'.format(len(imgs_aug))
    print '  Aug done: {} samples'.format(len(imgs_aug))
    imgs_aug = random.sample(imgs_aug, target_cnt)

    for i,img in enumerate(imgs_aug):
        imageio.imwrite('features_augmented/{}/image_{}.jpg'.format(class_dir, i), img)
