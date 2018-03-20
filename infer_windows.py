import imageio
from label_image import load_graph, load_labels
import argparse
import scipy.io as sio
import pickle
import os
import numpy as np
import time
import glob
from scipy.misc import imresize
import tensorflow as tf


def softmax_layer(patch):
    with tf.Session(graph=graph) as sess:
        results = sess.run(output_operation.outputs[0],
                  {input_operation.outputs[0]: patch})
    results = np.squeeze(results)
    return results


def prepare(img):
    float_caster = tf.cast(img, tf.float32)
    dims_expander = tf.expand_dims(float_caster, 0)
    resized = tf.image.resize_bilinear(dims_expander, [input_height, input_width])
    normalized = tf.divide(tf.subtract(resized, [input_mean]), [input_std])
    return normalized


if __name__ == '__main__':
    # init computational graph
    model_file = '{}/classifier/output_graph.pb'.format(os.environ['HOME'])
    graph = load_graph(model_file)
    input_name = "import/Mul"
    output_name = "import/final_result"
    input_operation = graph.get_operation_by_name(input_name)
    output_operation = graph.get_operation_by_name(output_name)
    labels = load_labels('{}/classifier/output_labels.txt'.format(os.environ['HOME']))

    # to resize and normalize
    height = 720
    width = 1280
    input_height = 299
    input_width = 299
    input_mean = 128
    input_std = 128

    imgfiles = sorted(glob.glob('image/*.jpg'))
    st = time.time()
    n = len(imgfiles)

    for k, imgfile in enumerate(imgfiles):
        file_reader = tf.read_file(imgfile, 'file_reader')
        img = tf.image.decode_jpeg(file_reader, channels = 3, name='jpeg_reader')

        # img = imageio.imread(imgfile)
        imgfile = imgfile.split('/')[-1].split('.')[0][5:]
        window_labels = []

        feature_vector = []
        step = 100
        patches = None
        for i in range(0,height,step):
            for j in range(0,width,step):
                hend = min(i+step,height)
                wend = min(j+step,width)
                patch = img[i:hend,j:wend,:]

                preprocessed = prepare(patch)
                with tf.Session() as sess:
                    t = sess.run(preprocessed)

                import ipdb; ipdb.set_trace()

                patch_vector = softmax_layer(t)
                feature_vector.append(patch_vector)

#                 if patches is None:
#                     patches = normalized
#                 else:
#                     patches = tf.concat((patches, normalized), 0)

#                 patch = imresize(patch, (input_height, input_width), interp='bilinear').astype(float)
#                 patch = (patch - input_mean)/input_std
#                 patches.append(patch)

#                 sinfo = '{}+{}+{}x{}'.format(i, j, hend-i, wend-j)
#                 fname = 'windows/image_{}.jpg'.format(sinfo)
#                 imageio.imwrite(fname, patch)
                # print('{}: {}'.format(sinfo, patch_vector), flush=True)

        feature_vector = np.concatenate(feature_vector, axis=0)
        fname = 'image/softmax_features_{}'.format(imgfile)
        sio.savemat('{}.mat'.format(fname), { 'feature_vector': feature_vector })
        with open('{}.pkl'.format(fname), 'wb') as f:
            pickle.dump(feature_vector, f)

        if (k+1) % 10 == 0:
          time_taken = time.time() - st
          avg_time_taken = time_taken / (k+1)
          time_remaining = (avg_time_taken * (n - k - 1)) / 60
          print('Step: {}, time/img: {} s, time remaining: {} m'.format(k+1, avg_time_taken, time_remaining), flush=True)
