import numpy as np
import cv2
from imageio import imread, imwrite


# params for ShiTomasi corner detection
FEATURE_PARAMS = dict( maxCorners = 100,
                       qualityLevel = 0.3,
                       minDistance = 7,
                       blockSize = 7 )
# Parameters for lucas kanade optical flow
LK_PARAMS = dict( winSize  = (15,15),
                  maxLevel = 2,
                  criteria = (cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 10, 0.03))

# Goodness param
THRESHOLD_VOTES = 6


def track_patch(image_num, image, sh, sw, old_gray=None, p0=None):
    eh = sh+100
    ew = min(sw+100,1280)
    # Take first frame and find corners in it
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
    track_interval = 5
    for img_num in range(image_num-track_interval, image_num+track_interval+1):
        if img_num == image_num or img_num < 1:
            continue
        frame = imread('TraderJoe/image/image{:07d}.jpg'.format(img_num))
        frame_gray = cv2.cvtColor(frame, cv2.COLOR_RGB2GRAY)
        # calculate optical flow
        p1, st, err = cv2.calcOpticalFlowPyrLK(old_gray, frame_gray, p0, None, **LK_PARAMS)
        p0r, _st, _err = cv2.calcOpticalFlowPyrLK(frame_gray, old_gray, p1, None, **LK_PARAMS)
        d = abs(p0-p0r).reshape(-1, 2).max(-1)
        good = d < 1
        if sum(in_patch & good) > 0:
            px, py = map(int, tuple(np.squeeze(p1)[in_patch & good].mean(axis=0)))
            tp = image[max(0,py-50):min(720,py+50),max(0,px-50):min(1280,px+50),:]
            imwrite('tracked_{}_{}_{}_{}.jpg'.format(image_num, image_num-img_num, sw, sh), tp)


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
    conf_labels = np.zeros(15)
    votes = []
    for image_num in range(500,1500):
        image = imread('TraderJoe/image/image{:07d}.jpg'.format(image_num))
        old_gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
        p0 = cv2.goodFeaturesToTrack(old_gray, mask = None, **FEATURE_PARAMS)
        probs, labels = pickle.load(open('TraderJoe/image/labels_{:07d}.pkl'.format(image_num)))
        for sh in range(0,601,100):
            for sw in range(0, 1201, 100):
                ans = confident_enough(sh, sw, labels):
                if ans:
                    label, max_votes = ans
                    conf_labels[label] += 1
                    votes.append(max_votes)
                    # track_patch(image_num, image, sh, sw, old_gray, p0)
    # track_patch(862, imread('TraderJoe/image/image{:07d}.jpg'.format(862)), 500, 300)
    print('---STATS----')
    import ipdb; ipdb.set_trace()
