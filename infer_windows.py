import imageio
from label_image import infer
import argparse
import scipy.io as sio


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-i', '--image_file',
        type=str,
        default='TraderJoe/image/image0000001.jpg',
        help='Image to window and classify'
    )
    FLAGS, unparsed = parser.parse_known_args()
    print(FLAGS)

    img = imageio.imread(FLAGS.image_file)
    height, width, _ = img.shape
    window_labels = []

    for i in range(0,height,100):
        for j in range(0,width,100):
            hend = min(i+100,height)
            wend = min(j+100,width)
            sample = img[i:hend,j:wend,:]
            sinfo = '{}+{}+{}x{}'.format(i, j, hend-i, wend-j)
            fname = 'windows/image_{}.jpg'.format(sinfo)
            imageio.imwrite(fname, sample)
            window_label = infer(fname)
            window_labels.append(window_label)
            print('{}: {}'.format(sinfo, window_label), flush=True)
    
    sio.savemat('window_labels_{}.mat'.format(FLAGS.image_file.split('.')[0][-12:]), { 'window_labels': window_labels })
