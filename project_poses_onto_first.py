import numpy as np
from collections import defaultdict
import scipy.io


K = np.array(((562.89536, 1.03815, 630.7712), (0, 557.29656, 363.16152), (0, 0, 1)))
K = np.matmul(K, np.eye(3,4))
projections = defaultdict(list)


def extract_poses(lines):
    poses = [None] * (len(lines) // 5)
    i = 3
    while i < len(lines):
        frame = int(lines[i].strip().split()[1])
        C = np.zeros((4,4));   C[0:3,3] = np.array(list(map(float, lines[i+1].strip().split())))
        R = np.eye(4,4);   R[:3,:3] = np.array(list(map(lambda s: list(map(float, s.strip().split())), lines[i+2:i+
    5])))
        poses[frame] = (R, C)
        i += 5
    return poses


def project_onto_frame(i, poses, f_i):
    R_i, C_i = poses[i]
    prjctn_matrix = np.matmul(K, np.matmul(R_i, np.eye(4,4) - C_i))
    if i==0:
        print(prjctn_matrix)

    initial_skip = 10
    num_pred = 60
    j = i + initial_skip + 1
    while j < i + num_pred + 1 and j < len(poses):
        pose = poses[j]
        pos = pose[1][:,3]
        pos[3] = 1
        prjctn = np.matmul(prjctn_matrix, pos)
        prjctn /= prjctn[2]
        projections[f_i + i].append(prjctn[:2])
        j += 1


for f_i in range(200, 201, 200):
    f_name = 'reconstruction00{0:05d}/camera.txt'.format(f_i)
    try:
        with open(f_name) as f:
            lines = f.readlines()
        poses = extract_poses(lines)
        i = 0
        while i < 200 and i < len(poses):
            project_onto_frame(i, poses, f_i)
            i += 1
    except:
        print('{} doesn\'t exist.'.format(f_name))


scipy.io.savemat('projections.mat', mdict={'projections': projections})
