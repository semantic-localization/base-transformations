import numpy as np
import cv2
from imageio import imread, imwrite


def track_patch(image_num, image, sh, sw, p0=None):
    eh = sh+100
    ew = min(sw+100,1280)
    # params for ShiTomasi corner detection
    feature_params = dict( maxCorners = 100,
                           qualityLevel = 0.3,
                           minDistance = 7,
                           blockSize = 7 )
    # Parameters for lucas kanade optical flow
    lk_params = dict( winSize  = (15,15),
                      maxLevel = 2,
                      criteria = (cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 10, 0.03))
    # Take first frame and find corners in it
    old_gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
    if not p0:
        p0 = cv2.goodFeaturesToTrack(old_gray, mask = None, **feature_params)
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
        p1, st, err = cv2.calcOpticalFlowPyrLK(old_gray, frame_gray, p0, None, **lk_params)
        p0r, _st, _err = cv2.calcOpticalFlowPyrLK(frame_gray, old_gray, p1, None, **lk_params)
        d = abs(p0-p0r).reshape(-1, 2).max(-1)
        good = d < 1
        if sum(in_patch & good) > 0:
            px, py = map(int, tuple(np.squeeze(p1)[in_patch & good].mean(axis=0)))
            tp = image[max(0,py-50):min(720,py+50),max(0,px-50):min(1280,px+50),:]
            imwrite('tracked_{}_{}_{}_{}.jpg'.format(image_num, image_num-img_num, sw, sh), tp)


if __name__ == '__main__':
    track_patch(862, imread('TraderJoe/image/image{:07d}.jpg'.format(862)), 500, 300)
