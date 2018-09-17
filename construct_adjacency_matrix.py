"""
Construct adjacency matrix from video labeling to get a sense of adjacent sections. 

Observation: Store duration whenever label is none, so that it gives a sense of raw distance.
"""


import os
import sys
import shutil
import argparse
import numpy as np
import scipy.io
import heapq
from collections import defaultdict, Counter


def to_time(s):
    m, s = map(int, s.split(':'))
    return 60*m + s


def get_labels():
    return [
           'bars',
           'beverages',
           'bodycare',
           'bread',
           'cereal',
           'cheese',
           'counter',
           'dairy',
           'diapers',
           'dressing',
           'entrance',
           'flowers',
           'frozenfood',
           'health',
           'meat',
           'oils',
           'pasta',
           'pets',
           'seafood',
           'snacks',
           'vegetables',
           'water',
           # 'none'
           ]


def construct_adjacency_matrix(store, normalize=False):
    labels_file = 'labels_{}.txt'.format(store)
    decay = 0.1
    step_size = 5

    with open(labels_file) as f:
        frames = list(f)

        labels = set()
        for frame in frames:
            ls = frame.strip().split()[1].split(':')
            for l in ls:
                labels.add(l)
        labels = sorted(list(labels))
        del(labels[labels.index('none')])
        adjacency_matrix = np.zeros((len(labels),len(labels)))

        n = len(frames)
        for i in range(n):
            frame = frames[i]
            ll, rl = frame.strip().split()[1].split(':')
            lli, rli = None, None
            if ll != 'none':
                lli = labels.index(ll)
            if rl != 'none':
                rli = labels.index(rl)
            # Mutually related
            if lli and rli:
                adjacency_matrix[lli][rli] += 1
                adjacency_matrix[rli][lli] += 1

            for j in range(i+1, n):
                next_frame = frames[j]
                nll, nrl = next_frame.strip().split()[1].split(':')
                steps = (j-i)//step_size
                weight = decay ** steps
                if nll != 'none':
                    nlli = labels.index(nll)
                    if lli:
                        adjacency_matrix[lli][nlli] += weight
                        adjacency_matrix[nlli][lli] += weight
                    if rli:
                        adjacency_matrix[rli][nlli] += weight
                        adjacency_matrix[nlli][rli] += weight
                if nrl != 'none':
                    nrli = labels.index(nrl)
                    if lli:
                        adjacency_matrix[lli][nrli] += weight
                        adjacency_matrix[nrli][lli] += weight
                    if rli:
                        adjacency_matrix[rli][nrli] += weight
                        adjacency_matrix[nrli][rli] += weight


    # L1 normalize
    if normalize:
        sum_ = adjacency_matrix.sum(axis=1)
        sum_[sum_ == 0] = 1
        sum_ = np.reshape(sum_, (-1,1))
        adjacency_matrix = adjacency_matrix / sum_

    # import ipdb; ipdb.set_trace()
    # print(adjacency_matrix)
    scipy.io.savemat('visualization/adjacency_matrices/{}_adjacency.mat'.format(store), mdict={'labels': np.array(labels), 'adjacency_matrix': adjacency_matrix})
    return


def shortest_path(store, source, target):
    labels = get_labels()
    try:
        source, target = labels.index(source), labels.index(target)
    except:
        print('Unknown source/target')
        return

    mat_dict = scipy.io.loadmat('visualization/adjacency_matrices/{}_adjacency.mat'.format(store))
    adjacency_matrix = mat_dict['adjacency_matrix']

    dist = { v: float('inf') for v in range(len(labels)) }
    dist[source] = 0
    back = { v: None for v in range(len(labels)) }
    for _ in range(len(labels)):
        u, d_u = min(dist.items(), key=lambda tup: tup[1])
        del(dist[u])
        for v, u_v in enumerate(adjacency_matrix[u]):
            if v in dist and u_v != 0:
                d_v = d_u + 1/u_v     # Since adjacency values are indicative of proximity
                if d_v < dist[v]:
                    dist[v] = d_v
                    back[v] = u

    # import ipdb; ipdb.set_trace()
    u = target
    path = [labels[u]]
    while u and u != source:
        u = back[u]
        path.append(labels[u])
    path.reverse()
    return path


if __name__ == '__main__':
    construct_adjacency_matrix('wholefood', True)
    construct_adjacency_matrix('traderjoe', True)

#     from_ = sys.argv[1]
#     to_ = sys.argv[2]
#     path = shortest_path('traderjoe', from_, to_)
#     print(' -> '.join(path))
