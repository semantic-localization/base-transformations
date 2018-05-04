<<<<<<< Updated upstream
=======
import os, sys
>>>>>>> Stashed changes
import pickle
import numpy as np
import cv2
import ipdb
from imageio import imread, imwrite


# params for ShiTomasi corner detection
FEATURE_PARAMS = dict( maxCorners = 500,
                       qualityLevel = 0.3,
                       minDistance = 7,
                       blockSize = 7 )
# Parameters for lucas kanade optical flow
LK_PARAMS = dict( winSize  = (15,15),
                  maxLevel = 2,
                  criteria = (cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 10, 0.03))
IMAGE_DIR = '/home/jayant/TraderJoe/image'
DATASET_DIR = '/home/jayant/features_filtered/opt_flow'

LABEL_DIRS = { int(k): '{}/{}'.format(DATASET_DIR, v.strip()) for line in open('{}/augmented/labels.txt'.format('/'.join(DATASET_DIR.split('/')[:-1]))).readlines() for k,v in [tuple(line.split(':'))] }
for label_dir in LABEL_DIRS.values():
    try:
        os.listdir(label_dir)
    except:
        os.makedirs(label_dir)

#######################################################
# Goodness Param : For deciding which patches to track
#   - patches w more votes from neighbors than this
#     value will be tracked
#     so at least 6/8 votes will be required
#######################################################
THRESHOLD_VOTES = 5

# 5 frames before and after image to be scanned
track_interval = 5


def track_patch(label, image_num, images, sh, sw, old_gray, p0):
    eh = sh+100
    ew = min(sw+100,1280)
    # # Take first frame and find corners in it
    # if not old_gray:
    #     old_gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
    # if not p0:
    #     p0 = cv2.goodFeaturesToTrack(old_gray, mask = None, **FEATURE_PARAMS)
    xs = np.reshape(p0, (-1,2))[:,0]
    ys = np.reshape(p0, (-1,2))[:,1]
    in_patch = (sh <= ys) & (ys < eh) & (sw <= xs) & (xs < ew)
    # Create a mask image for drawing purposes
    # mask = np.zeros_like(image)
    cnt = 0
    offset = track_interval
    for img_diff in range(-track_interval, track_interval+1):
        if img_diff == 0:
            continue
        # frame = imread('{}/image{:07d}.jpg'.format(IMAGE_DIR, img_num))
        frame = images[img_diff + track_interval]
        if frame is None:
            continue
        frame_gray = cv2.cvtColor(frame, cv2.COLOR_RGB2GRAY)

        # CALCULATE OPTICAL FLOW
        p1, st, err = cv2.calcOpticalFlowPyrLK(old_gray, frame_gray, p0, None, **LK_PARAMS)

        # CHECK FOR GOODNESS OF FEATURES - skipping this to see if I can get some more features
        # p0r, _st, _err = cv2.calcOpticalFlowPyrLK(frame_gray, old_gray, p1, None, **LK_PARAMS)
        # d = abs(p0-p0r).reshape(-1, 2).max(-1)
        # good = d < 1
        # if sum(in_patch & good) > 0:

        if sum(in_patch) > 0:
            px, py = map(int, tuple(np.squeeze(p1)[in_patch].mean(axis=0)))
            tp = frame[max(0,py-50):min(720,py+50),max(0,px-50):min(1280,px+50),:]
            imwrite('{}/tracked_{}_{}_{}_{}.jpg'.format(LABEL_DIRS[label], image_num, img_diff, sw, sh), tp)


def get_label(labels, sh_sw):
    sh, sw = sh_sw
    if 300 <= sh <= 600 and 0 <= sw <= 1200:
        return labels[13*sh//100 + sw//100]


def confident_enough(sh, sw, labels):
    label = get_label(labels, (sh, sw))
    votes = np.zeros(15)
    for nbr in [ (sh-100, sw-100), (sh-100, sw), (sh-100, sw+100), (sh, sw+100), (sh+100, sw+100), (sh+100, sw), (sh+100, sw-100), (sh, sw-100) ]:
    # for nbr in [ (sh-100, sw), (sh, sw+100), (sh+100, sw), (sh, sw-100) ]:
        lbl = get_label(labels, nbr)
        if lbl is not None:
            votes[lbl] += 1
    total_votes = np.sum(votes)
    max_votes = np.max(votes)
    alt_label = np.argmax(votes)
    if total_votes == 8 and max_votes > THRESHOLD_VOTES and alt_label == label: # and alt_label != 10:
        return label, max_votes



if __name__ == '__main__':
    START_NUM = int(sys.argv[1])
    END_NUM = int(sys.argv[2])
    conf_labels = np.zeros(15)
    votes = []
    frames = [ None ] * 5 + [ imread('{}/image{:07d}.jpg'.format(IMAGE_DIR, START_NUM + i)) for i in range(track_interval+1) ]
    for image_num in range(START_NUM,END_NUM):
        if image_num % 50 == 0:    print('--------- IMAGE {} -----------'.format(image_num))
        # image = imread('{}/image{:07d}.jpg'.format(IMAGE_DIR, image_num))
        image = frames[track_interval]
        old_gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
        p0 = cv2.goodFeaturesToTrack(old_gray, mask = None, **FEATURE_PARAMS)
        data = pickle.load(open('{}/labels_{:07d}.pkl'.format(IMAGE_DIR, image_num), 'rb'))
        labels = data[1]
        for sh in range(0,601,100):
            for sw in range(0, 1201, 100):
                ans = confident_enough(sh, sw, labels)
                if ans:
                    label, max_votes = ans
                    conf_labels[label] += 1
                    votes.append(max_votes)
                    # Will see None later
                    if label != 10:
                        track_patch(label, image_num, frames, sh, sw, old_gray, p0)

        # Roll over frames
        del(frames[0])
        next_edge = image_num + track_interval + 1
        frames.append(imread('{}/image{:07d}.jpg'.format(IMAGE_DIR, next_edge)) if next_edge < END_NUM else None)

    ## EXP
    # track_patch(862, imread('TraderJoe/image/image{:07d}.jpg'.format(862)), 500, 300)

    print('---STATS----')
    print('Avg vote: {}'.format(np.array(votes).mean()))
    for i in range(15):
        print('{} :: {}'.format(LABEL_DIRS[i].split('/')[-1], conf_labels[i]))
    import ipdb; ipdb.set_trace()
